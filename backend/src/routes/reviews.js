import { jsonResponse, errorResponse } from '../utils/cors';

export const reviewRoutes = {
  async list(request, env) {
    const { id } = request.params;
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '10');
    const offset = (page - 1) * limit;

    const reviews = await env.DB.prepare(
      `SELECT r.*, u.name as user_name, u.avatar_url as user_avatar
       FROM reviews r JOIN users u ON r.user_id = u.id
       WHERE r.product_id = ? ORDER BY r.created_at DESC LIMIT ? OFFSET ?`
    ).bind(id, limit, offset).all();

    const stats = await env.DB.prepare(
      `SELECT AVG(rating) as avg_rating, COUNT(*) as total_reviews,
              SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star,
              SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star,
              SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star,
              SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star,
              SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star
       FROM reviews WHERE product_id = ?`
    ).bind(id).first();

    return jsonResponse({
      reviews: (reviews.results || []).map(r => ({
        ...r,
        images: JSON.parse(r.images || '[]')
      })),
      stats: stats || {}
    });
  },

  async create(request, env) {
    const { id } = request.params;
    const { rating, title, comment, images } = await request.json();

    if (!rating || rating < 1 || rating > 5) {
      return errorResponse('Rating must be between 1 and 5');
    }

    const existing = await env.DB.prepare(
      'SELECT id FROM reviews WHERE user_id = ? AND product_id = ?'
    ).bind(request.user.uid, id).first();

    if (existing) return errorResponse('You already reviewed this product');

    const reviewId = crypto.randomUUID();
    await env.DB.prepare(
      `INSERT INTO reviews (id, user_id, product_id, rating, title, comment, images, is_verified)
       VALUES (?, ?, ?, ?, ?, ?, ?, 1)`
    ).bind(reviewId, request.user.uid, id, rating, title || '', comment || '', JSON.stringify(images || [])).run();

    const stats = await env.DB.prepare(
      'SELECT AVG(rating) as avg_rating, COUNT(*) as total_reviews FROM reviews WHERE product_id = ?'
    ).bind(id).first();

    await env.DB.prepare(
      'UPDATE products SET avg_rating = ?, total_reviews = ? WHERE id = ?'
    ).bind(stats.avg_rating, stats.total_reviews, id).run();

    return jsonResponse({ id: reviewId, message: 'Review created' }, 201);
  }
};
