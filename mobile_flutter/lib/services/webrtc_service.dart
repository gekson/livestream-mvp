import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobile_flutter/utils/webrtc_helper.dart';

class RemoteStream {
  final String id;
  final MediaStream stream;
  final String? username;
  
  RemoteStream({
    required this.id,
    required this.stream,
    this.username,
  });
}

class WebRTCService extends ChangeNotifier {
  MediaStream? localStream;
  final List<RemoteStream> remoteStreams = [];
  final Map<String, RTCPeerConnection> peerConnections = {};
  io.Socket? _socket;
  
  // Initialize WebRTC service
  Future<void> initialize(io.Socket socket) async {
    _socket = socket;
    _setupSocketListeners();
  }
  
  // Set up socket listeners for WebRTC signaling
  void _setupSocketListeners() {
    _socket?.on('routerRtpCapabilities', (data) {
      debugPrint('Router RTP capabilities received');
      // Handle router RTP capabilities
    });
    
    _socket?.on('existingProducers', (data) {
      debugPrint('Existing producers received: $data');
      // Handle existing producers
    });
    
    _socket?.on('newProducer', (data) {
      debugPrint('New producer received: $data');
      // Handle new producer
    });
    
    _socket?.on('producerClosed', (data) {
      debugPrint('Producer closed: $data');
      // Handle producer closed
    });
    
    _socket?.on('offer', (data) async {
      debugPrint('Offer received from: ${data['from']}');
      await _handleOffer(data);
    });
    
    _socket?.on('answer', (data) async {
      debugPrint('Answer received from: ${data['from']}');
      await _handleAnswer(data);
    });
    
    _socket?.on('ice-candidate', (data) async {
      debugPrint('ICE candidate received from: ${data['from']}');
      await _handleIceCandidate(data);
    });
  }
  
  // Start local media stream
  Future<void> startLocalStream() async {
    try {
      localStream = await WebRTCHelper.getUserMedia();
      notifyListeners();
      debugPrint('Local stream started');
    } catch (e) {
      debugPrint('Error starting local stream: $e');
    }
  }
  
  // Stop local media stream
  void stopLocalStream() {
    localStream?.getTracks().forEach((track) {
      track.stop();
    });
    localStream?.dispose();
    localStream = null;
    notifyListeners();
    debugPrint('Local stream stopped');
  }
  
  // Create a peer connection for a specific user
  Future<RTCPeerConnection> _createPeerConnection(String userId) async {
    final peerConnection = await WebRTCHelper.createPeerConnectionInstance();
    
    // Add local stream tracks to the peer connection
    if (localStream != null) {
      WebRTCHelper.addTracksToConnection(localStream!, peerConnection);
    }
    
    // Set up event handlers
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      _sendIceCandidate(userId, candidate);
    };
    
