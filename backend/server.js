const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mediasoup = require('mediasoup');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { 
    origin: ['http://localhost:3000', process.env.FRONTEND_URL],
    methods: ['GET', 'POST'],
    credentials: true
  }
});

let worker, router;
const transports = new Map();
const producers = new Map();
const consumers = new Map(); // Inicializar consumers como Map

(async () => {
  worker = await mediasoup.createWorker();
  router = await worker.createRouter({
    mediaCodecs: [
      { kind: 'video', mimeType: 'video/VP8', clockRate: 90000 },
      { kind: 'audio', mimeType: 'audio/opus', clockRate: 48000, channels: 2 }
    ]
  });
})();

io.on('connection', (socket) => {
  console.log('Usuário conectado:', socket.id);

  socket.emit('routerRtpCapabilities', router.rtpCapabilities);

  const existingProducers = Array.from(producers.keys()).map(producerId => ({ producerId }));
  console.log('Enviando producers existentes para', socket.id, ':', existingProducers);
  socket.emit('existingProducers', existingProducers);

  socket.on('message', (msg) => {
    io.emit('message', { id: socket.id, text: msg });
  });

  socket.on('createTransport', async ({ sender }, callback) => {
    const transport = await router.createWebRtcTransport({
      listenIps: [{ ip: '0.0.0.0', announcedIp: null }], // Render gerencia o IP
      enableUdp: true,
      enableTcp: true,
      preferUdp: true,
      initialAvailableOutgoingBitrate: 1000000,
      iceServers: [
        { urls: 'stun:stun.relay.metered.ca:80' },
        {
          urls: 'turn:global.relay.metered.ca:443',
          username: '97776f89a5a01cd7ff7a328e',
          credential: 'JuVcNUrd1Kh8/TxM',
        },
      ],
    });
    console.log('Transport criado. ICE Candidates:', transport.iceCandidates);
    console.log('ICE Parameters:', transport.iceParameters);
    transports.set(transport.id, transport);
    console.log('Transport criado com DTLS Parameters:', transport.dtlsParameters);
    callback({
      id: transport.id,
      iceParameters: transport.iceParameters,
      iceCandidates: transport.iceCandidates,
      dtlsParameters: transport.dtlsParameters
    });

    if (sender) {
      socket.transportId = transport.id;
    } else {
      socket.consumerTransportId = transport.id;
    }
  });

  socket.on('connectTransport', async ({ transportId, dtlsParameters }, callback) => {
    const transport = transports.get(transportId);
    if (!transport) {
      console.error(`Transporte não encontrado para ID: ${transportId}`);
      return callback ? callback({ error: 'Transporte não encontrado' }) : null;
    }
    await transport.connect({ dtlsParameters });
    if (callback) callback();
  });

  socket.on('produce', async ({ transportId, kind, rtpParameters }, callback) => {
    console.log('Recebido rtpParameters:', rtpParameters);
    const transport = transports.get(transportId);
    if (!transport) {
      console.error(`Transporte não encontrado para produce, ID: ${transportId}`);
      return callback({ error: 'Transporte não encontrado' });
    }
    const producer = await transport.produce({ kind, rtpParameters });
    socket.producer = producer;
    producers.set(producer.id, producer);
    io.emit('newProducer', { producerId: producer.id, kind: producer.kind });
    callback({ id: producer.id });
  });

  socket.on('consume', async ({ producerId, rtpCapabilities }, callback) => {
    const transport = transports.get(socket.consumerTransportId);
    if (!transport) {
      console.error(`Transporte de consumo não encontrado para socket ${socket.id}`);
      return callback({ error: 'Transporte não encontrado' });
    }
    const producer = producers.get(producerId);
    if (!producer) {
      console.error(`Producer não encontrado para ID: ${producerId}`);
      return callback({ error: 'Producer não encontrado' });
    }
    const consumer = await transport.consume({
      producerId,
      rtpCapabilities,
      paused: true
    });
    consumers.set(consumer.id, consumer); // Agora consumers está definido
    callback({
      id: consumer.id,
      producerId: consumer.producerId,
      kind: producer.kind,
      rtpParameters: consumer.rtpParameters,
      type: consumer.type,
      transportId: transport.id,
      iceParameters: transport.iceParameters,
      iceCandidates: transport.iceCandidates,
      dtlsParameters: transport.dtlsParameters
    });
    await consumer.resume();
  });

  socket.on('disconnect', () => {
    console.log('Usuário desconectado:', socket.id);
    if (socket.transportId) transports.delete(socket.transportId);
    if (socket.consumerTransportId) transports.delete(socket.consumerTransportId);
    if (socket.producer) {
      producers.delete(socket.producer.id);
    }
  });
});

server.listen(process.env.PORT ||3001, '0.0.0.0', () => console.log('Servidor rodando na porta 3001'));