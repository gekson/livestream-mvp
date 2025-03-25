import 'package:http/http.dart' as http;
import 'dart:convert';
import 'logger_service.dart';

class ServerTestService {
  final String baseUrl;
  final LoggerService _logger = LoggerService();

  ServerTestService(this.baseUrl);

  Future<bool> testConnection() async {
    try {
      _logger.i('Testing connection to $baseUrl/health');
      final response = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      
      _logger.i('Server response: ${response.statusCode} ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getSocketHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/socket-health'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'code': response.statusCode};
    } catch (e) {
      _logger.e('Socket health check failed: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
}