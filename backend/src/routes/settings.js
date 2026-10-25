import { jsonResponse, errorResponse } from '../utils/cors';

export const settingsRoutes = {
  async list(request, env) {
    const settings = await env.DB.prepare(
      'SELECT key, value, type FROM settings'
    ).all();

    const mapped = {};
    for (const s of settings.results || []) {
      let value = s.value;
      if (s.type === 'json') value = JSON.parse(value);
      if (s.type === 'boolean') value = value === 'true';
      if (s.type === 'number') value = parseFloat(value);
      mapped[s.key] = value;
    }

    return jsonResponse({ settings: mapped });
  },

  async update(request, env) {
    const { key } = request.params;
    const { value, type = 'string' } = await request.json();

    let storedValue = value;
    if (type === 'json') storedValue = JSON.stringify(value);

    await env.DB.prepare(
      `INSERT INTO settings (id, key, value, type, updated_at) VALUES (?, ?, ?, ?, datetime('now'))
       ON CONFLICT(key) DO UPDATE SET value = ?, type = ?, updated_at = datetime('now')`
    ).bind(crypto.randomUUID(), key, storedValue, type, storedValue, type).run();

    return jsonResponse({ message: 'Setting updated' });
  }
};
