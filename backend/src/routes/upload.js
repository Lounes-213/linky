import { jsonResponse, errorResponse } from '../utils/cors';

const R2_URL_MARKER = '/api/images/';

function isR2Image(url) {
  if (!url || typeof url !== 'string') return false;
  return url.includes(R2_URL_MARKER) || url.includes('.r2.dev');
}

function extractKeyFromUrl(url) {
  if (!url) return null;
  const idx = url.indexOf(R2_URL_MARKER);
  if (idx !== -1) return url.substring(idx + R2_URL_MARKER.length);
  const r2Match = url.match(/\/r2\.dev\/(.+)$/);
  if (r2Match) return r2Match[1];
  const pubMatch = url.match(/pub-[^/]+\/(.+)$/);
  if (pubMatch) return pubMatch[1];
  return null;
}

async function deleteR2Images(env, urls) {
  if (!Array.isArray(urls) || urls.length === 0) return;
  const keys = urls.map(extractKeyFromUrl).filter(Boolean);
  if (keys.length === 0) return;
  await Promise.allSettled(keys.map(key => env.IMAGES.delete(key)));
}

export const uploadRoutes = {
  async upload(request, env) {
    const formData = await request.formData();
    const file = formData.get('file');
    const folder = formData.get('folder') || 'misc';
    const replaceKey = formData.get('replace_key') || null;

    if (!file) return errorResponse('No file provided');
    if (!(file instanceof File) || file.size > 5 * 1024 * 1024) return errorResponse('Image must be smaller than 5 MB', 422);

    let contentType = file.type || '';
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(contentType)) {
      const name = (file.name || '').toLowerCase();
      if (name.endsWith('.png')) contentType = 'image/png';
      else if (name.endsWith('.webp')) contentType = 'image/webp';
      else contentType = 'image/jpeg';
    }

    if (!['profile', 'portfolio', 'products', 'misc', 'stores', 'stories'].includes(folder)) return errorResponse('Invalid upload folder', 422);

    const key = replaceKey || `${folder}/${request.user.uid}/${Date.now()}_${file.name}`;
    const buffer = await file.arrayBuffer();

    if (replaceKey) {
      try { await env.IMAGES.delete(replaceKey); } catch (_) {}
    }

    await env.IMAGES.put(key, buffer, {
      httpMetadata: { contentType }
    });

    const workerOrigin = new URL(request.url).origin;
    const url = `${workerOrigin}/api/images/${key}`;

    return jsonResponse({ url, key });
  },

  async getImage(request, env) {
    const url = new URL(request.url);
    const key = url.pathname.replace(/^\/api\/images\//, '');
    if (!key) return errorResponse('Not found', 404);

    const object = await env.IMAGES.get(key);
    if (!object) return errorResponse('Not found', 404);

    const headers = new Headers();
    if (object.httpMetadata && object.httpMetadata.contentType) {
      headers.set('Content-Type', object.httpMetadata.contentType);
    } else {
      headers.set('Content-Type', 'image/jpeg');
    }
    headers.set('etag', object.httpEtag);
    headers.set('Access-Control-Allow-Origin', '*');
    headers.set('Cache-Control', 'public, max-age=31536000');

    return new Response(object.body, { headers });
  },

  async deleteImages(request, env) {
    const { urls } = await request.json();
    await deleteR2Images(env, urls);
    return jsonResponse({ deleted: true });
  },

  async presign(request, env) {
    const { filename, content_type, folder } = await request.json();
    const key = `${folder || 'misc'}/${request.user.uid}/${Date.now()}_${filename}`;

    const workerOrigin = new URL(request.url).origin;
    const url = `${workerOrigin}/api/images/${key}`;

    return jsonResponse({ url, key });
  }
};

export { isR2Image, extractKeyFromUrl, deleteR2Images };
