import React from 'react';
import ReactDOM from 'react-dom/client'; // Importar de 'react-dom/client' no React 18
import { BrowserRouter } from 'react-router-dom';
import App from './App';

// Criar uma raiz para renderização
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <BrowserRouter>
    <App />
  </BrowserRouter>
);