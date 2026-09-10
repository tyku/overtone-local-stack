import http from 'node:http';

let requestReads = 0;

const json = (response, status, body) => {
  response.writeHead(status, { 'Content-Type': 'application/json' });
  response.end(JSON.stringify(body));
};

const server = http.createServer((request, response) => {
  const url = new URL(request.url ?? '/', 'http://api');
  if (request.method === 'GET' && url.pathname === '/api/health') {
    json(response, 200, { status: 'ok' });
    return;
  }

  const reportMatch = url.pathname.match(/^\/api\/requests\/([^/]+)\/report$/);
  if (request.method === 'GET' && reportMatch) {
    json(response, 200, {
      requestId: reportMatch[1],
      format: 'markdown',
      schemaVersion: 1,
      content: '# Smoke report\n\nNginx proxy and frontend polling are working.',
    });
    return;
  }

  const requestMatch = url.pathname.match(/^\/api\/requests\/([^/]+)$/);
  if (request.method === 'GET' && requestMatch) {
    requestReads += 1;
    json(response, 200, {
      requestId: requestMatch[1],
      status: requestReads >= 3 ? 'completed' : 'processing',
      createdAt: '2026-09-10T00:00:00.000Z',
      closedAt: '2026-09-10T00:01:00.000Z',
      audioStored: true,
      error: null,
      commands: [],
    });
    return;
  }

  json(response, 404, { message: 'Not Found', statusCode: 404 });
});

server.listen(3000, '0.0.0.0');

const stop = () => server.close(() => process.exit(0));
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
