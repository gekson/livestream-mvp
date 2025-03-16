// src/screens/LoginScreen.js
import React, { useState, useEffect } from 'react';
import { View, StyleSheet, KeyboardAvoidingView, Platform } from 'react-native';
import { Text, TextInput, Button, Switch, Headline, RadioButton } from 'react-native-paper';
import { useChat } from '../contexts/ChatContext';

const LoginScreen = ({ navigation }) => {
  const { connectToServer, joinRoom } = useChat();
  const [username, setUsername] = useState('');
  const [roomId, setRoomId] = useState('');
  const [serverUrl, setServerUrl] = useState('http://192.168.0.37:3001'); // Mudar para seu IP ou URL
  const [isHost, setIsHost] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    // Conectar ao servidor quando o componente montar
    console.log('Tentando conectar ao servidor:', serverUrl);
    connectToServer(serverUrl);
  }, [serverUrl]);

  const handleJoin = () => {
    if (username.trim() && roomId.trim()) {
      setIsLoading(true);
      joinRoom(roomId, username, isHost);
      
      // Navegar para a tela de chat após um breve delay para permitir que a conexão seja estabelecida
      setTimeout(() => {
        navigation.navigate('Chat');
        setIsLoading(false);
      }, 1000);
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={styles.container}
    >
      <View style={styles.formContainer}>
        <Headline style={styles.headline}>LiveChat App</Headline>
        
        <TextInput
          label="Nome de usuário"
          value={username}
          onChangeText={setUsername}
          style={styles.input}
        />
        
        <TextInput
          label="ID da Sala"
          value={roomId}
          onChangeText={setRoomId}
          style={styles.input}
        />
        
        <TextInput
          label="URL do Servidor"
          value={serverUrl}
          onChangeText={setServerUrl}
          style={styles.input}
        />
        
        <View style={styles.switchContainer}>
          <Text>Entrar como Host?</Text>
          <Switch
            value={isHost}
            onValueChange={setIsHost}
          />
        </View>
        
        <Button
          mode="contained"
          onPress={handleJoin}
          loading={isLoading}
          disabled={!username.trim() || !roomId.trim() || isLoading}
          style={styles.button}
        >
          {isHost ? 'Criar Sala' : 'Entrar na Sala'}
        </Button>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  formContainer: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
  },
  headline: {
    textAlign: 'center',
    marginBottom: 30,
    fontSize: 26,
  },
  input: {
    marginBottom: 15,
  },
  switchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  button: {
    padding: 8,
  },
});

export default LoginScreen;