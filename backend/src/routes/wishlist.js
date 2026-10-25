import { jsonResponse, errorResponse } from '../utils/cors';

export const wishlistRoutes = {
  async list(request, env) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;

    const items = await env.DB.prepare(
      `SELECT w.id, w.product_id, w.created_at,
              p.name as product_name, p.base_price, p.images, p.avg_rating,
              s.name as store_name, s.slug as store_slug
       FROM wishlist w
       JOIN products p ON w.product_id = p.id
       JOIN stores s ON p.store_id = s.id
       WHERE w.user_id = ?
       ORDER BY w.created_at DESC
       LIMIT ? OFFSET ?`
    ).bind(request.user.uid, limit, offset).all();

    const total = await env.DB.prepare(
      'SELECT COUNT(*) as count FROM wishlist WHERE user_id = ?'
    ).bind(request.user.uid).first();

    return jsonResponse({
      items: items.results || [],
      total: total?.count || 0,
      page,
      limit
    });
  },

  async add(request, env) {
    const { product_id } = await request.json();

    if (!product_id) {
      return errorResponse('product_id is required', 400);
    }

    const existing = await env.DB.prepare(
      'SELECT id FROM wishlist WHERE user_id = ? AND product_id = ?'
    ).bind(request.user.uid, product_id).first();

    if (existing) {
      return errorResponse('Product already in wishlist', 409);
    }

    const id = crypto.randomUUID();
    await env.DB.prepare(
      'INSERT INTO wishlist (id, user_id, product_id) VALUES (?, ?, ?)'
    ).bind(id, request.user.uid, product_id).run();

    return jsonResponse({ message: 'Added to wishlist', id }, 201);
  },

  async remove(request, env) {
    const { productId } = request.params;

    const existing = await env.DB.prepare(
      'SELECT id FROM wishlist WHERE user_id = ? AND product_id = ?'
    ).bind(request.user.uid, productId).first();

    if (!existing) {
      return errorResponse('Product not in wishlist', 404);
    }

    await env.DB.prepare(
      'DELETE FROM wishlist WHERE user_id = ? AND product_id = ?'
    ).bind(request.user.uid, productId).run();

    return jsonResponse({ message: 'Removed from wishlist' });
  },

  async check(request, env) {
    const { productId } = request.params;

    const existing = await env.DB.prepare(
      'SELECT id FROM wishlist WHERE user_id = ? AND product_id = ?'
    ).bind(request.user.uid, productId).first();

    return jsonResponse({ is_wishlisted: !!existing });
  }
};
