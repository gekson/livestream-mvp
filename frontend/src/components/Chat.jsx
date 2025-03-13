import React, { useState, useEffect } from 'react';

function Chat({ socket }) {
  const [messages, setMessages] = useState([]);
  const [message, setMessage] = useState('');

  useEffect(() => {
    socket.on('message', (msg) => {
      setMessages((prev) => [...prev, msg]);
    });

    return () => {
      socket.off('message');
    };
  }, [socket]);

  const sendMessage = () => {
    if (message.trim()) {
      socket.emit('message', message);
      setMessage('');
    }
  };

  const handleKeyPress = (event) => {
    if (event.key === 'Enter' && message.trim()) {
      sendMessage();
    }
  };

  return (
    <>
      <h3>Chat</h3>
      <div className="chat-messages">
        {messages.map((msg, i) => (
          <p key={i}>{msg.id}: {msg.text}</p>
        ))}
      </div>
      <div className="chat-input">
        <input
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          onKeyPress={handleKeyPress} // Adiciona o evento de tecla
          placeholder="Digite uma mensagem"
        />
        <button onClick={sendMessage}>Enviar</button>
      </div>
    </>
  );
}

export default Chat;