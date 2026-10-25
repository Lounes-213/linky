import { jsonResponse, errorResponse } from '../utils/cors';

export const categoryRoutes = {
  async list(request, env) {
    const categories = await env.DB.prepare(
      'SELECT id, name, slug, icon, image_url FROM categories WHERE is_active = 1 ORDER BY sort_order'
    ).all();

    return jsonResponse({ categories: categories.results || [] });
  },

  async getBySlug(request, env) {
    const { slug } = request.params;

    const category = await env.DB.prepare(
      'SELECT id, name, slug, icon, image_url FROM categories WHERE slug = ?'
    ).bind(slug).first();

    if (!category) return errorResponse('Category not found', 404);

    const products = await env.DB.prepare(
      `SELECT p.*, s.name as store_name FROM products p 
       JOIN stores s ON p.store_id = s.id 
       WHERE p.category_id = ? AND p.is_active = 1 
       ORDER BY p.total_sold DESC LIMIT 20`
    ).bind(category.id).all();

    return jsonResponse({
      ...category,
      products: products.results || []
    });
  },

  async getSubcategories(request, env) {
    const { slug } = request.params;

    const category = await env.DB.prepare(
      'SELECT id FROM categories WHERE slug = ?'
    ).bind(slug).first();

    if (!category) return errorResponse('Category not found', 404);

    const subcategories = await env.DB.prepare(
      'SELECT id, name, slug, icon FROM subcategories WHERE category_id = ? AND is_active = 1 ORDER BY sort_order'
    ).bind(category.id).all();

    return jsonResponse({ subcategories: subcategories.results || [] });
  }
};
