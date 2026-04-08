const http = require('http');
const httpProxy = require('http-proxy');

// Configuration dynamique (utilise le nom du conteneur dans Docker, ou localhost sinon)
const KEYCLOAK_HOST = process.env.KEYCLOAK_HOST || 'localhost';
const BACKEND_HOST = process.env.BACKEND_HOST || 'localhost';

const KEYCLOAK_PORT = 8080;
const BACKEND_PORT = 8083;
const PROXY_PORT = 9000;

const proxy = httpProxy.createProxyServer({});

// Gestion des erreurs pour éviter que le proxy ne crash si un service est éteint
proxy.on('error', function (err, req, res) {
  console.error(`[ERREUR PROXY] ${err.message} pour ${req.url}`);
  res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('Le service local est injoignable. Vérifiez que votre Backend ou Keycloak est lancé.');
});

const server = http.createServer(function (req, res) {
  console.log(`[REQUÊTE] : ${req.method} ${req.url}`);
  if (req.url.startsWith('/api') || req.url.startsWith('/mobile')) {
    proxy.web(req, res, { target: `http://${BACKEND_HOST}:${BACKEND_PORT}`, changeOrigin: true, xfwd: true });
  } else {
    proxy.web(req, res, {
      target: `http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}`,
      changeOrigin: true,
      xfwd: true,
      cookieDomainRewrite: "", // Réécrit les cookies pour qu'ils matchent parfaitement Ngrok
      headers: {
        'X-Forwarded-Proto': 'https',
        'X-Forwarded-Port': '443'
      }
    });
  }
});

console.log(`=======================================================`);
console.log(`PROXY DYNAMIQUE LANCÉ SUR LE PORT ${PROXY_PORT}`);
console.log(`- /api/*    -> Redirigé vers Backend (Port ${BACKEND_PORT})`);
console.log(`- le reste  -> Redirigé vers Keycloak (Port ${KEYCLOAK_PORT})`);
console.log(`=======================================================`);
console.log(`COMMANDE NGROK : ngrok http 9000`);

server.listen(PROXY_PORT);
