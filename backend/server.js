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

let worker;
let router;
const transports = new Map();
const producers = new Map();
const consumers = new Map();

async function startServer() {
  // Configuração do Worker com iceLite: false
  worker = await mediasoup.createWorker({
    logLevel: 'debug', // Para mais logs
    rtcMinPort: 10000,
    rtcMaxPort: 59999,
    iceLite: false // Desativar iceLite no Worker
  });

  worker.on('died', () => {
    console.error('Worker morreu, saindo em 2 segundos...');
    setTimeout(() => process.exit(1), 2000);
  });

  // Criar um Router
  router = await worker.createRouter({
    mediaCodecs: [
      { kind: 'audio', mimeType: 'audio/opus', clockRate: 48000, channels: 2 },
      { kind: 'video', mimeType: 'video/VP8', clockRate: 90000 },
      { kind: 'video', mimeType: 'video/VP9', clockRate: 90000 },
      { kind: 'video', mimeType: 'video/H264', clockRate: 90000 },
    ]
  });

  console.log('Router criado com sucesso');
}

startServer().catch(console.error);

// Gerenciar conexões de socket
io.on('connection', (socket) => {
  console.log(`Usuário conectado: ${socket.id}`);
  socket.emit('routerRtpCapabilities', router.rtpCapabilities);

  // Enviar producers existentes ao conectar
  socket.emit('existingProducers', Array.from(producers.entries(), ([id, { kind }]) => ({ producerId: id, kind })));

  socket.on('createTransport', async ({ sender }, callback) => {
    const transport = await router.createWebRtcTransport({
      listenIps: [{ ip: '0.0.0.0', announcedIp: null }],
      enableUdp: true,
      enableTcp: true,
      preferUdp: true,
      iceLite: false, // Redundante, mas reforça
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

    transport.on('icestatechange', (state) => {
      console.log('Estado ICE no servidor:', state);
    });

    transport.on('dtlsstatechange', (state) => {
      console.log('Estado DTLS no servidor:', state);
    });

    transport.on('icecandidate', (candidate) => {
      console.log('Novo candidato ICE no servidor:', candidate);
    });

    transport.on('dtlsstatechange', (state) => {
      if (state === 'closed') {
        transport.close();
      }
    });

    transports.set(socket.id, transport);

    callback({
      id: transport.id,
      iceParameters: transport.iceParameters,
      iceCandidates: transport.iceCandidates,
      dtlsParameters: transport.dtlsParameters
    });

    transport.on('close', () => {
      console.log('Transport fechado para socket:', socket.id);
      transports.delete(socket.id);
    });
  });

  socket.on('connectTransport', async ({ transportId, dtlsParameters }, callback) => {
    const transport = transports.get(socket.id);
    if (!transport) return callback('Transporto não encontrado');

    await transport.connect({ dtlsParameters });
    callback();
  });

  socket.on('produce', async ({ kind, rtpParameters }, callback) => {
    const transport = transports.get(socket.id);
    if (!transport) return callback('Transporto não encontrado');

    const producer = await transport.produce({
      kind,
      rtpParameters,
    });

    producers.set(producer.id, { socketId: socket.id, kind });
    console.log(`Novo producer criado: ${producer.id} (kind: ${kind})`);

    producer.on('transportclose', () => {
      console.log(`Producer ${producer.id} fechado`);
      producers.delete(producer.id);
    });

    producer.on('close', () => {
      console.log(`Producer ${producer.id} fechado por close`);
      producers.delete(producer.id);
    });

    // Notificar outros clientes sobre o novo producer
    socket.broadcast.emit('newProducer', { producerId: producer.id, kind });

    callback({ id: producer.id });
  });

  socket.on('consume', async ({ producerId, rtpCapabilities }, callback) => {
    const transport = transports.get(socket.id);
    if (!transport) return callback('Transporto não encontrado');

    const producer = Array.from(producers.values()).find(p => p.socketId !== socket.id && p.producerId === producerId);
    if (!producer) return callback('Producer não encontrado');

    const consumer = await transport.consume({
      producerId,
      rtpCapabilities,
      paused: false,
    });

    consumers.set(consumer.id, { socketId: socket.id, producerId });
    console.log(`Novo consumer criado: ${consumer.id} para producer ${producerId}`);

    consumer.on('transportclose', () => {
      console.log(`Consumer ${consumer.id} fechado`);
      consumers.delete(consumer.id);
    });

    consumer.on('producerclose', () => {
      console.log(`Consumer ${consumer.id} fechado por producerclose`);
      consumers.delete(consumer.id);
    });

    await consumer.resume();

    callback({
      id: consumer.id,
      producerId,
      kind: consumer.kind,
      rtpParameters: consumer.rtpParameters,
      type: consumer.type
    });
  });

  socket.on('disconnect', () => {
    console.log(`Usuário desconectado: ${socket.id}`);
    const transport = transports.get(socket.id);
    if (transport) {
      transport.close();
      transports.delete(socket.id);
    }

    // Fechar producers e consumers associados
    for (const [id, producer] of producers) {
      if (producer.socketId === socket.id) {
        producer.close();
        producers.delete(id);
      }
    }
    for (const [id, consumer] of consumers) {
      if (consumer.socketId === socket.id) {
        consumer.close();
        consumers.delete(id);
      }
    }
    socket.broadcast.emit('existingProducers', Array.from(producers.entries(), ([id, { kind }]) => ({ producerId: id, kind })));
  });
});

// Configurar o servidor para ouvir na porta fornecida pelo Render
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

module.exports = server;