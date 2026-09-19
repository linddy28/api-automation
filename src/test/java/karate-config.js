/**
 * Global Karate configuration.
 *
 * Runs once before any feature. Sets the base URL and the common headers
 * (including the Bearer token) so every feature/scenario inherits them.
 *
 * The token can be overridden via the GOREST_TOKEN environment variable
 * (recommended in CI, so the secret is not hard-coded).
 */
function fn() {
  var env = karate.env || 'dev';
  karate.log('karate.env =', env);

  var token = karate.properties['gorest.token']
    || java.lang.System.getenv('GOREST_TOKEN');

  var config = {
    baseUrl: 'https://gorest.co.in/public/v2',
    token: token
  };

  // Cabeceras aplicadas a TODAS las peticiones (persisten en toda la escena).
  // En Karate, las cabeceras puestas con "header ..." solo aplican a la
  // siguiente petición; con "configure headers" se mantienen en cada request.
  karate.configure('headers', {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    Authorization: 'Bearer ' + token
  });

  // Fail fast if a connection cannot be established
  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 20000);

  // Reintentos por defecto para "retry until" (propagación de recursos en GoRest)
  karate.configure('retry', { count: 5, interval: 1000 });

  return config;
}
