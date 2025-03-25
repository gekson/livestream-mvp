import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/services/socket_service.dart';
import 'package:mobile_flutter/services/webrtc_service.dart';
import 'package:mobile_flutter/widgets/video_grid.dart';
import 'package:mobile_flutter/widgets/chat_widget.dart';
import 'package:mobile_flutter/utils/permission_helper.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  final String username;
  
  const RoomScreen({
    super.key,
    required this.roomId,
    required this.username,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with WidgetsBindingObserver {
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _isChatVisible = false;
  bool _isSettingsVisible = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupRoom();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leaveRoom();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Disable camera when app is in background
        if (_isCameraEnabled) {
          final webRTCService = Provider.of<WebRTCService>(context, listen: false);
          webRTCService.toggleCamera(false);
        }
        break;
      case AppLifecycleState.resumed:
        // Re-enable camera when app is in foreground
        if (_isCameraEnabled) {
          final webRTCService = Provider.of<WebRTCService>(context, listen: false);
          webRTCService.toggleCamera(true);
        }
        break;
      default:
        break;
    }
  }
  
  Future<void> _setupRoom() async {
    // Request permissions
    final hasPermissions = await PermissionHelper.requestMediaPermissions();
    if (!hasPermissions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and microphone permissions are required'),
          ),
        );
      }
      return;
    }
    
    // Initialize services
    final socketService = Provider.of<SocketService>(context, listen: false);
    final webRTCService = Provider.of<WebRTCService>(context, listen: false);
    
    // Join room
    socketService.joinRoom(widget.roomId, widget.username);
    
    // Initialize WebRTC
    webRTCService.initialize(socketService.socket);
    
    // Start local stream
    await webRTCService.startLocalStream();
  }
  
  void _leaveRoom() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    final webRTCService = Provider.of<WebRTCService>(context, listen: false);
    
    socketService.leaveRoom();
    webRTCService.stopLocalStream();
    webRTCService.closeAllPeerConnections();
  }
  
  void _toggleMicrophone() {
    setState(() {
      _isMicEnabled = !_isMicEnabled;
    });
    
    final webRTCService = Provider.of<WebRTCService>(context, listen: false);
    webRTCService.toggleMicrophone(_isMicEnabled);
  }
  
  void _toggleCamera() {
    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
    
    final webRTCService = Provider.of<WebRTCService>(context, listen: false);
    webRTCService.toggleCamera(_isCameraEnabled);
  }
  
  void _switchCamera() {
    final webRTCService = Provider.of<WebRTCService>(context, listen: false);
    webRTCService.switchCamera();
  }
  
  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
      if (_isChatVisible) {
        _isSettingsVisible = false;
      }
    });
  }
  
  void _toggleSettings() {
    setState(() {
      _isSettingsVisible = !_isSettingsVisible;
      if (_isSettingsVisible) {
        _isChatVisible = false;
      }
    });
  }
  
  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room'),
        content: const Text('Are you sure you want to leave this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Leave room
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _toggleSettings,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showLeaveDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video grid (takes most of the screen)
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Video grid
                  const VideoGrid(),
                  
                  // Settings panel (conditionally visible)
                  if (_isSettingsVisible)
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppBar(
                              title: const Text('Settings'),
                              automaticallyImplyLeading: false,
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _toggleSettings,
                                ),
                              ],
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  const Text(
                                    'Video Settings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    title: const Text('Camera'),
                                    trailing: Switch(
                                      value: _isCameraEnabled,
                                      onChanged: (value) {
                                        setState(() {
                                          _isCameraEnabled = value;
                                        });
                                        final webRTCService = Provider.of<WebRTCService>(
                                          context,
                                          listen: false,
                                        );
                                        webRTCService.toggleCamera(_isCameraEnabled);
                                      },
                                    ),
                                  ),
                                  ListTile(
                                    title: const Text('Switch Camera'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.flip_camera_ios),
                                      onPressed: _switchCamera,
                                    ),
                                  ),
                                  const Divider(),
                                  const Text(
                                    'Audio Settings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    title: const Text('Microphone'),
                                    trailing: Switch(
                                      value: _isMicEnabled,
                                      onChanged: (value) {
                                        setState(() {
                                          _isMicEnabled = value;
                                        });
                                        final webRTCService = Provider.of<WebRTCService>(
                                          context,
                                          listen: false,
                                        );
                                        webRTCService.toggleMicrophone(_isMicEnabled);
                                      },
                                    ),
                                  ),
                                  const Divider(),
                                  const Text(
                                    'Room Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    title: const Text('Room ID'),
                                    subtitle: Text(widget.roomId),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () {
                                        // Copy room ID to clipboard
                                      },
                                    ),
                                  ),
                                  ListTile(
                                    title: const Text('Your Name'),
                                    subtitle: Text(widget.username),
                                  ),
                                  Consumer<SocketService>(
                                    builder: (context, socketService, child) {
                                      final isHost = socketService.isCurrentUserHost();
                                      return ListTile(
                                        title: const Text('Role'),
                                        subtitle: Text(isHost ? 'Host' : 'Participant'),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Chat panel (conditionally visible)
            if (_isChatVisible)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: const ChatWidget(),
                ),
              ),
            
            // Control bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic toggle
                  IconButton(
                    icon: Icon(_isMicEnabled ? Icons.mic : Icons.mic_off),
                    onPressed: _toggleMicrophone,
                    color: _isMicEnabled ? null : Colors.red,
                  ),
                  
                  // Camera toggle
                  IconButton(
                    icon: Icon(_isCameraEnabled ? Icons.videocam : Icons.videocam_off),
                    onPressed: _toggleCamera,
                    color: _isCameraEnabled ? null : Colors.red,
                  ),
                  
                  // Switch camera
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios),
                    onPressed: _switchCamera,
                  ),
                  
                  // Chat toggle
                  IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: _toggleChat,
                    color: _isChatVisible ? Theme.of(context).colorScheme.primary : null,
                  ),
                  
                  // Leave room
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    onPressed: _showLeaveDialog,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}