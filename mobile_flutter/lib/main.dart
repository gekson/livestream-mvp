import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/screens/home_screen.dart';
import 'package:mobile_flutter/services/socket_service.dart';
import 'package:mobile_flutter/services/webrtc_service.dart';
import 'package:mobile_flutter/services/settings_service.dart';
import 'package:mobile_flutter/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SocketService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => WebRTCService(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsService()..initialize(),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settingsService, child) {
          return MaterialApp(
            title: 'Livestream MVP',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: settingsService.enableDarkMode ? Brightness.dark : Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: settingsService.enableDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
