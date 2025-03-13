const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mediasoup = require('mediasoup');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: 'http://localhost:3000' }
});

let worker, router;
const transports = new Map();
const producers = new Map(); // Rastrear producers ativos

(async () => {
  worker = await mediasoup.createWorker();
  router = await worker.createRouter({
    mediaCodecs: [
      {
        kind: 'video',
        mimeType: 'video/VP8',
        clockRate: 90000
      },
      {
        kind: 'audio',
        mimeType: 'audio/opus',
        clockRate: 48000,
        channels: 2
      }
    ]
  });
})();

io.on('connection', (socket) => {
  console.log('Usuário conectado:', socket.id);

  // Enviar capacidades RTP
  socket.emit('routerRtpCapabilities', router.rtpCapabilities);

  // Enviar lista de producers existentes para o novo cliente
  const existingProducers = Array.from(producers.keys()).map(producerId => ({ producerId }));
  socket.emit('existingProducers', existingProducers);
  console.log('Enviando producers existentes:', existingProducers);

  socket.on('message', (msg) => {
    io.emit('message', { id: socket.id, text: msg });
  });

  socket.on('createTransport', async ({ sender }, callback) => {
    const transport = await router.createWebRtcTransport({
      listenIps: [{ ip: '0.0.0.0', announcedIp: '127.0.0.1' }],
      enableUdp: true,
      enableTcp: true
    });
    transports.set(transport.id, transport);
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
    producers.set(producer.id, producer); // Adicionar à lista de producers
    io.emit('newProducer', { producerId: producer.id }); // Notificar todos os clientes
    callback({ id: producer.id });
  });

  socket.on('consume', async ({ producerId, rtpCapabilities }, callback) => {
    const transport = transports.get(socket.consumerTransportId);
    if (!transport) {
      console.error(`Transporte de consumo não encontrado para socket ${socket.id}`);
      return callback({ error: 'Transporte não encontrado' });
    }
    const consumer = await transport.consume({
      producerId,
      rtpCapabilities
    });
    callback({
      id: consumer.id,
      producerId,
      rtpParameters: consumer.rtpParameters,
      transportId: transport.id,
      iceParameters: transport.iceParameters,
      iceCandidates: transport.iceCandidates,
      dtlsParameters: transport.dtlsParameters
    });
  });

  socket.on('disconnect', () => {
    console.log('Usuário desconectado:', socket.id);
    if (socket.transportId) transports.delete(socket.transportId);
    if (socket.consumerTransportId) transports.delete(socket.consumerTransportId);
    if (socket.producer) {
      producers.delete(socket.producer.id); // Remover producer ao desconectar
    }
  });
});

server.listen(3001, () => console.log('Servidor rodando na porta 3001'));