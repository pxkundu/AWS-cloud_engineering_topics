const express = require('express');
const AWSXRay = require('aws-xray-sdk');
const AWS = AWSXRay.captureAWS(require('aws-sdk'));
const app = express();
const cloudwatch = new AWS.CloudWatch();

AWSXRay.captureHTTPsGlobal(require('http'));
app.use(AWSXRay.express.openSegment('EcommBackend'));

app.get('/inventory', (req, res) => res.json({ products: 10000 }));
app.get('/orders', (req, res) => {
  cloudwatch.putMetricData({
    MetricData: [{ MetricName: 'OrdersPerMinute', Value: 1, Unit: 'Count' }],
    Namespace: 'EcommMetrics'
  }).promise();
  res.json({ orders: 0 });
});
app.get('/health', (req, res) => res.status(200).send('OK'));
app.get('/ready', (req, res) => res.status(200).send('Ready'));

app.use(AWSXRay.express.closeSegment());
app.listen(80, () => console.log('Backend running on port 80'));
