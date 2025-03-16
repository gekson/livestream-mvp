// src/screens/ChatScreen.js
import React, { useState, useRef } from 'react';
import { View, StyleSheet, FlatList, KeyboardAvoidingView, Platform } from 'react-native';
import { Text, TextInput, Button, Avatar, FAB } from 'react-native-paper';
import { useChat } from '../contexts/ChatContext';

// Corrigindo o componente ChatMessage em src/screens/ChatScreen.js
const ChatMessage = ({ message, isOwn }) => {
  // Certifique-se de que o message é um objeto e tem as propriedades necessárias
  if (!message || typeof message !== 'object') {
    console.warn('Message inválida recebida:', message);
    return null;
  }

  // Verifique se message.sender existe antes de tentar usar substring
  const senderInitials = message.sender && typeof message.sender === 'string' 
    ? message.sender.substring(0, 2).toUpperCase() 
    : "?";

  // Garanta que as propriedades são strings antes de renderizar
  const messageText = message.text ? String(message.text) : '';
  const timestamp = message.timestamp ? new Date(message.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '';

  return (
    <View style={[styles.messageContainer, isOwn ? styles.ownMessage : styles.otherMessage]}>
      {!isOwn && <Avatar.Text size={32} label={senderInitials} style={styles.avatar} />}
      <View style={[styles.messageBubble, isOwn ? styles.ownBubble : styles.otherBubble]}>
        <Text style={styles.messageText}>{messageText.text}</Text>
        <Text style={styles.timestamp}>{timestamp.text}</Text>
      </View>
    </View>
  );
};

const ChatScreen = ({ navigation }) => {
  const { state, sendMessage, socketRef } = useChat();
  const [inputText, setInputText] = useState('');
  const flatListRef = useRef(null);

  const handleSend = () => {
    if (inputText.trim()) {
      sendMessage(inputText);
      setInputText('');
    }
  };

  const startVideoCall = () => {
    if (state.isHost) {
      navigation.navigate('VideoCall');
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : null}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 90 : 0}
    >
      <FlatList
        ref={flatListRef}
        data={state.messages}
        keyExtractor={(item, index) => index.toString()}
        renderItem={({ item }) => {
          // Adicione log para debug
          console.log('Renderizando mensagem:', JSON.stringify(item));
          
          return (
            <ChatMessage 
              message={item} 
              isOwn={item.sender === (socketRef.current?.id || 'me')} 
            />
          );
        }}
        onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
        style={styles.messagesList}
      />
      
      <View style={styles.inputContainer}>
        <TextInput
          value={inputText}
          onChangeText={setInputText}
          placeholder="Digite sua mensagem..."
          style={styles.input}
          multiline
        />
        // src/screens/ChatScreen.js (continuação)
        <Button
          mode="contained"
          onPress={handleSend}
          style={styles.sendButton}
          disabled={!inputText.trim()}
        >
          Enviar
        </Button>
      </View>
      
      {state.isHost && (
        <FAB
          icon="video"
          style={styles.fab}
          onPress={startVideoCall}
          label="Iniciar Videochamada"
        />
      )}
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  messagesList: {
    flex: 1,
    padding: 10,
  },
  messageContainer: {
    flexDirection: 'row',
    marginVertical: 5,
    maxWidth: '80%',
  },
  ownMessage: {
    alignSelf: 'flex-end',
  },
  otherMessage: {
    alignSelf: 'flex-start',
  },
  avatar: {
    marginRight: 8,
    alignSelf: 'flex-end',
    backgroundColor: '#3498db',
  },
  messageBubble: {
    padding: 10,
    borderRadius: 15,
  },
  ownBubble: {
    backgroundColor: '#2196F3',
  },
  otherBubble: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E0E0E0',
  },
  messageText: {
    fontSize: 16,
    color: '#333',
  },
  timestamp: {
    fontSize: 12,
    color: '#999',
    alignSelf: 'flex-end',
    marginTop: 2,
  },
  inputContainer: {
    flexDirection: 'row',
    padding: 10,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  input: {
    flex: 1,
    marginRight: 10,
    backgroundColor: '#fff',
  },
  sendButton: {
    justifyContent: 'center',
  },
  fab: {
    position: 'absolute',
    right: 16,
    top: 16,
    backgroundColor: '#2196F3',
  },
});

export default ChatScreen;