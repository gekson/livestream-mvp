import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? tag;
  
  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'level': level.toString(),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'tag': tag,
    };
  }
  
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      tag: json['tag'],
    );
  }
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  final List<LogEntry> _logs = [];
  final int _maxLogEntries = 1000;
  
  // Singleton pattern
  factory LoggerService() => _instance;
  
  LoggerService._internal();
  
  List<LogEntry> get logs => List.unmodifiable(_logs);
  
  // Log a debug message
  void d(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }
  
  // Log an info message
  void i(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }
  
  // Log a warning message
  void w(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }
  
  // Log an error message
  void e(String message, {String? tag}) {
    _log(LogLevel.error, message, tag: tag);
  }
  
  // Internal log method
  void _log(LogLevel level, String message, {String? tag}) {
    final entry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      tag: tag,
    );
    
    _logs.add(entry);
    
    // Trim logs if they exceed the maximum
    if (_logs.length > _maxLogEntries) {
      _logs.removeRange(0, _logs.length - _maxLogEntries);
    }
    
    // Print to console in debug mode
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      switch (level) {
        case LogLevel.debug:
          debugPrint('DEBUG $prefix: $message');
          break;
        case LogLevel.info:
          debugPrint('INFO $prefix: $message');
          break;
        case LogLevel.warning:
          debugPrint('WARNING $prefix: $message');
          break;
        case LogLevel.error:
          debugPrint('ERROR $prefix: $message');
          break;
      }
    }
  }
  
  // Save logs to persistent storage
  Future<void> saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logs.map((log) => log.toJson()).toList();
      await prefs.setString('app_logs', logsJson.toString());
    } catch (e) {
      debugPrint('Error saving logs: $e');
    }
  }
  
  // Load logs from persistent storage
  Future<void> loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString('app_logs');
      if (logsString != null) {
        final logsJson = List<Map<String, dynamic>>.from(logsString as List);
        _logs.clear();
        _logs.addAll(logsJson.map((json) => LogEntry.fromJson(json)));
      }
    } catch (e) {
      debugPrint('Error loading logs: $e');
    }
  }
  
  // Clear all logs
  void clearLogs() {
    _logs.clear();
  }
  
  // Get logs filtered by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }
  
  // Get logs filtered by tag
  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }
}