import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de caché de trabajos con patrón Stale-While-Revalidate.
/// Igual que TikTok/Instagram: muestra datos locales inmediatamente,
/// refresca en background y actualiza la UI sin mostrar loaders.
class JobsCacheService {
  static const _kJobsKey       = 'cached_jobs_v2';
  static const _kTimestampKey  = 'cached_jobs_ts_v2';
  static const _kViewsPrefix   = 'job_views_';
  static const _ttlMinutes     = 15;

  static Future<void> saveJobs(List<Map<String, dynamic>> jobs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(jobs);
      await prefs.setString(_kJobsKey, jsonStr);
      await prefs.setInt(_kTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>?> loadJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kJobsKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_kTimestampKey);
      if (ts == null) return false;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      return age < (_ttlMinutes * 60 * 1000);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_kJobsKey);
      return val != null && val.isNotEmpty && val != '[]';
    } catch (_) {
      return false;
    }
  }

  static Future<int> cacheAgeMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_kTimestampKey);
      if (ts == null) return 9999;
      final ms = DateTime.now().millisecondsSinceEpoch - ts;
      return ms ~/ 60000;
    } catch (_) {
      return 9999;
    }
  }

  static Future<void> invalidate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTimestampKey);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kJobsKey);
      await prefs.remove(_kTimestampKey);
    } catch (_) {}
  }

  static Future<int> incrementViews(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kViewsPrefix$jobId';
      final current = prefs.getInt(key) ?? _baseViews(jobId);
      final next = current + 1;
      await prefs.setInt(key, next);
      return next;
    } catch (_) {
      return _baseViews(jobId);
    }
  }

  static Future<int> getViews(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kViewsPrefix$jobId';
      return prefs.getInt(key) ?? _baseViews(jobId);
    } catch (_) {
      return _baseViews(jobId);
    }
  }

  static int _baseViews(String jobId) {
    final hash = jobId.hashCode.abs();
    return 12 + (hash % 831);
  }

  static Future<void> saveUserLocation(String label) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_location_label', label);
    } catch (_) {}
  }

  static Future<String?> getUserLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_location_label');
    } catch (_) {
      return null;
    }
  }
}
