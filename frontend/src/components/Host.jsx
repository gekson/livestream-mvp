import React, { useEffect, useRef, useState } from 'react';
import Chat from './Chat';
import '../styles/StreamLayout.css';

function Host({ socket, device }) {
  const videoRef = useRef();
  const streamRef = useRef(null);
  const [isLive, setIsLive] = useState(false);

  const startHost = async () => {
    if (!device) {
      console.error('Aguardando inicialização do dispositivo...');
      return;
    }

    const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
    videoRef.current.srcObject = stream;
    streamRef.current = stream;

    const transportData = await new Promise(resolve => {
      socket.emit('createTransport', { sender: true }, resolve);
    });
    console.log('Transport Data (Host):', transportData);

    const sendTransport = device.createSendTransport(transportData);
    sendTransport.on('connect', ({ dtlsParameters }, callback) => {
      socket.emit('connectTransport', { transportId: transportData.id, dtlsParameters }, callback);
    });
    sendTransport.on('produce', ({ kind, rtpParameters }, callback) => {
      socket.emit('produce', { transportId: transportData.id, kind, rtpParameters }, callback);
    });

    // Adicionar videoTrack
    const videoTrack = stream.getVideoTracks()[0];
    const videoProducer = await sendTransport.produce({ track: videoTrack, encodings: [{ maxBitrate: 1000000 }], appData: { mediaType: 'video' } });
    console.log('Video producer criado com sucesso:', videoProducer.id);

    // Adicionar audioTrack
    const audioTrack = stream.getAudioTracks()[0];
    const audioProducer = await sendTransport.produce({ track: audioTrack, encodings: [], appData: { mediaType: 'audio' } });
    console.log('Audio producer criado com sucesso:', audioProducer.id);

    setIsLive(true);
  };

  const stopHost = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      videoRef.current.srcObject = null;
      streamRef.current = null;
      setIsLive(false);
      console.log('Live parada com sucesso');
    }
  };

  return (
    <div className="stream-container">
      <div className="stream-wrapper">
        <div className="video-section">
          {isLive && <div className="live-label">LIVE</div>}
          <video ref={videoRef} autoPlay muted className="stream-video" />
          <div className="control-buttons">
            <button onClick={startHost} disabled={!device || isLive} className="control-button">
              Iniciar Live
            </button>
            <button onClick={stopHost} disabled={!isLive} className="control-button">
              Parar Live
            </button>
          </div>
        </div>
        <div className="chat-section">
          <Chat socket={socket} />
        </div>
      </div>
    </div>
  );
}

export default Host;