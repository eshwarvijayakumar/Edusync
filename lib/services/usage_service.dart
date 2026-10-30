import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

class UsageService {
  static final UsageService _instance = UsageService._internal();
  factory UsageService() => _instance;
  UsageService._internal();

  static const String _usageCountKey = 'edusync_daily_questions_count';
  static const String _usageDateKey = 'edusync_daily_questions_date';

  String _getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Returns remaining questions for today (out of 10)
  Future<int> getRemainingQuestions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final storedDate = prefs.getString('${_usageDateKey}_$userId');

    if (storedDate != today) {
      // New day: Reset to 0 questions used
      await prefs.setString('${_usageDateKey}_$userId', today);
      await prefs.setInt('${_usageCountKey}_$userId', 0);
      return AppConstants.dailyFreeQuestionLimit;
    }

    final used = prefs.getInt('${_usageCountKey}_$userId') ?? 0;
    final remaining = AppConstants.dailyFreeQuestionLimit - used;
    return remaining > 0 ? remaining : 0;
  }

  /// Increments questions used today by 1. Returns true if allowed, false if limit reached.
  Future<bool> consumeQuestion(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final storedDate = prefs.getString('${_usageDateKey}_$userId');

    int used = 0;
    if (storedDate == today) {
      used = prefs.getInt('${_usageCountKey}_$userId') ?? 0;
    } else {
      await prefs.setString('${_usageDateKey}_$userId', today);
    }

    if (used >= AppConstants.dailyFreeQuestionLimit) {
      return false; // Limit reached
    }

    used++;
    await prefs.setInt('${_usageCountKey}_$userId', used);

    // Sync with Supabase usage_limits table if online
    if (SupabaseService().isConfigured && userId.isNotEmpty) {
      try {
        await SupabaseService().client.from('usage_limits').upsert({
          'user_id': userId,
          'date': today,
          'questions_used': used,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Usage limit remote sync note: $e');
      }
    }

    return true;
  }
}
