// src/api/socket.js
import io from 'socket.io-client';

export const setupSocket = (url) => {
  const socket = io(url, {
    transports: ['websocket'],
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionAttempts: 10,
  });
  
  return socket;
};