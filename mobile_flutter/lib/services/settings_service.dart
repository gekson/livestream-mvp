import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  // Video settings
  bool _enableLowBandwidthMode = false;
  String _videoQuality = 'Medium'; // Low, Medium, High
  
  // Audio settings
  bool _enableEchoCancellation = true;
  bool _enableNoiseSuppression = true;
  bool _enableAutoGainControl = true;
  
  // Notification settings
  bool _enableNotifications = true;
  bool _enableMessageNotifications = true;
  bool _enableUserJoinNotifications = true;
  
  // UI settings
  bool _enableDarkMode = false;
  
  // Getters
  bool get enableLowBandwidthMode => _enableLowBandwidthMode;
  String get videoQuality => _videoQuality;
  bool get enableEchoCancellation => _enableEchoCancellation;
  bool get enableNoiseSuppression => _enableNoiseSuppression;
  bool get enableAutoGainControl => _enableAutoGainControl;
  bool get enableNotifications => _enableNotifications;
  bool get enableMessageNotifications => _enableMessageNotifications;
  bool get enableUserJoinNotifications => _enableUserJoinNotifications;
  bool get enableDarkMode => _enableDarkMode;
  
  // Initialize settings
  Future<void> initialize() async {
    await loadSettings();
  }
  
  // Load settings from shared preferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Video settings
      _enableLowBandwidthMode = prefs.getBool('enable_low_bandwidth_mode') ?? false;
      _videoQuality = prefs.getString('video_quality') ?? 'Medium';
      
      // Audio settings
      _enableEchoCancellation = prefs.getBool('enable_echo_cancellation') ?? true;
      _enableNoiseSuppression = prefs.getBool('enable_noise_suppression') ?? true;
      _enableAutoGainControl = prefs.getBool('enable_auto_gain_control') ?? true;
      
      // Notification settings
      _enableNotifications = prefs.getBool('enable_notifications') ?? true;
      _enableMessageNotifications = prefs.getBool('enable_message_notifications') ?? true;
      _enableUserJoinNotifications = prefs.getBool('enable_user_join_notifications') ?? true;
      
      // UI settings
      _enableDarkMode = prefs.getBool('enable_dark_mode') ?? false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }
  
  // Save a setting to shared preferences
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (e) {
      debugPrint('Error saving setting: $e');
    }
  }
  
  // Setters with persistence
  Future<void> setEnableLowBandwidthMode(bool value) async {
    _enableLowBandwidthMode = value;
    await _saveSetting('enable_low_bandwidth_mode', value);
    notifyListeners();
  }
  
  Future<void> setVideoQuality(String value) async {
    _videoQuality = value;
    await _saveSetting('video_quality', value);
    notifyListeners();
  }
  
  Future<void> setEnableEchoCancellation(bool value) async {
    _enableEchoCancellation = value;
    await _saveSetting('enable_echo_cancellation', value);
    notifyListeners();
  }
  
  Future<void> setEnableNoiseSuppression(bool value) async {
    _enableNoiseSuppression = value;
    await _saveSetting('enable_noise_suppression', value);
    notifyListeners();
  }
  
  Future<void> setEnableAutoGainControl(bool value) async {
    _enableAutoGainControl = value;
    await _saveSetting('enable_auto_gain_control', value);
    notifyListeners();
  }
  
  Future<void> setEnableNotifications(bool value) async {
    _enableNotifications = value;
    await _saveSetting('enable_notifications', value);
    notifyListeners();
  }
  
  Future<void> setEnableMessageNotifications(bool value) async {
    _enableMessageNotifications = value;
    await _saveSetting('enable_message_notifications', value);
    notifyListeners();
  }
  
  Future<void> setEnableUserJoinNotifications(bool value) async {
    _enableUserJoinNotifications = value;
    await _saveSetting('enable_user_join_notifications', value);
    notifyListeners();
  }
  
  Future<void> setEnableDarkMode(bool value) async {
    _enableDarkMode = value;
    await _saveSetting('enable_dark_mode', value);
    notifyListeners();
  }
  
  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _enableLowBandwidthMode = false;
    _videoQuality = 'Medium';
    _enableEchoCancellation = true;
    _enableNoiseSuppression = true;
    _enableAutoGainControl = true;
    _enableNotifications = true;
    _enableMessageNotifications = true;
    _enableUserJoinNotifications = true;
    _enableDarkMode = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}