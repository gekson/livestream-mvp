const express = require('express');
const path = require('path');
const app = express();

// Servir os arquivos estáticos da pasta build
app.use(express.static(path.join(__dirname, 'build')));

// Redirecionar todas as rotas para index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

// Usar a porta fornecida pelo Render
const port = process.env.PORT || 3000; // Fallback para teste local
app.listen(port, () => {
  console.log(`Frontend rodando na porta ${port}`);
});