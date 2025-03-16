// src/hooks/useWebRTC.js
import { useEffect, useRef, useState } from 'react';
import { mediaDevices, RTCPeerConnection, RTCSessionDescription } from 'react-native-webrtc';

export default function useWebRTC(socketRef) {
  const [localStream, setLocalStream] = useState(null);
  const [remoteStream, setRemoteStream] = useState(null);
  const peerConnectionRef = useRef(null);
  
  const setupWebRTC = async () => {
    // Configuração das restrições de mídia
    const mediaConstraints = {
      audio: true,
      video: {
        facingMode: 'user',
      },
    };
    
    try {
      // Obter stream local
      const stream = await mediaDevices.getUserMedia(mediaConstraints);
      setLocalStream(stream);
      
      // Configuração do peer connection
      const configuration = { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] };
      const peerConnection = new RTCPeerConnection(configuration);
      
      // Adicionar tracks ao peer connection
      stream.getTracks().forEach(track => {
        peerConnection.addTrack(track, stream);
      });
      
      // Configurar handlers para stream remoto
      peerConnection.ontrack = event => {
        setRemoteStream(event.streams[0]);
      };
      
      // Configurar eventos de ICE
      peerConnection.onicecandidate = event => {
        if (event.candidate) {
          socketRef.current.emit('ice-candidate', event.candidate);
        }
      };
      
      peerConnectionRef.current = peerConnection;
    } catch (error) {
      console.error('Error setting up WebRTC:', error);
    }
  };
  
  const createOffer = async () => {
    try {
      const offer = await peerConnectionRef.current.createOffer();
      await peerConnectionRef.current.setLocalDescription(offer);
      return offer;
    } catch (error) {
      console.error('Error creating offer:', error);
    }
  };
  
  const handleAnswer = async (answer) => {
    try {
      await peerConnectionRef.current.setRemoteDescription(new RTCSessionDescription(answer));
    } catch (error) {
      console.error('Error handling answer:', error);
    }
  };
  
  const handleIceCandidate = async (candidate) => {
    try {
      await peerConnectionRef.current.addIceCandidate(candidate);
    } catch (error) {
      console.error('Error handling ICE candidate:', error);
    }
  };
  
  const cleanup = () => {
    if (localStream) {
      localStream.getTracks().forEach(track => track.stop());
    }
    if (peerConnectionRef.current) {
      peerConnectionRef.current.close();
    }
  };
  
  return {
    localStream,
    remoteStream,
    setupWebRTC,
    createOffer,
    handleAnswer,
    handleIceCandidate,
    cleanup,
  };
}