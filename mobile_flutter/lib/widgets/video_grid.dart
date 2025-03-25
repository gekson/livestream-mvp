import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/services/webrtc_service.dart';

class VideoGrid extends StatelessWidget {
  const VideoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebRTCService>(
      builder: (context, webRTCService, child) {
        final localStream = webRTCService.localStream;
        final remoteStreams = webRTCService.remoteStreams;
        
        // Calculate grid dimensions based on number of streams
        final totalStreams = 1 + remoteStreams.length; // Local + remote
        int columns;
        
        if (totalStreams <= 1) {
          columns = 1;
        } else if (totalStreams <= 4) {
          columns = 2;
        } else {
          columns = 3;
        }
        
        return Container(
          color: Colors.black87,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 4 / 3, // Standard video aspect ratio
            ),
            itemCount: totalStreams,
            itemBuilder: (context, index) {
              if (index == 0 && localStream != null) {
                // Local video
                return VideoItem(
                  stream: localStream,
                  isLocal: true,
                  username: 'You',
                );
              } else if (index > 0 && index - 1 < remoteStreams.length) {
                // Remote videos
                final remoteStream = remoteStreams[index - 1];
                return VideoItem(
                  stream: remoteStream.stream,
                  isLocal: false,
                  username: remoteStream.username ?? 'User ${index}',
                );
              } else {
                // Placeholder for empty slots
                return const Center(
                  child: Icon(
                    Icons.videocam_off,
                    size: 48,
                    color: Colors.white54,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

class VideoItem extends StatelessWidget {
  final MediaStream stream;
  final bool isLocal;
  final String username;
  
  const VideoItem({
    super.key,
    required this.stream,
    required this.isLocal,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video renderer
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: isLocal ? Colors.blue : Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: RTCVideoView(
              RTCVideoRenderer()..srcObject = stream,
              mirror: isLocal, // Mirror local video
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
        
        // Username label
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLocal)
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.white,
                  ),
                if (isLocal)
                  const SizedBox(width: 4),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}