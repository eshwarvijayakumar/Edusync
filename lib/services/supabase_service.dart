import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_profile.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isConfigured = false;
  static const String _profileCacheKey = 'cached_student_profile_v1';
  static const String _usersRegistryKey = 'registered_accounts_registry_v1';

  bool get isConfigured => _isConfigured;
  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<void> initialize({String? supabaseUrl, String? supabaseAnonKey}) async {
    final url = supabaseUrl ?? AppConstants.defaultSupabaseUrl;
    final key = supabaseAnonKey ?? AppConstants.defaultSupabaseAnonKey;

    if (url.contains('YOUR_SUPABASE') || key.contains('YOUR_SUPABASE')) {
      debugPrint('EduSync: Supabase using self-contained local resilient mode.');
      _isConfigured = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: key,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = Supabase.instance.client;
      _isConfigured = true;
      debugPrint('EduSync: Supabase initialized successfully.');
    } catch (e) {
      debugPrint('EduSync: Supabase init error, running in resilient mode: $e');
      _isConfigured = false;
    }
  }

  // --- Duplicate Validation ---
  Future<bool> isEmailOrMobileRegistered(String email, String mobile) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanMobile = mobile.trim();

    // 1. Check local registry
    final prefs = await SharedPreferences.getInstance();
    final registryJson = prefs.getString(_usersRegistryKey);
    if (registryJson != null) {
      final List<dynamic> list = jsonDecode(registryJson);
      for (var u in list) {
        if (u['email'] == cleanEmail || (cleanMobile.isNotEmpty && u['mobile'] == cleanMobile)) {
          return true;
        }
      }
    }

    // 2. Check Supabase DB if connected
    if (_isConfigured && _client != null) {
      try {
        final res = await _client!
            .from('student_profiles')
            .select('email, mobile')
            .or('email.eq.$cleanEmail,mobile.eq.$cleanMobile')
            .limit(1);
        if (res.isNotEmpty) return true;
      } catch (e) {
        debugPrint('Supabase duplicate check query error: $e');
      }
    }
    return false;
  }

  Future<void> _recordRegisteredUser(String email, String mobile, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final registryJson = prefs.getString(_usersRegistryKey);
    List<dynamic> list = [];
    if (registryJson != null) {
      list = jsonDecode(registryJson);
    }
    list.add({
      'id': userId,
      'email': email.trim().toLowerCase(),
      'mobile': mobile.trim(),
      'registered_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_usersRegistryKey, jsonEncode(list));
  }

  // --- Authentication ---

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String name,
    required String mobile,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanMobile = mobile.trim();

    // Check duplicate
    final isDuplicate = await isEmailOrMobileRegistered(cleanEmail, cleanMobile);
    if (isDuplicate) {
      throw Exception('An account with this email address or mobile number already exists. Please sign in instead.');
    }

    if (_isConfigured && _client != null) {
      try {
        final response = await _client!.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {
            'name': name,
            'mobile': cleanMobile,
          },
        );
        if (response.user != null) {
          await _recordRegisteredUser(cleanEmail, cleanMobile, response.user!.id);
        }
        return response;
      } catch (e) {
        rethrow;
      }
    } else {
      // Offline / Local self-contained auth session
      final fakeId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await _recordRegisteredUser(cleanEmail, cleanMobile, fakeId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_auth_current_user_id', fakeId);
      await prefs.setString('local_auth_current_email', cleanEmail);
      await prefs.setString('local_auth_current_name', name);
      await prefs.setString('local_auth_current_mobile', cleanMobile);
      return null;
    }
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (_isConfigured && _client != null) {
      return await _client!.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
    } else {
      // Local authentication check
      final prefs = await SharedPreferences.getInstance();
      final registryJson = prefs.getString(_usersRegistryKey);
      if (registryJson != null) {
        final List<dynamic> list = jsonDecode(registryJson);
        final user = list.firstWhere(
          (u) => u['email'] == cleanEmail,
          orElse: () => null,
        );
        if (user != null) {
          await prefs.setString('local_auth_current_user_id', user['id']);
          await prefs.setString('local_auth_current_email', cleanEmail);
          return null;
        }
      }
      throw Exception('No account found for this email. Please check your credentials or register a new account.');
    }
  }

  Future<void> signInWithGoogle() async {
    if (_isConfigured && _client != null) {
      await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.edusync://login-callback',
      );
    } else {
      // Resilient sandbox google sign in
      final prefs = await SharedPreferences.getInstance();
      final fakeId = 'google_user_${DateTime.now().millisecondsSinceEpoch}';
      const fakeEmail = 'student@gmail.com';
      await _recordRegisteredUser(fakeEmail, '9876543210', fakeId);
      await prefs.setString('local_auth_current_user_id', fakeId);
      await prefs.setString('local_auth_current_email', fakeEmail);
    }
  }

  Future<void> resetPassword(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_isConfigured && _client != null) {
      await _client!.auth.resetPasswordForEmail(cleanEmail);
    }
  }

  Future<void> signOut() async {
    if (_isConfigured && _client != null) {
      await _client!.auth.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_auth_current_user_id');
    await prefs.remove('local_auth_current_email');
    await prefs.remove(_profileCacheKey);
  }

  Future<void> deleteAccount(String userId) async {
    if (_isConfigured && _client != null) {
      try {
        await _client!.from('student_profiles').delete().eq('id', userId);
        await _client!.auth.admin.deleteUser(userId);
      } catch (e) {
        debugPrint('Account delete server notice: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- Profile Storage & Sync ---

  Future<void> saveProfile(StudentProfile profile) async {
    // 1. Cache locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileCacheKey, jsonEncode(profile.toJson()));

    // 2. Persist to Supabase if connected
    if (_isConfigured && _client != null) {
      try {
        await _client!.from('student_profiles').upsert(profile.toJson());
      } catch (e) {
        debugPrint('Failed to sync profile to Supabase: $e');
      }
    }
  }

  Future<StudentProfile?> loadProfile(String userId) async {
    // 1. Check local cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_profileCacheKey);
    if (cached != null) {
      try {
        final profile = StudentProfile.fromJson(jsonDecode(cached));
        if (profile.id == userId || userId.isEmpty) {
          return profile;
        }
      } catch (e) {
        debugPrint('Error parsing cached profile: $e');
      }
    }

    // 2. Fetch from Supabase
    if (_isConfigured && _client != null && userId.isNotEmpty) {
      try {
        final res = await _client!
            .from('student_profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (res != null) {
          final profile = StudentProfile.fromJson(res);
          await prefs.setString(_profileCacheKey, jsonEncode(profile.toJson()));
          return profile;
        }
      } catch (e) {
        debugPrint('Error loading profile from Supabase: $e');
      }
    }
    return null;
  }

  String? getCurrentUserId() {
    if (_isConfigured && _client != null) {
      return _client!.auth.currentUser?.id;
    }
    return null;
  }

  String? getCurrentUserEmail() {
    if (_isConfigured && _client != null) {
      return _client!.auth.currentUser?.email;
    }
    return null;
  }
}
