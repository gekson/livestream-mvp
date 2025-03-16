// src/screens/VideoCallScreen.js
import React, { useEffect, useState } from 'react';
import { View, StyleSheet, TouchableOpacity, Text } from 'react-native';
import { RTCView } from 'react-native-webrtc';
import { IconButton } from 'react-native-paper';
import { useChat } from '../contexts/ChatContext';
import useWebRTC from '../hooks/useWebRTC';

const VideoCallScreen = ({ navigation }) => {
  const { state, socketRef } = useChat();
  const [isMuted, setIsMuted] = useState(false);
  const [isCameraOff, setIsCameraOff] = useState(false);
  
  const {
    localStream,
    remoteStream,
    setupWebRTC,
    createOffer,
    handleAnswer,
    handleIceCandidate,
    cleanup,
  } = useWebRTC(socketRef);

  useEffect(() => {
    setupWebRTC();
    
    if (state.isHost) {
      socketRef.current.on('user-joined', async () => {
        const offer = await createOffer();
        socketRef.current.emit('video-offer', offer);
      });
    } else {
      socketRef.current.on('video-offer', async (offer) => {
        // Implementar lógica para responder à oferta
      });
    }
    
    socketRef.current.on('video-answer', (answer) => {
      handleAnswer(answer);
    });
    
    socketRef.current.on('ice-candidate', (candidate) => {
      handleIceCandidate(candidate);
    });
    
    return () => {
      cleanup();
    };
  }, []);

  const toggleMute = () => {
    if (localStream) {
      localStream.getAudioTracks().forEach(track => {
        track.enabled = !track.enabled;
        setIsMuted(!track.enabled);
      });
    }
  };

  const toggleCamera = () => {
    if (localStream) {
      localStream.getVideoTracks().forEach(track => {
        track.enabled = !track.enabled;
        setIsCameraOff(!track.enabled);
      });
    }
  };

  const endCall = () => {
    cleanup();
    navigation.goBack();
  };

  return (
    <View style={styles.container}>
      {remoteStream && (
        <RTCView
          streamURL={remoteStream.toURL()}
          style={styles.remoteStream}
          objectFit="cover"
        />
      )}
      
      {localStream && (
        <RTCView
          streamURL={localStream.toURL()}
          style={styles.localStream}
          objectFit="cover"
        />
      )}
      
      <View style={styles.controls}>
        <IconButton
          icon={isMuted ? "microphone-off" : "microphone"}
          color="#FFF"
          size={30}
          onPress={toggleMute}
          style={styles.controlButton}
        />
        <IconButton
          icon="phone-hangup"
          color="#F00"
          size={30}
          onPress={endCall}
          style={[styles.controlButton, styles.endCallButton]}
        />
        <IconButton
          icon={isCameraOff ? "camera-off" : "camera"}
          color="#FFF"
          size={30}
          onPress={toggleCamera}
          style={styles.controlButton}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  remoteStream: {
    flex: 1,
    width: '100%',
  },
  localStream: {
    position: 'absolute',
    top: 20,
    right: 20,
    width: 100,
    height: 150,
    borderRadius: 10,
    zIndex: 2,
  },
  controls: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'absolute',
    bottom: 30,
    left: 0,
    right: 0,
  },
  controlButton: {
    backgroundColor: 'rgba(0,0,0,0.5)',
    margin: 10,
    borderRadius: 30,
  },
  endCallButton: {
    backgroundColor: 'rgba(255,0,0,0.5)',
  },
});

export default VideoCallScreen;