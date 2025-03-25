import 'dart:async';
import 'dart:io' show Platform;
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobile_flutter/models/message.dart';

import 'logger_service.dart' show LoggerService;
// Initialize socket connection
import 'package:mobile_flutter/services/server_test_service.dart';

// Set this to true when testing on emulator, false for physical device
const bool USE_EMULATOR_URL = false; // Change to false for physical devices

class SocketService extends ChangeNotifier {
  late io.Socket socket;
  bool isConnected = false;
  String? username;
  String? roomId;
  List<ChatMessage> messages = [];
  List<Map<String, dynamic>> users = [];
  String currentServerUrl = 'https://slow-books-remain.loca.lt'; // Default URL
  
  // Initialize socket connection
  static bool useEmulatorUrl = false;
  
  // Add this method to toggle the URL and reconnect
  void toggleServerUrl() {
    SocketService.useEmulatorUrl = !SocketService.useEmulatorUrl;
    // Reinitialize the socket with the new URL
    disconnect();
    initialize();
    LoggerService().i('Switched to ${SocketService.useEmulatorUrl ? "emulator" : "physical device"} URL');
  }
  
  
  
  // Add to your class
  late ServerTestService _serverTestService;
  
  // Update initialize method
  Future<void> initialize() async {
    // Hardcoded server URLs for different environments
    const String PHYSICAL_DEVICE_URL = 'http://192.168.0.37:3001';
    const String EMULATOR_URL = 'http://10.0.2.2:3001';
    const String NGROK_URL = 'https://fe73-179-214-115-44.ngrok-free.app';
    
    // Try multiple URLs in order of preference
    final List<String> urlsToTry = [
      PHYSICAL_DEVICE_URL,  // Try direct IP first
      NGROK_URL,           // Then try ngrok
      EMULATOR_URL,        // Then try emulator URL
    ];
    
    String? workingUrl;
    bool isConnected = false;
    
    // Try each URL until one works
    for (final url in urlsToTry) {
      LoggerService().i('Trying connection to $url');
      currentServerUrl = url;
      
      _serverTestService = ServerTestService(url);
      try {
        final connected = await _serverTestService.testConnection();
        if (connected) {
          LoggerService().i('Successfully connected to $url');
          workingUrl = url;
          isConnected = true;
          break;
        }
      } catch (e) {
        LoggerService().e('Error connecting to $url: $e');
      }
    }
    
    // Use the working URL or default to the direct IP
    currentServerUrl = workingUrl ?? PHYSICAL_DEVICE_URL;
    LoggerService().i('Using server URL: $currentServerUrl');
    
    // Create socket with more robust options
    // socket = io.io(
    //   currentServerUrl,
    //   io.OptionBuilder()
    //     .setTransports(['polling', 'websocket']) // Try both transport methods
    //     .disableAutoConnect()
    //     .enableForceNew()
    //     .enableReconnection()
    //     .setReconnectionAttempts(10)
    //     .setReconnectionDelay(3000)
    //     .setTimeout(30000)
    //     .build(),
    // );

    socket = io.io(currentServerUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],  // Add polling as fallback
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
      'timeout': 20000,  // Increase timeout
    });
    
    LoggerService().i('SocketService initialized with $currentServerUrl');
    _setupSocketListeners();
    
    // Start the keep-alive timer
    _startKeepAlive();
    
    // Connect manually after setting up listeners
    LoggerService().i('Manually connecting socket...');
    socket.connect();
  }
  
  // Set up socket event listeners
  void _setupSocketListeners() {
    socket.onConnect((_) {
      LoggerService().i('Socket connected with ID: ${socket.id}');
      isConnected = true;
      
      // If we were in a room, rejoin it
      if (roomId != null && username != null) {
        LoggerService().i('Rejoining room $roomId as $username after reconnect');
        joinRoom(roomId!, username!);
      }
      
      notifyListeners();
    });
    
    socket.onConnecting((_) {
      LoggerService().i('Socket connecting...');
    });
    
    // Add connection acknowledgment listener
    socket.on('connection-ack', (data) {
      LoggerService().i('Connection acknowledged by server: $data');
    });
    
    // Add optional MediaSoup event handlers
    socket.on('routerRtpCapabilities', (data) {
      LoggerService().i('Received MediaSoup router capabilities');
      // Handle MediaSoup capabilities if needed
    });
    
    socket.on('existingProducers', (data) {
      LoggerService().i('Received existing producers: $data');
      // Handle existing producers if needed
    });
    
    // Add join success listener
    socket.on('join-success', (data) {
      LoggerService().i('Successfully joined room: $data');
    });
    
    socket.onDisconnect((_) {
      LoggerService().w('Socket disconnected');
      isConnected = false;
      notifyListeners();
    });
    
    socket.onConnectError((error) {
      LoggerService().e('Socket connection error: $error');
      isConnected = false;
      notifyListeners();
    });
    
    socket.onConnectTimeout((_) {
      LoggerService().e('Socket connection timeout');
      isConnected = false;
      notifyListeners();
    });
    
    socket.onError((error) {
      LoggerService().e('Socket error: $error');
      notifyListeners();
    });
    
    // Make sure this event name matches what your server is emitting
    socket.on('message', (data) {
      LoggerService().d('Received message event with data: $data');
      _handleNewMessage(data);
    });
    
    // You might want to listen for other message events if your server uses different names
    socket.on('chat-message', (data) {
      LoggerService().d('Received chat-message event with data: $data');
      _handleNewMessage(data);
    });
    
    socket.on('user-joined', (data) {
      _handleUserJoined(data);
    });
    
    socket.on('user-left', (data) {
      _handleUserLeft(data);
    });
    
    socket.on('room-users', (data) {
      _handleRoomUsers(data);
    });
  }
  
  // Keep connection alive with periodic pings
  Timer? _keepAliveTimer;
  
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (socket.connected) {
        LoggerService().d('Sending keep-alive ping');
        socket.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
      } else if (isConnected) {
        LoggerService().w('Socket appears disconnected but state is connected, reconnecting...');
        socket.connect();
      }
    });
  }
  
  @override
  void dispose() {
    _keepAliveTimer?.cancel();
    disconnect();
    super.dispose();
  }
  
  // Set up socket event listeners
  // void _setupSocketListeners() {
  //   socket.onConnect((_) {
  //     LoggerService().i('Socket connected with ID: ${socket.id}');
  //     isConnected = true;
      
  //     // If we were in a room, rejoin it
  //     if (roomId != null && username != null) {
  //       LoggerService().i('Rejoining room $roomId as $username after reconnect');
  //       joinRoom(roomId!, username!);
  //     }
      
  //     notifyListeners();
  //   });
    
  //   // Add connection acknowledgment listener
  //   socket.on('connection-ack', (data) {
  //     LoggerService().i('Connection acknowledged by server: $data');
  //   });
    
  //   // Add join success listener
  //   socket.on('join-success', (data) {
  //     LoggerService().i('Successfully joined room: $data');
  //   });
    
  //   // Rest of your listeners...
  // }
  
  // Handle new message from server with better error handling
  void _handleNewMessage(dynamic data) {
    LoggerService().d('Received message: $data');
    try {
      // Handle both Map and String formats
      final Map<String, dynamic> messageData;
      if (data is Map) {
        messageData = Map<String, dynamic>.from(data);
      } else if (data is String) {
        messageData = {'text': data, 'sender': 'System', 'timestamp': DateTime.now().toIso8601String()};
      } else {
        throw FormatException('Unexpected message format: ${data.runtimeType}');
      }
      
      final message = ChatMessage.fromJson(messageData, socket.id ?? '');
      messages.add(message);
      LoggerService().d('Messages count: ${messages.length}');
      notifyListeners();
    } catch (e) {
      LoggerService().e('Error processing message: $e');
      LoggerService().e('Message data: $data');
    }
  }
  
  // Handle user joined event
  void _handleUserJoined(Map<String, dynamic> data) {
    debugPrint('User joined: ${data['username']}');
    
    // Add system message
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '${data['username']} joined the room',
      sender: 'System',
      senderId: 'system',
      timestamp: DateTime.now(),
      isFromMe: false,
    );
    
    messages.add(systemMessage);
    notifyListeners();
  }
  
  // Handle user left event
  void _handleUserLeft(Map<String, dynamic> data) {
    debugPrint('User left: ${data['username']}');
    
    // Add system message
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '${data['username']} left the room',
      sender: 'System',
      senderId: 'system',
      timestamp: DateTime.now(),
      isFromMe: false,
    );
    
    messages.add(systemMessage);
    notifyListeners();
  }
  
  // Handle room users event
  void _handleRoomUsers(List<dynamic> data) {
    users = List<Map<String, dynamic>>.from(data);
    notifyListeners();
  }
  
  // Join a room
  void joinRoom(String roomId, String username) {
    this.roomId = roomId;
    this.username = username;
    
    socket.emit('join-room', {
      'roomId': roomId,
      'username': username,
    });
    
    // Clear previous messages
    messages.clear();
    notifyListeners();
  }
  
  // Leave the current room
  void leaveRoom() {
    if (roomId != null) {
      socket.emit('leave-room', {
        'roomId': roomId,
      });
      
      roomId = null;
      messages.clear();
      users.clear();
      notifyListeners();
    }
  }
  
  // Send a message to the current room
  void sendMessage(String text) {
    if (roomId == null || username == null) return;
    
    final message = {
      'roomId': roomId,
      'text': text,
      'sender': username,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    socket.emit('message', message);
    
    // Add message to local list (optimistic update)
    final localMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: username!,
      senderId: socket.id ?? '',
      timestamp: DateTime.now(),
      isFromMe: true,
    );
    
    messages.add(localMessage);
    notifyListeners();
  }
  
  // Get users in the current room
  List<Map<String, dynamic>> getRoomUsers() {
    return users;
  }
  
  // Check if a user is the room host
  bool isUserHost(String userId) {
    if (users.isEmpty) return false;
    
    final hostUser = users.firstWhere(
      (user) => user['isHost'] == true,
      orElse: () => {},
    );
    
    return hostUser.isNotEmpty && hostUser['id'] == userId;
  }
  
  // Check if the current user is the room host
  bool isCurrentUserHost() {
    return isUserHost(socket.id ?? '');
  }
  
  // Disconnect socket
  void disconnect() {
    socket.disconnect();
  }
  
  // Connect with a specific server URL
  void connectToServer(String serverUrl) {
    LoggerService().i('Manually connecting to $serverUrl');
    currentServerUrl = serverUrl;
    
    // Disconnect existing socket if connected
    if (socket.connected) {
      socket.disconnect();
    }
    
    // Create new socket with the provided URL
    socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['polling', 'websocket'],  // Start with polling, then upgrade to websocket
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'timeout': 30000,
      'pingInterval': 5000,
      'pingTimeout': 10000,
    });
    
    _setupSocketListeners();
    socket.connect();
    notifyListeners();
  }
}