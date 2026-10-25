import http from 'node:http';
import scrape from '../index.js';

const port = Number(process.env.PORT || 8788);
const token = process.env.IMPORT_SERVICE_TOKEN;
const send = (res, status, body) => { res.writeHead(status, { 'content-type': 'application/json; charset=utf-8' }); res.end(JSON.stringify(body)); };
const productId = (value) => String(value || '').match(/(?:item\/|productId=)(\d{8,})/)?.[1] || String(value || '').match(/^\d{8,}$/)?.[0];

http.createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/health') return send(res, 200, { ok: true });
  if (req.method !== 'POST' || req.url !== '/preview') return send(res, 404, { error: 'Not found' });
  if (!token || req.headers.authorization !== `Bearer ${token}`) return send(res, 401, { error: 'Unauthorized' });
  let payload = ''; for await (const chunk of req) payload += chunk;
  try {
    const id = productId(JSON.parse(payload).url);
    if (!id) return send(res, 422, { error: 'Invalid AliExpress product URL' });
    return send(res, 200, { product: await scrape(id, { reviewsCount: 0, timeout: 90000 }) });
  } catch (error) { return send(res, 502, { error: 'Import unavailable', detail: error.message }); }
}).listen(port, () => console.log(`AliExpress import service listening on ${port}`));
