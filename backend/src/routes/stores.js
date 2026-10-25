import { jsonResponse, errorResponse } from '../utils/cors';

const staffRoles = new Set(['manager', 'partner', 'editor', 'viewer']);

async function ownerOrManager(request, env, storeId) {
  const store = await env.DB.prepare('SELECT owner_id, total_products FROM stores WHERE id = ?').bind(storeId).first();
  if (!store) return null;
  if (store.owner_id === request.user.uid || store.owner_id === request.user.firebaseUid) return { store, canManageTeam: true };
  const membership = await env.DB.prepare('SELECT role FROM store_employees WHERE store_id = ? AND user_id = ? AND is_active = 1').bind(storeId, request.user.uid).first();
  return membership ? { store, canManageTeam: membership.role === 'manager' } : null;
}

async function checkAndBlockExpiredStores(env) {
  await env.DB.prepare(
    `UPDATE stores SET is_active = 0 WHERE is_active = 1 AND code_expires_at IS NOT NULL AND code_expires_at <= datetime('now')`
  ).run();
}

export const storeRoutes = {
  async validateCode(request, env) {
    const url = new URL(request.url);
    const code = url.searchParams.get('code');

    if (!code) return errorResponse('Code is required');

    const cleanCode = code.trim().toUpperCase();

    const storeCode = await env.DB.prepare(
      'SELECT id, code, expires_at FROM store_codes WHERE code = ? AND is_used = 0'
    ).bind(cleanCode).first();

    if (!storeCode) return errorResponse('Invalid or already used code', 404);

    if (new Date(storeCode.expires_at) < new Date()) {
      return errorResponse('Code has expired', 410);
    }

    return jsonResponse({ valid: true, code: storeCode.code });
  },
  async list(request, env) {
    await checkAndBlockExpiredStores(env);
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const category = url.searchParams.get('category');
    const mine = url.searchParams.get('mine') === 'true';
    const offset = (page - 1) * limit;

    if (mine) {
      let user = null;
      const authHeader = request.headers.get('Authorization');
      if (authHeader && authHeader.startsWith('Bearer ')) {
        try {
          const token = authHeader.split(' ')[1];
          const { verifyToken } = await import('../middleware/auth.js');
          user = await verifyToken(token, env);
          if (user && env.DB) {
            const dbUser = await env.DB.prepare('SELECT id FROM users WHERE firebase_uid = ?').bind(user.uid).first();
            if (dbUser) user.uid = dbUser.id;
          }
        } catch (_) {}
      }
      if (!user) return errorResponse('Unauthorized', 401);
      const stores = await env.DB.prepare(
        'SELECT id, name, slug, description, logo_url, cover_url, primary_color, phone, email, address, city, rating, total_reviews, total_followers, total_products, is_verified, settings, social_links, owner_id FROM stores WHERE owner_id = ? ORDER BY created_at DESC'
      ).bind(user.uid).all();
      return jsonResponse({ stores: stores.results || [] });
    }

    const cacheKey = `stores:${category || 'all'}:${page}`;
    const cached = await env.CACHE.get(cacheKey);
    if (cached) {
      return jsonResponse(JSON.parse(cached));
    }

    let query = 'SELECT id, name, slug, description, logo_url, cover_url, primary_color, rating, total_reviews, total_followers, total_products, city, is_verified FROM stores WHERE is_active = 1';
    const params = [];

    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }

    query += ' ORDER BY total_followers DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const stores = await env.DB.prepare(query).bind(...params).all();

    const result = { stores: stores.results || [] };

    await env.CACHE.put(cacheKey, JSON.stringify(result), { expirationTtl: 300 });

    return jsonResponse(result);
  },

  async getBySlug(request, env) {
    const { slug } = request.params;

    const store = await env.DB.prepare(
      'SELECT * FROM stores WHERE slug = ? AND is_active = 1'
    ).bind(slug).first();

    if (!store) return errorResponse('Store not found', 404);

    const products = await env.DB.prepare(
      'SELECT id, name, slug, base_price, discount_price, images, avg_rating, total_sold FROM products WHERE store_id = ? AND is_active = 1 ORDER BY total_sold DESC LIMIT 20'
    ).bind(store.id).all();

    const followersCount = await env.DB.prepare(
      'SELECT COUNT(*) as count FROM store_followers WHERE store_id = ?'
    ).bind(store.id).first();

    return jsonResponse({
      ...store,
      products: products.results || [],
      followers_count: followersCount?.count || 0
    });
  },

  async create(request, env) {
    const body = await request.json();
    const { name, description, category, subcategory, phone, email, address, city, invite_code, maps_url, website, settings } = body;

    if (!name) return errorResponse('Store name is required');
    if (!invite_code) return errorResponse('Invite code is required');

    const cleanCode = invite_code.trim().toUpperCase();

    const storeCode = await env.DB.prepare(
      'SELECT * FROM store_codes WHERE code = ? AND is_used = 0'
    ).bind(cleanCode).first();

    if (!storeCode) return errorResponse('Invalid or already used invite code');

    if (new Date(storeCode.expires_at) < new Date()) {
      return errorResponse('Invite code has expired');
    }

    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
    const id = crypto.randomUUID();
    const ownerId = request.user?.uid || 'demo-owner';

    // Ensure user exists in users table if DB is bound
    try {
      const userExists = await env.DB.prepare('SELECT id FROM users WHERE id = ?').bind(ownerId).first();
      if (!userExists) {
        await env.DB.prepare(
          'INSERT INTO users (id, username, email, referral_code) VALUES (?, ?, ?, ?)'
        ).bind(ownerId, `user_${id.slice(0, 8)}`, request.user?.email || `owner_${id.slice(0, 6)}@linky.to`, `REF-${id.slice(0, 6)}`).run();
      }
    } catch (_) {}

    const socialLinks = settings?.social ? JSON.stringify(settings.social) : '{}';
    const storeSettings = settings ? JSON.stringify({
      currency: settings.currency || 'DA',
      payment_methods: settings.payment_methods || {},
      delivery: settings.delivery || {},
      theme_dark: settings.theme_dark || false,
      primary_color: settings.primary_color || '#5B5FC7',
      cta_button: settings.cta_button || 'Commander',
      show_reviews: settings.show_reviews ?? true,
      show_followers: settings.show_followers ?? true,
      show_popular: settings.show_popular ?? true,
      show_stories: settings.show_stories ?? true,
    }) : '{}';
    const keywords = settings?.keywords ? JSON.stringify(settings.keywords) : '[]';
    const languages = settings?.languages ? JSON.stringify(settings.languages) : '{"fr":true,"ar":true,"en":false}';
    const country = settings?.country || 'Algeria';
    const state = settings?.state || '';

    await env.DB.prepare(
      `INSERT INTO stores (id, owner_id, name, slug, description, category, subcategory, phone, email, address, city,
       maps_url, website, social_links, settings, keywords, languages, country, state, code_expires_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(id, ownerId, name, `${slug}-${id.slice(0, 6)}`, description || '', category || '', subcategory || '',
      phone || '', email || '', address || '', city || '', maps_url || '', website || '',
      socialLinks, storeSettings, keywords, languages, country, state, storeCode.expires_at).run();

    try {
      await env.DB.prepare(
        'UPDATE store_codes SET is_used = 1, used_by = ?, used_at = datetime(\'now\') WHERE id = ?'
      ).bind(ownerId, storeCode.id).run();
    } catch (_) {}

    return jsonResponse({ id, name, slug: `${slug}-${id.slice(0, 6)}` }, 201);
  },

  async update(request, env) {
    const { id } = request.params;
    const store = await env.DB.prepare('SELECT owner_id FROM stores WHERE id = ?').bind(id).first();

    if (!store) return errorResponse('Store not found', 404);
    if (store.owner_id !== request.user.uid && store.owner_id !== request.user.firebaseUid) return errorResponse('Unauthorized', 403);

    const body = await request.json();
    const { name, description, category, subcategory, phone, email, address, city, primary_color,
      logo_url, cover_url, maps_url, website, social_links, settings, keywords, languages, country, state } = body;

    const safeColor = /^#[0-9A-Fa-f]{6}$/.test(primary_color || '') ? primary_color : null;

    const socialStr = social_links ? (typeof social_links === 'string' ? social_links : JSON.stringify(social_links)) : undefined;
    const settingsStr = settings ? (typeof settings === 'string' ? settings : JSON.stringify(settings)) : undefined;
    const keywordsStr = keywords ? (typeof keywords === 'string' ? keywords : JSON.stringify(keywords)) : undefined;
    const languagesStr = languages ? (typeof languages === 'string' ? languages : JSON.stringify(languages)) : undefined;

    await env.DB.prepare(
      `UPDATE stores SET name = COALESCE(?, name), description = COALESCE(?, description),
       category = COALESCE(?, category), subcategory = COALESCE(?, subcategory),
       phone = COALESCE(?, phone), email = COALESCE(?, email),
       address = COALESCE(?, address), city = COALESCE(?, city),
       primary_color = COALESCE(?, primary_color), logo_url = COALESCE(?, logo_url),
       cover_url = COALESCE(?, cover_url), maps_url = COALESCE(?, maps_url),
       website = COALESCE(?, website), social_links = COALESCE(?, social_links),
       settings = COALESCE(?, settings), keywords = COALESCE(?, keywords),
       languages = COALESCE(?, languages), country = COALESCE(?, country),
       state = COALESCE(?, state), updated_at = datetime('now') WHERE id = ?`
    ).bind(name ?? null, description ?? null, category ?? null, subcategory ?? null, phone ?? null, email ?? null, address ?? null, city ?? null, safeColor, logo_url ?? null, cover_url ?? null, maps_url ?? null, website ?? null, socialStr ?? null, settingsStr ?? null, keywordsStr ?? null, languagesStr ?? null, country ?? null, state ?? null, id).run();

    return jsonResponse({ message: 'Store updated' });
  },

  async getProducts(request, env) {
    const { id } = request.params;
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;

    const products = await env.DB.prepare(
      'SELECT p.id, p.name, p.slug, p.base_price, p.discount_price, p.images, p.stock, p.avg_rating, p.total_sold, p.category_id, c.name as category FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE p.store_id = ? AND p.is_active = 1 ORDER BY p.created_at DESC LIMIT ? OFFSET ?'
    ).bind(id, limit, offset).all();

    const results = products.results || [];
    for (const p of results) {
      const variants = await env.DB.prepare(
        'SELECT id, name, type, color_hex, price_extra, stock FROM product_variants WHERE product_id = ? AND is_active = 1'
      ).bind(p.id).all();
      p.variants = variants.results || [];
    }

    return jsonResponse({ products: results });
  },

  async follow(request, env) {
    const { id } = request.params;
    const existing = await env.DB.prepare(
      'SELECT id FROM store_followers WHERE store_id = ? AND user_id = ?'
    ).bind(id, request.user.uid).first();

    if (existing) return errorResponse('Already following');

    await env.DB.prepare(
      'INSERT INTO store_followers (id, store_id, user_id) VALUES (?, ?, ?)'
    ).bind(crypto.randomUUID(), id, request.user.uid).run();

    await env.DB.prepare(
      'UPDATE stores SET total_followers = total_followers + 1 WHERE id = ?'
    ).bind(id).run();

    return jsonResponse({ message: 'Following store' });
  },

  async unfollow(request, env) {
    const { id } = request.params;

    await env.DB.prepare(
      'DELETE FROM store_followers WHERE store_id = ? AND user_id = ?'
    ).bind(id, request.user.uid).run();

    await env.DB.prepare(
      'UPDATE stores SET total_followers = total_followers - 1 WHERE id = ?'
    ).bind(id).run();

    return jsonResponse({ message: 'Unfollowed store' });
  },

  async getAnalytics(request, env) {
    const { id } = request.params;
    const store = await env.DB.prepare('SELECT owner_id FROM stores WHERE id = ?').bind(id).first();

    if (!store || (store.owner_id !== request.user.uid && store.owner_id !== request.user.firebaseUid)) return errorResponse('Unauthorized', 403);

    const analytics = await env.DB.prepare(
      'SELECT * FROM store_analytics WHERE store_id = ? ORDER BY date DESC LIMIT 30'
    ).bind(id).all();

    return jsonResponse({ analytics: analytics.results || [] });
  },

  async dashboard(request, env) {
    const access = await ownerOrManager(request, env, request.params.id);
    if (!access) return errorResponse('Unauthorized', 403);
    const storeId = request.params.id;
    const [summary, lowStock, topProducts, recentOrders] = await Promise.all([
      env.DB.prepare(`SELECT COUNT(DISTINCT os.id) AS orders_count, COALESCE(SUM(os.subtotal), 0) AS revenue,
        COALESCE(SUM(CASE WHEN os.status = 'delivered' THEN 1 ELSE 0 END), 0) AS delivered_count
        FROM order_stores os WHERE os.store_id = ?`).bind(storeId).first(),
      env.DB.prepare('SELECT id, name, stock, images FROM products WHERE store_id = ? AND is_active = 1 AND stock <= 5 ORDER BY stock ASC LIMIT 8').bind(storeId).all(),
      env.DB.prepare('SELECT id, name, total_sold, avg_rating, total_reviews, images FROM products WHERE store_id = ? AND is_active = 1 ORDER BY total_sold DESC LIMIT 5').bind(storeId).all(),
      env.DB.prepare(`SELECT o.order_number, os.status, os.subtotal, o.created_at FROM order_stores os
        JOIN orders o ON o.id = os.order_id WHERE os.store_id = ? ORDER BY o.created_at DESC LIMIT 6`).bind(storeId).all(),
    ]);
    return jsonResponse({
      can_manage: access.canManageTeam,
      summary: { products: access.store.total_products || 0, orders: summary?.orders_count || 0, revenue: summary?.revenue || 0, delivered: summary?.delivered_count || 0 },
      low_stock: lowStock.results || [], top_products: topProducts.results || [], recent_orders: recentOrders.results || [],
    });
  },

  async team(request, env) {
    const access = await ownerOrManager(request, env, request.params.id);
    if (!access) return errorResponse('Unauthorized', 403);
    const members = await env.DB.prepare(`SELECT e.id, e.user_id, e.role, e.permissions, e.is_active, e.created_at,
      u.name, u.email, u.avatar_url FROM store_employees e JOIN users u ON u.id = e.user_id
      WHERE e.store_id = ? ORDER BY CASE e.role WHEN 'manager' THEN 0 WHEN 'partner' THEN 1 ELSE 2 END, e.created_at`).bind(request.params.id).all();
    const owner = await env.DB.prepare('SELECT id AS user_id, name, email, avatar_url FROM users WHERE id = ?').bind(access.store.owner_id).first();
    return jsonResponse({
      owner_id: access.store.owner_id,
      can_manage_team: access.canManageTeam,
      members: [{ id: null, ...owner, role: 'owner', is_active: 1 }, ...(members.results || [])]
    });
  },

  async addTeamMember(request, env) {
    const access = await ownerOrManager(request, env, request.params.id);
    if (!access?.canManageTeam) return errorResponse('Only the owner or manager can invite team members', 403);
    const { email, role } = await request.json();
    const safeRole = String(role || '').toLowerCase();
    if (!staffRoles.has(safeRole) || !String(email || '').trim()) return errorResponse('Email and valid role are required');
    const user = await env.DB.prepare('SELECT id FROM users WHERE lower(email) = lower(?)').bind(String(email).trim()).first();
    if (!user) return errorResponse('This user must create a Linky account first', 404);
    if (user.id === access.store.owner_id) return errorResponse('The owner is already on this store');
    await env.DB.prepare(`INSERT INTO store_employees (id, store_id, user_id, role, permissions, is_active)
      VALUES (?, ?, ?, ?, ?, 1) ON CONFLICT(store_id, user_id) DO UPDATE SET role = excluded.role, is_active = 1`)
      .bind(crypto.randomUUID(), request.params.id, user.id, safeRole, '{}').run();
    return jsonResponse({ ok: true }, 201);
  },

  async updateTeamMember(request, env) {
    const access = await ownerOrManager(request, env, request.params.id);
    if (!access?.canManageTeam) return errorResponse('Only the owner or manager can change team access', 403);
    const { role, is_active } = await request.json();
    const safeRole = role == null ? null : String(role).toLowerCase();
    if (safeRole != null && !staffRoles.has(safeRole)) return errorResponse('Invalid role');
    await env.DB.prepare('UPDATE store_employees SET role = COALESCE(?, role), is_active = COALESCE(?, is_active) WHERE id = ? AND store_id = ?')
      .bind(safeRole, typeof is_active === 'boolean' ? Number(is_active) : null, request.params.memberId, request.params.id).run();
    return jsonResponse({ ok: true });
  },

  async removeTeamMember(request, env) {
    const access = await ownerOrManager(request, env, request.params.id);
    if (!access?.canManageTeam) return errorResponse('Only the owner or manager can remove members', 403);
    await env.DB.prepare('DELETE FROM store_employees WHERE id = ? AND store_id = ?').bind(request.params.memberId, request.params.id).run();
    return jsonResponse({ ok: true });
  }
};
