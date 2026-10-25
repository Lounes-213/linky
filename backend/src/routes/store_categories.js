import { jsonResponse, errorResponse } from '../utils/cors';

export const storeCategoryRoutes = {
  async list(request, env) {
    const url = new URL(request.url);
    const storeId = url.searchParams.get('store_id');
    if (!storeId) return errorResponse('store_id required', 400);

    const categories = await env.DB.prepare(
      'SELECT id, store_id, name, icon_code, color_val, sort_order FROM store_categories WHERE store_id = ? AND is_active = 1 ORDER BY sort_order'
    ).bind(storeId).all();

    return jsonResponse({ categories: categories.results || [] });
  },

  async create(request, env) {
    const { store_id, name, color_val, frame_style } = await request.json();
    if (!store_id || !name) return errorResponse('store_id and name required');

    const store = await env.DB.prepare('SELECT owner_id FROM stores WHERE id = ?').bind(store_id).first();
    if (!store || (store.owner_id !== request.user.uid && store.owner_id !== request.user.firebaseUid)) return errorResponse('Unauthorized', 403);

    const maxOrder = await env.DB.prepare('SELECT MAX(sort_order) as max_order FROM store_categories WHERE store_id = ?').bind(store_id).first();
    const nextOrder = (maxOrder?.max_order ?? -1) + 1;

    const id = crypto.randomUUID();
    await env.DB.prepare(
      'INSERT INTO store_categories (id, store_id, name, color_val, frame_style, sort_order) VALUES (?, ?, ?, ?, ?, ?)'
    ).bind(id, store_id, name, color_val ?? 34762495, frame_style ?? 'filled', nextOrder).run();

    return jsonResponse({ id, name, color_val: color_val ?? 34762495, frame_style: frame_style ?? 'filled', sort_order: nextOrder }, 201);
  },

  async update(request, env) {
    const { id } = request.params;
    const body = await request.json();
    const cat = await env.DB.prepare(
      'SELECT sc.id, sc.store_id, s.owner_id FROM store_categories sc JOIN stores s ON sc.store_id = s.id WHERE sc.id = ?'
    ).bind(id).first();

    if (!cat) return errorResponse('Category not found', 404);
    if (cat.owner_id !== request.user.uid && cat.owner_id !== request.user.firebaseUid) return errorResponse('Unauthorized', 403);

    const sets = [];
    const params = [];
    if (body.name !== undefined) { sets.push('name = ?'); params.push(body.name); }
    if (body.color_val !== undefined) { sets.push('color_val = ?'); params.push(body.color_val); }
    if (body.frame_style !== undefined) { sets.push('frame_style = ?'); params.push(body.frame_style); }
    if (sets.length === 0) return errorResponse('Nothing to update');

    params.push(id);
    await env.DB.prepare(`UPDATE store_categories SET ${sets.join(', ')} WHERE id = ?`).bind(...params).run();
    return jsonResponse({ message: 'Updated' });
  },

  async delete(request, env) {
    const { id } = request.params;
    const cat = await env.DB.prepare(
      'SELECT sc.id, sc.store_id, s.owner_id FROM store_categories sc JOIN stores s ON sc.store_id = s.id WHERE sc.id = ?'
    ).bind(id).first();

    if (!cat) return errorResponse('Category not found', 404);
    if (cat.owner_id !== request.user.uid && cat.owner_id !== request.user.firebaseUid) return errorResponse('Unauthorized', 403);

    await env.DB.prepare('UPDATE store_categories SET is_active = 0 WHERE id = ?').bind(id).run();
    return jsonResponse({ message: 'Deleted' });
  },

  async reorder(request, env) {
    const { store_id, order } = await request.json();
    if (!store_id || !Array.isArray(order)) return errorResponse('store_id and order array required');

    const store = await env.DB.prepare('SELECT owner_id FROM stores WHERE id = ?').bind(store_id).first();
    if (!store || (store.owner_id !== request.user.uid && store.owner_id !== request.user.firebaseUid)) return errorResponse('Unauthorized', 403);

    for (let i = 0; i < order.length; i++) {
      await env.DB.prepare('UPDATE store_categories SET sort_order = ? WHERE id = ? AND store_id = ?')
        .bind(i, order[i], store_id).run();
    }
    return jsonResponse({ message: 'Reordered' });
  }
};
