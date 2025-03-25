import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  
  // Singleton pattern
  factory AnalyticsService() => _instance;
  
  AnalyticsService._internal();
  
  // Track app launch
  Future<void> trackAppLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int launchCount = prefs.getInt('app_launch_count') ?? 0;
      await prefs.setInt('app_launch_count', launchCount + 1);
      
      // Track first launch date if not already set
      if (!prefs.containsKey('first_launch_date')) {
        await prefs.setString('first_launch_date', DateTime.now().toIso8601String());
      }
      
      // Update last launch date
      await prefs.setString('last_launch_date', DateTime.now().toIso8601String());
      
      debugPrint('App launch tracked: ${launchCount + 1} times');
    } catch (e) {
      debugPrint('Error tracking app launch: $e');
    }
  }
  
  // Track room join
  Future<void> trackRoomJoin(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int roomJoinCount = prefs.getInt('room_join_count') ?? 0;
      await prefs.setInt('room_join_count', roomJoinCount + 1);
      
      // Store last joined room
      await prefs.setString('last_joined_room', roomId);
      
      // Store join timestamp
      await prefs.setString('last_room_join_time', DateTime.now().toIso8601String());
      
      debugPrint('Room join tracked: $roomId');
    } catch (e) {
      debugPrint('Error tracking room join: $e');
    }
  }
  
  // Track room creation
  Future<void> trackRoomCreation(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int roomCreateCount = prefs.getInt('room_create_count') ?? 0;
      await prefs.setInt('room_create_count', roomCreateCount + 1);
      
      // Store created room
      await prefs.setString('last_created_room', roomId);
      
      // Store creation timestamp
      await prefs.setString('last_room_create_time', DateTime.now().toIso8601String());
      
      debugPrint('Room creation tracked: $roomId');
    } catch (e) {
      debugPrint('Error tracking room creation: $e');
    }
  }
  
  // Track message sent
  Future<void> trackMessageSent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int messageSentCount = prefs.getInt('message_sent_count') ?? 0;
      await prefs.setInt('message_sent_count', messageSentCount + 1);
      
      debugPrint('Message sent tracked');
    } catch (e) {
      debugPrint('Error tracking message sent: $e');
    }
  }
  
  // Get analytics data
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'app_launch_count': prefs.getInt('app_launch_count') ?? 0,
        'first_launch_date': prefs.getString('first_launch_date'),
        'last_launch_date': prefs.getString('last_launch_date'),
        'room_join_count': prefs.getInt('room_join_count') ?? 0,
        'room_create_count': prefs.getInt('room_create_count') ?? 0,
        'message_sent_count': prefs.getInt('message_sent_count') ?? 0,
        'last_joined_room': prefs.getString('last_joined_room'),
        'last_created_room': prefs.getString('last_created_room'),
      };
    } catch (e) {
      debugPrint('Error getting analytics data: $e');
      return {};
    }
  }
  
  // Clear analytics data
  Future<void> clearAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('app_launch_count');
      await prefs.remove('first_launch_date');
      await prefs.remove('last_launch_date');
      await prefs.remove('room_join_count');
      await prefs.remove('room_create_count');
      await prefs.remove('message_sent_count');
      await prefs.remove('last_joined_room');
      await prefs.remove('last_created_room');
      await prefs.remove('last_room_join_time');
      await prefs.remove('last_room_create_time');
      
      debugPrint('Analytics data cleared');
    } catch (e) {
      debugPrint('Error clearing analytics data: $e');
    }
  }
}