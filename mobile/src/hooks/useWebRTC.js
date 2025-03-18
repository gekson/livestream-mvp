import { useState, useEffect, useRef } from 'react';
import { mediaDevices } from 'react-native-webrtc';
import { Device } from 'mediasoup-client';

export default function useWebRTC(socketRef) {
  const [localStream, setLocalStream] = useState(null);
  const [remoteStream, setRemoteStream] = useState(null);
  const deviceRef = useRef(null);
  const sendTransportRef = useRef(null);
  const recvTransportRef = useRef(null);
  const producerRef = useRef(null);

  useEffect(() => {
    const setupMediasoup = async () => {
      try {
        // Solicitar permissões e obter stream local
        const stream = await mediaDevices.getUserMedia({ video: true, audio: true });
        setLocalStream(stream);
        console.log('Stream local obtido com sucesso:', stream);

        // Inicializar o dispositivo mediasoup
        const device = new Device();
        const routerRtpCapabilities = await new Promise(resolve =>
          socketRef.current.emit('routerRtpCapabilities', null, resolve)
        );
        console.log('Capacidades RTP do roteador:', routerRtpCapabilities);
        await device.load({ routerRtpCapabilities });
        deviceRef.current = device;
        console.log('Dispositivo mediasoup carregado com sucesso');

        // Criar transporte de envio
        const sendTransportData = await new Promise(resolve =>
          socketRef.current.emit('createTransport', { sender: true }, resolve)
        );
        console.log('Dados do transporte de envio:', sendTransportData);
        const sendTransport = device.createSendTransport(sendTransportData);
        sendTransportRef.current = sendTransport;

        sendTransport.on('connect', async ({ dtlsParameters }, callback) => {
          console.log('Conectando transporte de envio com DTLS:', dtlsParameters);
          await socketRef.current.emit('connectTransport', {
            transportId: sendTransportData.id,
            dtlsParameters,
          }, callback);
        });

        sendTransport.on('produce', async ({ kind, rtpParameters }, callback) => {
          console.log('Produzindo stream com parâmetros:', { kind, rtpParameters });
          const producer = await socketRef.current.emit('produce', {
            transportId: sendTransportData.id,
            kind,
            rtpParameters,
          }, callback);
          producerRef.current = producer;
          socketRef.current.emit('newProducer', { producerId: producer.id, kind });
          console.log('Produtor criado:', producer.id);
        });

        // Produzir stream local
        const videoTrack = stream.getVideoTracks()[0];
        const audioTrack = stream.getAudioTracks()[0];
        if (videoTrack && audioTrack) {
          await sendTransport.produce({ track: videoTrack });
          await sendTransport.produce({ track: audioTrack });
          console.log('Streams de vídeo e áudio produzidos');
        } else {
          console.error('Falha ao obter tracks de vídeo ou áudio');
        }
      } catch (error) {
        console.error('Erro ao configurar mediasoup:', error);
        if (error.name === 'UnsupportedError') {
          console.error('Detalhes do erro: O dispositivo não suporta mediasoup-client. Verifique WebRTC e codecs.');
        }
      }
    };

    setupMediasoup();

    socketRef.current.on('newProducer', async ({ producerId, kind }) => {
      if (deviceRef.current && kind === 'video' && !recvTransportRef.current) {
        try {
          const recvTransportData = await new Promise(resolve =>
            socketRef.current.emit('createTransport', { sender: false }, resolve)
          );
          const recvTransport = deviceRef.current.createRecvTransport(recvTransportData);
          recvTransportRef.current = recvTransport;

          recvTransport.on('connect', async ({ dtlsParameters }, callback) => {
            await socketRef.current.emit('connectTransport', {
              transportId: recvTransportData.id,
              dtlsParameters,
            }, callback);
          });

          const consumerData = await new Promise(resolve =>
            socketRef.current.emit('consume', {
              producerId,
              rtpCapabilities: deviceRef.current.rtpCapabilities,
            }, resolve)
          );
          const consumer = await recvTransport.consume(consumerData);
          const stream = new MediaStream([consumer.track]);
          setRemoteStream(stream);
          await consumer.resume();
          console.log('Consumidor criado para producerId:', producerId);
        } catch (error) {
          console.error('Erro ao consumir stream remoto:', error);
        }
      }
    });

    return () => {
      if (localStream) localStream.getTracks().forEach(track => track.stop());
      if (remoteStream) remoteStream.getTracks().forEach(track => track.stop());
      if (sendTransportRef.current) sendTransportRef.current.close();
      if (recvTransportRef.current) recvTransportRef.current.close();
    };
  }, [socketRef]);

  const cleanup = () => {
    if (localStream) localStream.getTracks().forEach(track => track.stop());
    if (remoteStream) remoteStream.getTracks().forEach(track => track.stop());
    if (sendTransportRef.current) sendTransportRef.current.close();
    if (recvTransportRef.current) recvTransportRef.current.close();
    setLocalStream(null);
    setRemoteStream(null);
  };

  return {
    localStream,
    remoteStream,
    cleanup,
  };
}