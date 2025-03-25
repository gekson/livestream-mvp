import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';

class WebRTCHelper {
  // Default media constraints
  static final Map<String, dynamic> _defaultMediaConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': {
      'mandatory': {
        'minWidth': 640,
        'minHeight': 480,
        'minFrameRate': 24,
      },
      'facingMode': 'user',
      'optional': [],
    }
  };

  // Default peer connection configuration with STUN servers
  static final Map<String, dynamic> _defaultPeerConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ]
  };

  // Get user media with default constraints
  static Future<MediaStream> getUserMedia() async {
    try {
      return await navigator.mediaDevices.getUserMedia(_defaultMediaConstraints);
    } catch (e) {
      debugPrint('Error getting user media: $e');
      rethrow;
    }
  }

  // Create a peer connection with default configuration
  static Future<RTCPeerConnection> createPeerConnectionInstance() async {
    try {
      // Usando a função correta da biblioteca flutter_webrtc
      return await createPeerConnection(_defaultPeerConfig);
    } catch (e) {
      debugPrint('Error creating peer connection: $e');
      rethrow;
    }
  }

  // Add tracks from a media stream to a peer connection
  static void addTracksToConnection(
      MediaStream stream, RTCPeerConnection peerConnection) {
    stream.getTracks().forEach((track) {
      peerConnection.addTrack(track, stream);
    });
  }

  // Simplified method to get constraints for different video qualities
  static Map<String, dynamic> getConstraintsForQuality(String quality, {
    bool? echoCancellation,
    bool? noiseSuppression,
    bool? autoGainControl,
  }) {
    final constraints = Map<String, dynamic>.from(_defaultMediaConstraints);
    final audioSettings = constraints['audio'] as Map<String, dynamic>;
    final videoSettings = constraints['video'] as Map<String, dynamic>;
    final videoMandatory = videoSettings['mandatory'] as Map<String, dynamic>;
    
    // Apply audio settings if provided
    if (echoCancellation != null) {
      audioSettings['echoCancellation'] = echoCancellation;
    }
    
    if (noiseSuppression != null) {
      audioSettings['noiseSuppression'] = noiseSuppression;
    }
    
    if (autoGainControl != null) {
      audioSettings['autoGainControl'] = autoGainControl;
    }
    
    // Apply video settings based on quality
    switch (quality) {
      case 'Low':
        videoMandatory['minWidth'] = 320;
        videoMandatory['minHeight'] = 240;
        videoMandatory['minFrameRate'] = 15;
        break;
      case 'Medium':
        videoMandatory['minWidth'] = 640;
        videoMandatory['minHeight'] = 480;
        videoMandatory['minFrameRate'] = 24;
        break;
      case 'High':
        videoMandatory['minWidth'] = 1280;
        videoMandatory['minHeight'] = 720;
        videoMandatory['minFrameRate'] = 30;
        break;
    }
    
    return constraints;
  }

  // Get low bandwidth constraints
  static Map<String, dynamic> getLowBandwidthConstraints() {
    return getConstraintsForQuality('Low');
  }

  // Restart media stream with new constraints
  static Future<MediaStream> restartMediaStream(
      Map<String, dynamic> constraints) async {
    try {
      return await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      debugPrint('Error restarting media stream: $e');
      rethrow;
    }
  }
}