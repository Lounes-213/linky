import { jsonResponse, errorResponse } from '../utils/cors';

function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = new Uint8Array(10);
  crypto.getRandomValues(bytes);
  let code = 'LINKY-';
  for (let i = 0; i < 10; i++) {
    code += chars.charAt(bytes[i] % chars.length);
  }
  return code;
}

export const adminRoutes = {
  async generateCodes(request, env) {
    const { count = 10, days_valid = 30 } = await request.json();
    const codes = [];

    for (let i = 0; i < Math.min(count, 50); i++) {
      const id = crypto.randomUUID();
      const code = generateCode();
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + days_valid);

      await env.DB.prepare(
        `INSERT INTO store_codes (id, code, created_by, expires_at) VALUES (?, ?, ?, ?)`
      ).bind(id, code, request.user.uid, expiresAt.toISOString()).run();

      codes.push({ id, code, expires_at: expiresAt.toISOString() });
    }

    return jsonResponse({ codes }, 201);
  },

  async listCodes(request, env) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const offset = (page - 1) * limit;

    const codes = await env.DB.prepare(
      `SELECT sc.*, u.name as created_by_name
       FROM store_codes sc
       LEFT JOIN users u ON sc.created_by = u.id
       ORDER BY sc.created_at DESC LIMIT ? OFFSET ?`
    ).bind(limit, offset).all();

    const total = await env.DB.prepare('SELECT COUNT(*) as count FROM store_codes').bind().first();

    return jsonResponse({
      codes: codes.results || [],
      total: total?.count || 0,
      page,
      limit
    });
  },

  async deleteCode(request, env) {
    const { id } = request.params;
    await env.DB.prepare('DELETE FROM store_codes WHERE id = ?').bind(id).run();
    return jsonResponse({ message: 'Code deleted' });
  },

  async stats(request, env) {
    const [totalCodes, usedCodes, activeCodes, expiredCodes, totalStores, totalUsers, totalProducts] = await Promise.all([
      env.DB.prepare('SELECT COUNT(*) as count FROM store_codes').bind().first(),
      env.DB.prepare('SELECT COUNT(*) as count FROM store_codes WHERE is_used = 1').bind().first(),
      env.DB.prepare(`SELECT COUNT(*) as count FROM store_codes WHERE is_used = 0 AND expires_at > datetime('now')`).bind().first(),
      env.DB.prepare(`SELECT COUNT(*) as count FROM store_codes WHERE expires_at <= datetime('now')`).bind().first(),
      env.DB.prepare('SELECT COUNT(*) as count FROM stores').bind().first(),
      env.DB.prepare('SELECT COUNT(*) as count FROM users').bind().first(),
      env.DB.prepare('SELECT COUNT(*) as count FROM products').bind().first()
    ]);

    return jsonResponse({
      total_codes: totalCodes?.count || 0,
      used_codes: usedCodes?.count || 0,
      active_codes: activeCodes?.count || 0,
      expired_codes: expiredCodes?.count || 0,
      total_stores: totalStores?.count || 0,
      total_users: totalUsers?.count || 0,
      total_products: totalProducts?.count || 0
    });
  },

  async listUsers(request, env) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;
    const search = url.searchParams.get('search') || '';

    let query = `SELECT u.*, (SELECT COUNT(*) FROM stores WHERE owner_id = u.id) as store_count
                 FROM users u`;
    const params = [];

    if (search) {
      query += ` WHERE u.name LIKE ? OR u.email LIKE ?`;
      params.push(`%${search}%`, `%${search}%`);
    }

    query += ` ORDER BY u.created_at DESC LIMIT ? OFFSET ?`;
    params.push(limit, offset);

    const users = await env.DB.prepare(query).bind(...params).all();

    const totalQuery = search
      ? `SELECT COUNT(*) as count FROM users WHERE name LIKE ? OR email LIKE ?`
      : `SELECT COUNT(*) as count FROM users`;
    const total = search
      ? await env.DB.prepare(totalQuery).bind(`%${search}%`, `%${search}%`).first()
      : await env.DB.prepare(totalQuery).bind().first();

    return jsonResponse({
      users: users.results || [],
      total: total?.count || 0,
      page,
      limit
    });
  },

  async getUser(request, env) {
    const { id } = request.params;

    const user = await env.DB.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(id).first();

    if (!user) {
      return errorResponse('User not found', 404);
    }

    const stores = await env.DB.prepare(
      'SELECT * FROM stores WHERE owner_id = ?'
    ).bind(id).all();

    const orderCount = await env.DB.prepare(
      'SELECT COUNT(*) as count FROM orders WHERE user_id = ?'
    ).bind(id).first();

    return jsonResponse({
      user,
      stores: stores.results || [],
      order_count: orderCount?.count || 0
    });
  },

  async banUser(request, env) {
    const { id } = request.params;

    const user = await env.DB.prepare(
      'SELECT is_active FROM users WHERE id = ?'
    ).bind(id).first();

    if (!user) {
      return errorResponse('User not found', 404);
    }

    const newStatus = user.is_active ? 0 : 1;
    await env.DB.prepare(
      'UPDATE users SET is_active = ? WHERE id = ?'
    ).bind(newStatus, id).run();

    return jsonResponse({ message: newStatus ? 'User activated' : 'User banned', is_active: newStatus });
  },

  async listStores(request, env) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;
    const search = url.searchParams.get('search') || '';

    let query = `SELECT s.*, u.name as owner_name
                 FROM stores s
                 LEFT JOIN users u ON s.owner_id = u.id`;
    const params = [];

    if (search) {
      query += ` WHERE s.name LIKE ?`;
      params.push(`%${search}%`);
    }

    query += ` ORDER BY s.created_at DESC LIMIT ? OFFSET ?`;
    params.push(limit, offset);

    const stores = await env.DB.prepare(query).bind(...params).all();

    const totalQuery = search
      ? `SELECT COUNT(*) as count FROM stores WHERE name LIKE ?`
      : `SELECT COUNT(*) as count FROM stores`;
    const total = search
      ? await env.DB.prepare(totalQuery).bind(`%${search}%`).first()
      : await env.DB.prepare(totalQuery).bind().first();

    return jsonResponse({
      stores: stores.results || [],
      total: total?.count || 0,
      page,
      limit
    });
  },

  async toggleStore(request, env) {
    const { id } = request.params;

    const store = await env.DB.prepare(
      'SELECT is_active FROM stores WHERE id = ?'
    ).bind(id).first();

    if (!store) {
      return errorResponse('Store not found', 404);
    }

    const newStatus = store.is_active ? 0 : 1;
    await env.DB.prepare(
      'UPDATE stores SET is_active = ? WHERE id = ?'
    ).bind(newStatus, id).run();

    return jsonResponse({ message: newStatus ? 'Store activated' : 'Store deactivated', is_active: newStatus });
  },

  async verifyStore(request, env) {
    const { id } = request.params;

    const store = await env.DB.prepare(
      'SELECT is_verified FROM stores WHERE id = ?'
    ).bind(id).first();

    if (!store) {
      return errorResponse('Store not found', 404);
    }

    const newStatus = store.is_verified ? 0 : 1;
    await env.DB.prepare(
      'UPDATE stores SET is_verified = ? WHERE id = ?'
    ).bind(newStatus, id).run();

    return jsonResponse({ message: newStatus ? 'Store verified' : 'Store unverified', is_verified: newStatus });
  },

  async listProducts(request, env) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;

    const products = await env.DB.prepare(
      `SELECT p.*, s.name as store_name
       FROM products p
       LEFT JOIN stores s ON p.store_id = s.id
       ORDER BY p.created_at DESC
       LIMIT ? OFFSET ?`
    ).bind(limit, offset).all();

    const total = await env.DB.prepare('SELECT COUNT(*) as count FROM products').bind().first();

    return jsonResponse({
      products: products.results || [],
      total: total?.count || 0,
      page,
      limit
    });
  },

  async renewStore(request, env) {
    const { id } = request.params;
    const { days_valid = 30 } = await request.json();

    const store = await env.DB.prepare('SELECT id, code_expires_at FROM stores WHERE id = ?').bind(id).first();
    if (!store) return errorResponse('Store not found', 404);

    const baseDate = new Date(store.code_expires_at || new Date());
    if (baseDate < new Date()) baseDate.setTime(Date.now());
    baseDate.setDate(baseDate.getDate() + days_valid);

    await env.DB.prepare(
      'UPDATE stores SET code_expires_at = ?, is_active = 1 WHERE id = ?'
    ).bind(baseDate.toISOString(), id).run();

    const code = generateCode();
    const codeId = crypto.randomUUID();
    await env.DB.prepare(
      `INSERT INTO store_codes (id, code, created_by, expires_at, is_used, used_by) VALUES (?, ?, ?, ?, 1, ?)`
    ).bind(codeId, code, request.user.uid, baseDate.toISOString(), store.owner_id || request.user.uid).run();

    return jsonResponse({
      message: 'Store renewed',
      code_expires_at: baseDate.toISOString(),
      new_code: code,
      days_added: days_valid
    });
  }
};
