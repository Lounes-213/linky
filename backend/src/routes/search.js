import { jsonResponse, errorResponse } from '../utils/cors';

export const searchRoutes = {
  async search(request, env) {
    const url = new URL(request.url);
    const q = url.searchParams.get('q') || '';
    const type = url.searchParams.get('type') || 'all';
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;

    if (!q || q.length < 2) return errorResponse('Query must be at least 2 characters');

    const results = {};

    if (type === 'all' || type === 'products') {
      const products = await env.DB.prepare(
        `SELECT p.*, s.name as store_name FROM products p 
         JOIN stores s ON p.store_id = s.id
         WHERE p.is_active = 1 AND (p.name LIKE ? OR p.description LIKE ? OR p.tags LIKE ?)
         ORDER BY p.total_sold DESC LIMIT ? OFFSET ?`
      ).bind(`%${q}%`, `%${q}%`, `%${q}%`, limit, offset).all();
      results.products = products.results || [];
    }

    if (type === 'all' || type === 'stores') {
      const stores = await env.DB.prepare(
        `SELECT id, name, slug, description, logo_url, rating, total_products
         FROM stores WHERE is_active = 1 AND (name LIKE ? OR description LIKE ? OR category LIKE ?)
         ORDER BY total_followers DESC LIMIT ? OFFSET ?`
      ).bind(`%${q}%`, `%${q}%`, `%${q}%`, limit, offset).all();
      results.stores = stores.results || [];
    }

    if (type === 'all' || type === 'users') {
      const users = await env.DB.prepare(
        `SELECT id, name, username, avatar_url, bio
         FROM users WHERE (name LIKE ? OR username LIKE ?)
         LIMIT ? OFFSET ?`
      ).bind(`%${q}%`, `%${q}%`, limit, offset).all();
      results.users = users.results || [];
    }

    return jsonResponse(results);
  },

  async suggestions(request, env) {
    const url = new URL(request.url);
    const q = url.searchParams.get('q') || '';

    if (!q || q.length < 1) return jsonResponse({ suggestions: [] });

    const products = await env.DB.prepare(
      `SELECT name, id FROM products WHERE name LIKE ? AND is_active = 1 LIMIT 5`
    ).bind(`${q}%`).all();

    const stores = await env.DB.prepare(
      `SELECT name, slug FROM stores WHERE name LIKE ? AND is_active = 1 LIMIT 5`
    ).bind(`${q}%`).all();

    const categories = await env.DB.prepare(
      `SELECT name, slug FROM categories WHERE name LIKE ? LIMIT 3`
    ).bind(`${q}%`).all();

    return jsonResponse({
      suggestions: [
        ...(products.results || []).map(p => ({ type: 'product', ...p })),
        ...(stores.results || []).map(s => ({ type: 'store', ...s })),
        ...(categories.results || []).map(c => ({ type: 'category', ...c }))
      ]
    });
  }
};
