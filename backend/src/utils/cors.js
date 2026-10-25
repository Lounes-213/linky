export const corsHeaders = {
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};

export function jsonResponse(data, status = 200, env, request) {
  const headers = { 'Content-Type': 'application/json' };
  const origin = request?.headers?.get('Origin');
  const allowed = (env?.ALLOWED_ORIGINS || '').split(',').map((item) => item.trim()).filter(Boolean);
  if (origin && allowed.includes(origin)) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Vary'] = 'Origin';
  }
  return new Response(JSON.stringify(data), { status, headers });
}

export function errorResponse(message, status = 400, env, request) {
  return jsonResponse({ error: message }, status, env, request);
}

export function withCors(handler) {
  return async (request, env, ctx) => {
    if (request.method === 'OPTIONS') {
      const origin = request.headers.get('Origin');
      const allowed = (env?.ALLOWED_ORIGINS || '').split(',').map((item) => item.trim()).filter(Boolean);
      const headers = {
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
        'Access-Control-Max-Age': '86400',
      };
      if (origin && allowed.includes(origin)) {
        headers['Access-Control-Allow-Origin'] = origin;
        headers['Vary'] = 'Origin';
      }
      return new Response(null, { status: 204, headers });
    }
    return handler(request, env, ctx);
  };
}