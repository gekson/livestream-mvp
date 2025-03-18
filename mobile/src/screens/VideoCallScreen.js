import React, { useEffect, useState } from 'react'; // Importe useState explicitamente
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { RTCView } from 'react-native-webrtc';
import { IconButton } from 'react-native-paper';
import { useChat } from '../contexts/ChatContext';
import useWebRTC from '../hooks/useWebRTC';
import { PermissionsAndroid } from 'react-native';

const VideoCallScreen = ({ navigation }) => {
  const { state, socketRef } = useChat();
  const { localStream, remoteStream, cleanup } = useWebRTC(socketRef);
  const [isMuted, setIsMuted] = useState(false); // Correção: useState em vez de us
  const [isCameraOff, setIsCameraOff] = useState(false); // Correção: useState em vez de us

  const requestPermissions = async () => {
    try {
      const granted = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.CAMERA,
        PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
      ]);
      if (
        granted['android.permission.CAMERA'] === PermissionsAndroid.RESULTS.GRANTED &&
        granted['android.permission.RECORD_AUDIO'] === PermissionsAndroid.RESULTS.GRANTED
      ) {
        console.log('Permissões concedidas');
      } else {
        console.log('Permissões negadas');
      }
    } catch (err) {
      console.warn(err);
    }
  };

  useEffect(() => {
    requestPermissions();
  }, []);
  
  useEffect(() => {
    return () => {
      cleanup();
    };
  }, []);

  const toggleMute = () => {
    if (localStream) {
      localStream.getAudioTracks().forEach(track => {
        track.enabled = !isMuted;
        setIsMuted(!isMuted);
      });
    }
  };

  const toggleCamera = () => {
    if (localStream) {
      localStream.getVideoTracks().forEach(track => {
        track.enabled = !isCameraOff;
        setIsCameraOff(!isCameraOff);
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
          icon={isMuted ? 'microphone-off' : 'microphone'}
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
          icon={isCameraOff ? 'camera-off' : 'camera'}
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
    width: 120,
    height: 180,
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