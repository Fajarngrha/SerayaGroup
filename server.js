const express = require('express');
const path = require('path');

const app = express();
const HOST = process.env.HOST || '127.0.0.1';
const PORT = process.env.PORT || 3000;
const isProd = process.env.NODE_ENV === 'production';

app.disable('x-powered-by');

app.use(express.static(path.join(__dirname), {
  maxAge: isProd ? '1d' : 0,
  etag: true
}));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'seraya-website' });
});

app.get('*', (req, res) => {
  const file = path.join(__dirname, req.path === '/' ? 'index.html' : req.path);
  res.sendFile(file, (err) => {
    if (err) res.status(404).sendFile(path.join(__dirname, 'index.html'));
  });
});

app.listen(PORT, HOST, () => {
  console.log(`Seraya website → http://${HOST}:${PORT}`);
  console.log(`Health check   → http://${HOST}:${PORT}/health`);
});
