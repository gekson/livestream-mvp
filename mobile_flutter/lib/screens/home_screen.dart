import 'package:flutter/material.dart';
import 'package:mobile_flutter/screens/room_screen.dart';
import 'package:mobile_flutter/services/analytics_service.dart';
import 'package:mobile_flutter/widgets/server_toggle_button.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _analyticsService = AnalyticsService();
  
  @override
  void initState() {
    super.initState();
    _trackAppLaunch();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }
  
  Future<void> _trackAppLaunch() async {
    await _analyticsService.trackAppLaunch();
  }
  
  void _joinRoom() {
    if (_formKey.currentState?.validate() ?? false) {
      final username = _usernameController.text.trim();
      final roomId = _roomIdController.text.trim();
      
      _analyticsService.trackRoomJoin(roomId);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomScreen(
            roomId: roomId,
            username: username,
          ),
        ),
      );
    }
  }
  
  void _createRoom() {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a username'),
        ),
      );
      return;
    }
    
    final username = _usernameController.text.trim();
    final roomId = const Uuid().v4().substring(0, 8); // Generate a shorter room ID
    
    _analyticsService.trackRoomCreation(roomId);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomScreen(
          roomId: roomId,
          username: username,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livestream MVP'),
        actions: [
          const ServerToggleButton(),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Icon(
                  Icons.video_call,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                
                // App title
                Text(
                  'Livestream MVP',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // App subtitle
                Text(
                  'Video conferencing made simple',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Enter your display name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                // Room ID field
                TextFormField(
                  controller: _roomIdController,
                  decoration: const InputDecoration(
                    labelText: 'Room ID',
                    hintText: 'Enter room ID to join',
                    prefixIcon: Icon(Icons.meeting_room),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a room ID';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _joinRoom(),
                ),
                const SizedBox(height: 24),
                
                // Join room button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _joinRoom,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Join Room'),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Create room button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _createRoom,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Create New Room'),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Info text
                Text(
                  'By joining, you agree to our Terms of Service and Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}