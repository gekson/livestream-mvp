const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mediasoup = require('mediasoup');

// Define variables at the top level before using them
let worker, router;
const transports = new Map();
const producers = new Map();
const consumers = new Map();
// Keep track of rooms and users
const rooms = new Map();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: '*', // Allow all origins for testing
    methods: ['GET', 'POST'],
    credentials: true,
  },
  pingTimeout: 60000, // Increase ping timeout to 60 seconds
  pingInterval: 10000, // Send ping every 10 seconds
  transports: ['polling', 'websocket'], // Support both transport methods
  allowEIO3: true, // Allow Engine.IO 3 compatibility
});

// Add a simple health check endpoint
app.get('/health', (req, res) => {
  console.log('Health check requested from:', req.ip);
  res.status(200).send('Server is running');
});

// Add a socket.io specific health check
app.get('/socket-health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    connections: io.engine.clientsCount,
    rooms: Array.from(rooms.keys())
  });
});

// Add more detailed logging for socket.io
io.engine.on('connection', (socket) => {
  console.log('Transport connection attempt:', socket.remoteAddress);
});

// Initialize MediaSoup worker and router
async function initializeMediasoup() {
  try {
    worker = await mediasoup.createWorker({
      logLevel: 'warn',
      rtcMinPort: 10000,
      rtcMaxPort: 10100,
    });
    
    console.log('MediaSoup worker created');
    
    // Create router
    router = await worker.createRouter({
      mediaCodecs: [
        {
          kind: 'audio',
          mimeType: 'audio/opus',
          clockRate: 48000,
          channels: 2,
        },
        {
          kind: 'video',
          mimeType: 'video/VP8',
          clockRate: 90000,
          parameters: {
            'x-google-start-bitrate': 1000,
          },
        },
      ],
    });
    
    console.log('MediaSoup router created');
    
    return true;
  } catch (error) {
    console.error('Failed to initialize MediaSoup:', error);
    return false;
  }
}

// Initialize MediaSoup before setting up socket events
initializeMediasoup().then((success) => {
  if (!success) {
    console.error('MediaSoup initialization failed, some features may not work');
  }
});

// Then in your connection handler, check if router exists before using it
io.on('connection', (socket) => {
  console.log('Usuário conectado:', socket.id, 'from', socket.handshake.address, 'via', socket.conn.transport.name);

  // Send immediate acknowledgment to client
  socket.emit('connection-ack', { id: socket.id, status: 'connected' });

  // Only emit MediaSoup capabilities if router is initialized
  if (router) {
    socket.emit('routerRtpCapabilities', router.rtpCapabilities);
    
    const existingProducers = Array.from(producers.keys()).map((producerId) => ({ producerId }));
    console.log('Enviando producers existentes para', socket.id, ':', existingProducers);
    socket.emit('existingProducers', existingProducers);
  } else {
    console.warn('Router not initialized, skipping MediaSoup events for socket', socket.id);
  }

  // Handle join room with better error handling
  socket.on('join-room', ({ roomId, username }) => {
    try {
      socket.join(roomId);
      socket.username = username || `User_${socket.id.substring(0, 5)}`;
      socket.currentRoom = roomId;
      
      console.log(`${socket.username} entrou na sala ${roomId}`);
      
      // Update room tracking
      if (!rooms.has(roomId)) {
        rooms.set(roomId, new Set());
      }
      rooms.get(roomId).add(socket.id);
      
      // Notify everyone in the room about the new user
      socket.to(roomId).emit('user-joined', {
        id: socket.id,
        username: socket.username
      });
      
      // Send updated user list to everyone in the room
      const users = Array.from(io.sockets.adapter.rooms.get(roomId) || [])
        .map((id) => ({
          id,
          username: io.sockets.sockets.get(id)?.username || `User_${id.substring(0, 5)}`,
          isHost: rooms.get(roomId).values().next().value === id, // First user is host
        }));
      
      io.to(roomId).emit('room-users', users);
      
      // Acknowledge successful join
      socket.emit('join-success', { roomId, users });
    } catch (error) {
      console.error('Error in join-room:', error);
      socket.emit('error', { message: 'Failed to join room', details: error.message });
    }
  });

  // Improved message handling
  socket.on('message', (msg) => {
    try {
      console.log('Mensagem recebida de', socket.id, ':', msg);
      
      // Ensure message has the correct format
      const formattedMessage = {
        id: Date.now().toString(), // Add a unique ID
        sender: socket.username || socket.id,
        senderId: socket.id,
        text: typeof msg === 'object' ? msg.text : String(msg),
        timestamp: typeof msg === 'object' && msg.timestamp ? msg.timestamp : new Date().toISOString(),
        roomId: typeof msg === 'object' && msg.roomId ? msg.roomId : socket.currentRoom,
      };
      
      console.log('Mensagem formatada para envio:', formattedMessage);
      
      // Send to everyone in the room including sender (for consistency)
      io.to(formattedMessage.roomId || '').emit('message', formattedMessage);
    } catch (error) {
      console.error('Error in message handling:', error);
    }
  });

  // Rest of your socket handlers...

  socket.on('disconnect', () => {
    console.log('Usuário desconectado:', socket.id);
    
    // Clean up room membership
    if (socket.currentRoom && rooms.has(socket.currentRoom)) {
      const room = rooms.get(socket.currentRoom);
      room.delete(socket.id);
      
      // Notify others in the room
      socket.to(socket.currentRoom).emit('user-left', {
        id: socket.id,
        username: socket.username || socket.id
      });
      
      // Update user list
      if (room.size > 0) {
        const users = Array.from(room).map((id) => ({
          id,
          username: io.sockets.sockets.get(id)?.username || `User_${id.substring(0, 5)}`,
          isHost: room.values().next().value === id, // First remaining user is host
        }));
        
        io.to(socket.currentRoom).emit('room-users', users);
      } else {
        // Remove empty room
        rooms.delete(socket.currentRoom);
      }
    }
    
    // Clean up transports and producers
    if (socket.transportId) transports.delete(socket.transportId);
    if (socket.consumerTransportId) transports.delete(socket.consumerTransportId);
    if (socket.producer) {
      producers.delete(socket.producer.id);
      // Notify others about producer removal
      io.emit('producerClosed', { producerId: socket.producer.id });
    }
  });
});

server.listen(process.env.PORT || 3001, '0.0.0.0', () => console.log('Servidor rodando na porta 3001'));

// Add a socket.io specific debug endpoint
// Fix the socket-debug endpoint to handle undefined rooms
app.get('/socket-debug', (req, res) => {
  res.status(200).json({
    status: 'ok',
    socketInitialized: io !== undefined,
    connections: io.engine?.clientsCount || 0,
    rooms: rooms ? Array.from(rooms.keys()) : [],
    transports: io._transports || []
  });
});