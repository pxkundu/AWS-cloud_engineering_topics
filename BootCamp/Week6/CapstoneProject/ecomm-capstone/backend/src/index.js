const express = require('express');
const app = express();

app.get('/inventory', (req, res) => res.json({ products: 10000 }));
app.get('/orders', (req, res) => res.json({ orders: 0 }));
app.get('/health', (req, res) => res.status(200).send('OK'));
app.get('/ready', (req, res) => res.status(200).send('Ready'));

app.listen(80, () => console.log('Backend running on port 80'));
