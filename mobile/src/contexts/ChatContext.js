import React, { createContext, useReducer, useContext, useRef, useEffect } from 'react';
import io from 'socket.io-client';

const ChatContext = createContext();

const initialState = {
  messages: [],
  users: [],
  isConnected: false,
  currentRoom: null,
  isHost: false,
};

function chatReducer(state, action) {
  switch (action.type) {
    case 'CONNECT_SOCKET':
      return { ...state, isConnected: true };
    case 'DISCONNECT_SOCKET':
      return { ...state, isConnected: false };
    case 'SET_ROOM':
      return { ...state, currentRoom: action.payload, isHost: action.isHost };
    case 'ADD_MESSAGE':
      if (!action.payload || typeof action.payload !== 'object') {
        console.warn('Tentativa de adicionar mensagem inválida:', action.payload);
        return state;
      }
      console.log('Adicionando mensagem ao estado:', JSON.stringify(action.payload));
      return { ...state, messages: [...state.messages, action.payload] };
    case 'SET_USERS':
      return { ...state, users: action.payload };
    default:
      return state;
  }
}

export function ChatProvider({ children }) {
  const [state, dispatch] = useReducer(chatReducer, initialState);
  const socketRef = useRef(null);

  useEffect(() => {
    return () => {
      if (socketRef.current) {
        socketRef.current.disconnect();
      }
    };
  }, []);

  const connectToServer = (serverUrl) => {
    socketRef.current = io(serverUrl, {
      transports: ['polling'], // Usar polling por enquanto
      forceNew: true,
      reconnectionAttempts: 10,
      timeout: 10000,
      jsonp: false,
    });

    socketRef.current.on('connect', () => {
      console.log('Socket conectado!', socketRef.current.id);
      dispatch({ type: 'CONNECT_SOCKET' });
    });

    socketRef.current.on('connect_error', (error) => {
      console.error('Erro de conexão:', error.message);
    });

    socketRef.current.on('disconnect', () => {
      console.log('Socket desconectado');
      dispatch({ type: 'DISCONNECT_SOCKET' });
    });

    socketRef.current.on('message', (message) => {
      console.log('Mensagem recebida (crua):', JSON.stringify(message));
      // Garantir formato consistente
      const formattedMessage = {
        sender: message.sender || 'unknown',
        text: message.text || String(message),
        timestamp: message.timestamp || new Date().toISOString(),
        roomId: message.roomId || state.currentRoom,
      };
      console.log('Mensagem formatada:', JSON.stringify(formattedMessage));
      dispatch({ type: 'ADD_MESSAGE', payload: formattedMessage });
    });

    socketRef.current.on('users', (users) => {
      console.log('Usuários recebidos:', users);
      dispatch({ type: 'SET_USERS', payload: users });
    });
  };

  const joinRoom = (roomId, username, isHost = false) => {
    console.log('Tentando entrar na sala:', roomId, 'como:', username, 'Host?', isHost);
    console.log('Socket está conectado?', socketRef.current?.connected);

    if (socketRef.current) {
      socketRef.current.emit('join-room', { roomId, username });
      console.log('Evento join-room emitido');
      dispatch({ type: 'SET_ROOM', payload: roomId, isHost });
    } else {
      console.error('Socket não inicializado ao tentar entrar na sala');
    }
  };

  const sendMessage = (text) => {
    if (socketRef.current && state.currentRoom) {
      const message = {
        text: String(text),
        sender: socketRef.current.id, // Usar ID do socket como remetente
        timestamp: new Date().toISOString(),
        roomId: state.currentRoom,
      };
      console.log('Enviando mensagem:', JSON.stringify(message));
      socketRef.current.emit('message', message);
      dispatch({ type: 'ADD_MESSAGE', payload: message });
    } else {
      console.warn('Não foi possível enviar mensagem: socket ou sala não definidos');
    }
  };

  const value = {
    state,
    socketRef,
    connectToServer,
    joinRoom,
    sendMessage,
  };

  return <ChatContext.Provider value={value}>{children}</ChatContext.Provider>;
}

export const useChat = () => useContext(ChatContext);