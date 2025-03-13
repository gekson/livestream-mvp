import React, { useEffect, useRef, useState } from 'react';
import Chat from './Chat';
import '../styles/StreamLayout.css';

function Client({ socket, device }) {
  const [pendingProducers, setPendingProducers] = useState([]);
  const videoRef = useRef(null);
  const audioRef = useRef(null); // Novo ref para o elemento de áudio
  const recvTransportRef = useRef(null);
  const [videoConsumer, setVideoConsumer] = useState(null);
  const [audioConsumer, setAudioConsumer] = useState(null);

  const consumeProducer = async (producerId, recvTransport, isVideo) => {
    const consumerData = await new Promise(resolve => {
      socket.emit('consume', { producerId, rtpCapabilities: device.rtpCapabilities }, resolve);
    });
    console.log('Consumer Data recebido:', consumerData);

    const kind = consumerData.kind || (isVideo ? 'video' : 'audio');
    console.log(`Consuming ${kind} producer with ID: ${producerId}`);

    const consumer = await recvTransport.consume({
      id: consumerData.id,
      producerId: consumerData.producerId,
      kind: kind,
      rtpParameters: consumerData.rtpParameters
    });

    await consumer.resume();

    const stream = new MediaStream();
    stream.addTrack(consumer.track);

    if (kind === 'video') {
      videoRef.current.srcObject = stream;
      setVideoConsumer(consumer);
      videoRef.current.muted = true;
      videoRef.current.play().catch(err => {
        console.error('Erro ao reproduzir vídeo:', err);
        if (err.name === 'NotAllowedError') {
          console.log('Autoplay bloqueado. Aguardando interação do usuário para reproduzir.');
        }
      });
      console.log('Consumer configurado e vídeo deveria estar visível (muted)');
    } else if (kind === 'audio') {
      audioRef.current.srcObject = stream;
      setAudioConsumer(consumer);
      audioRef.current.muted = false; // Áudio começa desmutado, pode ser ajustado
      audioRef.current.play().catch(err => {
        console.error('Erro ao reproduzir áudio:', err);
        if (err.name === 'NotAllowedError') {
          console.log('Autoplay bloqueado. Aguardando interação do usuário para reproduzir.');
        }
      });
      console.log('Consumer configurado e áudio deveria estar visível');
    }
  };

  useEffect(() => {
    socket.on('existingProducers', (producers) => {
      console.log('Producers existentes recebidos:', producers);
      setPendingProducers(producers);
    });

    return () => {
      socket.off('existingProducers');
    };
  }, [socket]);

  useEffect(() => {
    if (!device) return;

    console.log('Iniciando lógica do client...');

    socket.on('newProducer', ({ producerId, kind }) => {
      console.log('Novo producer detectado:', producerId, 'kind:', kind);
      if (recvTransportRef.current) {
        consumeProducer(producerId, recvTransportRef.current, kind === 'video');
      } else {
        setPendingProducers(prev => [...prev, { producerId, kind }]);
      }
    });

    const setupConsumer = async () => {
      const transportData = await new Promise(resolve => {
        socket.emit('createTransport', { sender: false }, resolve);
      });
      console.log('Transport Data (Client) recebido:', transportData);

      console.log('DTLS Parameters recebidos:', transportData.dtlsParameters);

      const recvTransport = device.createRecvTransport({
        id: transportData.id,
        iceParameters: transportData.iceParameters,
        iceCandidates: transportData.iceCandidates,
        dtlsParameters: transportData.dtlsParameters,
        initialAvailableOutgoingBitrate: 1000000
      });
      recvTransport.on('connect', ({ dtlsParameters }, callback) => {
        console.log('Conectando transporte com DTLS:', dtlsParameters);
        socket.emit('connectTransport', {
          transportId: transportData.id,
          dtlsParameters
        }, callback);
      });
      recvTransport.on('connectionstatechange', (state) => {
        console.log('Estado da conexão do transporte:', state);
      });
      recvTransportRef.current = recvTransport;

      if (pendingProducers.length > 0) {
        for (const producer of pendingProducers) {
          console.log('Consumindo producer pendente:', producer.producerId);
          // Usar o producer atual para determinar o tipo (melhorar lógica se possível)
          const isVideo = !pendingProducers.some(p => p.producerId === producer.producerId && p.producerId.startsWith('video')); // Corrigido aqui
          consumeProducer(producer.producerId, recvTransport, isVideo);
        }
        setPendingProducers([]);
      }
    };

    setupConsumer();

    return () => {
      socket.off('newProducer');
    };
  }, [device, socket]);

  const unmuteVideo = () => {
    if (videoRef.current) {
      videoRef.current.muted = false;
      videoRef.current.play().catch(err => console.error('Erro ao reproduzir com som:', err));
      console.log('Som de vídeo ativado');
    }
  };

  return (
    <div className="stream-container">
      <div className="stream-wrapper">
        <div className="video-section">
          <video ref={videoRef} autoPlay className="stream-video" />
          <div className="control-buttons">
            <button onClick={unmuteVideo} className="control-button">Ativar Som de Vídeo</button>
          </div>
        </div>
        <div className="chat-section">
          <Chat socket={socket} />
        </div>
      </div>
      <audio ref={audioRef} autoPlay style={{ display: 'none' }} /> {/* Elemento de áudio oculto */}
    </div>
  );
}

export default Client;