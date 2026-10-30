import 'package:flutter/foundation.dart';
import '../models/student_profile.dart';
import '../services/supabase_service.dart';

class ProfileProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  StudentProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  StudentProfile? get profile => _profile;
  bool get hasProfile => _profile != null && _profile!.name.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _supabase.loadProfile(userId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error in fetchProfile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(StudentProfile newProfile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.saveProfile(newProfile);
      _profile = newProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