    peerConnection.onTrack = (RTCTrackEvent event) {
      _handleRemoteTrack(userId, event);
    };
    
    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('Connection state changed: $state');
    };
    
    peerConnections[userId] = peerConnection;
    return peerConnection;
  }
  
  // Handle an offer from a remote peer
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    final String from = data['from'];
    final RTCSessionDescription offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );
    
    RTCPeerConnection peerConnection;
    if (peerConnections.containsKey(from)) {
      peerConnection = peerConnections[from]!;
    } else {
      peerConnection = await _createPeerConnection(from);
    }
    
    await peerConnection.setRemoteDescription(offer);
    
    final RTCSessionDescription answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    
    _sendAnswer(from, answer);
  }
  
  // Handle an answer from a remote peer
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final String from = data['from'];
    final RTCSessionDescription answer = RTCSessionDescription(
      data['answer']['sdp'],
      data['answer']['type'],
    );
    
    if (peerConnections.containsKey(from)) {
      await peerConnections[from]!.setRemoteDescription(answer);
    }
  }
  
  // Handle an ICE candidate from a remote peer
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    final String from = data['from'];
    final RTCIceCandidate candidate = RTCIceCandidate(
      data['candidate']['candidate'],
      data['candidate']['sdpMid'],
      data['candidate']['sdpMLineIndex'],
    );
    
    if (peerConnections.containsKey(from)) {
      await peerConnections[from]!.addCandidate(candidate);
    }
  }
  
  // Handle remote track from a peer connection
  void _handleRemoteTrack(String userId, RTCTrackEvent event) {
    if (event.streams.isEmpty) return;
    
    final stream = event.streams[0];
    
    // Check if we already have this stream
    final existingStreamIndex = remoteStreams.indexWhere((s) => s.id == userId);
    
    if (existingStreamIndex >= 0) {
      // Update existing stream
      remoteStreams[existingStreamIndex] = RemoteStream(
        id: userId,
        stream: stream,
        username: remoteStreams[existingStreamIndex].username,
      );
    } else {
      // Add new stream
      remoteStreams.add(RemoteStream(
        id: userId,
        stream: stream,
      ));
    }
    
    notifyListeners();
  }
  
  // Send an offer to a remote peer
  Future<void> createOffer(String userId) async {
    try {
      RTCPeerConnection peerConnection;
      if (peerConnections.containsKey(userId)) {
        peerConnection = peerConnections[userId]!;
      } else {
        peerConnection = await _createPeerConnection(userId);
      }
      
      final RTCSessionDescription offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);
      
      _sendOffer(userId, offer);
    } catch (e) {
      debugPrint('Error creating offer: $e');
    }
  }
  
  // Send an offer to a remote peer
  void _sendOffer(String to, RTCSessionDescription offer) {
    _socket?.emit('offer', {
      'to': to,
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    });
  }
  
  // Send an answer to a remote peer
  void _sendAnswer(String to, RTCSessionDescription answer) {
    _socket?.emit('answer', {
      'to': to,
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    });
  }
  
  // Send an ICE candidate to a remote peer
  void _sendIceCandidate(String to, RTCIceCandidate candidate) {
    _socket?.emit('ice-candidate', {
      'to': to,
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    });
  }
  
  // Update username for a remote stream
  void updateRemoteUsername(String userId, String username) {
    final index = remoteStreams.indexWhere((s) => s.id == userId);
    if (index >= 0) {
      remoteStreams[index] = RemoteStream(
        id: userId,
        stream: remoteStreams[index].stream,
        username: username,
      );
      notifyListeners();
    }
  }
  
  // Close a peer connection
  void closePeerConnection(String userId) {
    if (peerConnections.containsKey(userId)) {
      peerConnections[userId]!.close();
      peerConnections.remove(userId);
    }
    
    remoteStreams.removeWhere((stream) => stream.id == userId);
    notifyListeners();
  }
  
  // Close all peer connections
  void closeAllPeerConnections() {
    for (final connection in peerConnections.values) {
      connection.close();
    }
    peerConnections.clear();
    remoteStreams.clear();
    notifyListeners();
  }
  
  // Toggle microphone
  void toggleMicrophone(bool enabled) {
    localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }
  
  // Toggle camera
  void toggleCamera(bool enabled) {
    localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }
  
  // Switch camera (front/back)
  Future<void> switchCamera() async {
    final videoTrack = localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }
  
  // Set low bandwidth mode
  void setLowBandwidthMode(bool enabled) {
    // Adjust video constraints for low bandwidth
    if (enabled) {
      _applyLowBandwidthConstraints();
    } else {
      _applyNormalBandwidthConstraints();
    }
    debugPrint('Low bandwidth mode set to: $enabled');
  }
  
  // Set video quality
  void setVideoQuality(String quality) {
    // Apply different video constraints based on quality
    switch (quality) {
      case 'Low':
        _applyVideoQualityConstraints(320, 240, 15);
        break;
      case 'Medium':
        _applyVideoQualityConstraints(640, 480, 24);
        break;
      case 'High':
        _applyVideoQualityConstraints(1280, 720, 30);
        break;
    }
    debugPrint('Video quality set to: $quality');
  }
  
  // Apply video quality constraints
  void _applyVideoQualityConstraints(int width, int height, int frameRate) {
    // This would typically restart the video track with new constraints
    // For simplicity, we're just logging it for now
    debugPrint('Setting video constraints: ${width}x$height @$frameRate fps');
    // Implementation would depend on the specific WebRTC implementation
  }
  
  // Apply low bandwidth constraints
  void _applyLowBandwidthConstraints() {
    _applyVideoQualityConstraints(320, 240, 15);
  }
  
  // Apply normal bandwidth constraints
  void _applyNormalBandwidthConstraints() {
    _applyVideoQualityConstraints(640, 480, 24);
  }
  
  // Set echo cancellation
  void setEchoCancellation(bool enabled) {
    // Apply echo cancellation setting
    debugPrint('Echo cancellation set to: $enabled');
    // This would typically modify the audio constraints
  }
  
  // Set noise suppression
  void setNoiseSuppression(bool enabled) {
    // Apply noise suppression setting
    debugPrint('Noise suppression set to: $enabled');
    // This would typically modify the audio constraints
  }
  
  // Set auto gain control
  void setAutoGainControl(bool enabled) {
    // Apply auto gain control setting
    debugPrint('Auto gain control set to: $enabled');
    // This would typically modify the audio constraints
  }
  
  @override
  void dispose() {
    stopLocalStream();
    closeAllPeerConnections();
    super.dispose();
  }
}