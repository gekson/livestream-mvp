import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  // Request camera and microphone permissions
  static Future<bool> requestMediaPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    
    return statuses[Permission.camera]!.isGranted && 
           statuses[Permission.microphone]!.isGranted;
  }
  
  // Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }
  
  // Check if microphone permission is granted
  static Future<bool> isMicrophonePermissionGranted() async {
    return await Permission.microphone.isGranted;
  }
  
  // Open app settings if permissions are denied
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}