import React, { useEffect, useState } from 'react';
import { Routes, Route } from 'react-router-dom';
import io from 'socket.io-client';
import * as mediasoupClient from 'mediasoup-client';
import Host from './components/Host';
import Client from './components/Client';

const socket = io('http://localhost:3001', {
  reconnection: true,
  reconnectionAttempts: 5,
  reconnectionDelay: 1000,
});

function App() {
  const [device, setDevice] = useState(null);

  useEffect(() => {
    const initializeDevice = async () => {
      try {
        const capabilities = await new Promise((resolve, reject) => {
          socket.on('routerRtpCapabilities', (data) => {
            console.log('routerRtpCapabilities recebido:', data);
            resolve(data);
          });
          socket.on('connect_error', (err) => {
            console.error('Erro de conexão detectado:', err.message);
            reject(new Error(`Erro de conexão: ${err.message}`));
          });
        });
        console.log('Recebido routerRtpCapabilities:', capabilities);
        const newDevice = new mediasoupClient.Device();
        await newDevice.load({ routerRtpCapabilities: capabilities });
        console.log('Dispositivo Mediasoup inicializado com sucesso');
        setDevice(newDevice);
      } catch (error) {
        console.error('Erro ao inicializar o dispositivo:', error);
      }
    };
    initializeDevice();

    socket.on('connect', () => console.log('Socket conectado com sucesso'));
    socket.on('connect_error', (err) => console.error('Erro de conexão no socket:', err.message));

    return () => {
      socket.off('routerRtpCapabilities');
      socket.off('connect');
      socket.off('connect_error');
    };
  }, []);

  return (
    <div style={{ height: '100vh', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', background: '#f5d9ff' }}>
      <h1 style={{ color: '#ff4d94' }}>Livestream MVP</h1>
      <Routes>
        <Route path="/host" element={<Host socket={socket} device={device} />} />
        <Route path="/client" element={<Client socket={socket} device={device} />} />
        <Route path="/" element={
          <div style={{ display: 'flex', gap: '20px' }}>
            <a href="/host" style={{ padding: '10px 20px', background: '#ff4d94', color: '#fff', borderRadius: '20px', textDecoration: 'none' }}>Host</a>
            <a href="/client" style={{ padding: '10px 20px', background: '#ff4d94', color: '#fff', borderRadius: '20px', textDecoration: 'none' }}>Client</a>
          </div>
        } />
      </Routes>
    </div>
  );
}

export default App;