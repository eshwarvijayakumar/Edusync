import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  bool _isLoading = true;
  String? _userId;
  String? _userEmail;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userId != null && _userId!.isNotEmpty;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    initAuth();
  }

  /// Automatically restores the logged in session on app open / reload
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_supabase.isConfigured) {
        final session = _supabase.client.auth.currentSession;
        if (session != null && session.user.id.isNotEmpty) {
          _userId = session.user.id;
          _userEmail = session.user.email;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Check persistent local session
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('local_auth_current_user_id');
      final savedEmail = prefs.getString('local_auth_current_email');

      if (savedId != null && savedId.isNotEmpty) {
        _userId = savedId;
        _userEmail = savedEmail;
      } else {
        _userId = null;
        _userEmail = null;
      }
    } catch (e) {
      debugPrint('Auth initialization note: $e');
      _userId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _supabase.signIn(email: email, password: password);
      if (res?.user != null) {
        _userId = res!.user!.id;
        _userEmail = res.user!.email;
      } else {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('local_auth_current_user_id');
        _userEmail = prefs.getString('local_auth_current_email') ?? email;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _supabase.signUp(
        email: email,
        password: password,
        name: name,
        mobile: mobile,
      );
      if (res?.user != null) {
        _userId = res!.user!.id;
        _userEmail = res.user!.email;
      } else {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('local_auth_current_user_id');
        _userEmail = prefs.getString('local_auth_current_email') ?? email;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.signInWithGoogle();
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('local_auth_current_user_id') ?? 'google_user_default';
      _userEmail = prefs.getString('local_auth_current_email') ?? 'student@gmail.com';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.signOut();
    _userId = null;
    _userEmail = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_userId != null) {
      await _supabase.deleteAccount(_userId!);
      _userId = null;
      _userEmail = null;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
