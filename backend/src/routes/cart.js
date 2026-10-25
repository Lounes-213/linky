import { jsonResponse, errorResponse } from '../utils/cors';

export const cartRoutes = {
  async get(request, env) {
    const cart = await env.DB.prepare(
      'SELECT id FROM cart WHERE user_id = ?'
    ).bind(request.user.uid).first();

    if (!cart) {
      const cartId = crypto.randomUUID();
      await env.DB.prepare('INSERT INTO cart (id, user_id) VALUES (?, ?)').bind(cartId, request.user.uid).run();
      return jsonResponse({ id: cartId, items: [] });
    }

    const items = await env.DB.prepare(
      `SELECT ci.*, p.name as product_name, p.images, p.base_price, p.discount_price,
              s.name as store_name, s.id as store_id,
              pv.color, pv.size, pv.image_url as variant_image, pv.price as variant_price
       FROM cart_items ci
       JOIN products p ON ci.product_id = p.id
       JOIN stores s ON p.store_id = s.id
       LEFT JOIN product_variants pv ON ci.variant_id = pv.id
       WHERE ci.cart_id = ?`
    ).bind(cart.id).all();

    const parsedItems = (items.results || []).map(item => ({
      ...item,
      images: JSON.parse(item.images || '[]'),
      price: item.variant_price || item.discount_price || item.base_price
    }));

    const total = parsedItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);

    return jsonResponse({
      id: cart.id,
      items: parsedItems,
      item_count: parsedItems.length,
      total
    });
  },

  async addItem(request, env) {
    const { product_id, variant_id, quantity = 1 } = await request.json();

    if (!product_id) return errorResponse('Product ID required');

    const cart = await env.DB.prepare(
      'SELECT id FROM cart WHERE user_id = ?'
    ).bind(request.user.uid).first();

    if (!cart) return errorResponse('Cart not found', 404);

    const existing = await env.DB.prepare(
      'SELECT id, quantity FROM cart_items WHERE cart_id = ? AND product_id = ? AND variant_id IS ?'
    ).bind(cart.id, product_id, variant_id || null).first();

    if (existing) {
      await env.DB.prepare(
        'UPDATE cart_items SET quantity = quantity + ? WHERE id = ?'
      ).bind(quantity, existing.id).run();
    } else {
      await env.DB.prepare(
        'INSERT INTO cart_items (id, cart_id, product_id, variant_id, quantity) VALUES (?, ?, ?, ?, ?)'
      ).bind(crypto.randomUUID(), cart.id, product_id, variant_id || null, quantity).run();
    }

    return jsonResponse({ message: 'Item added to cart' });
  },

  async updateItem(request, env) {
    const { id } = request.params;
    const { quantity } = await request.json();

    if (quantity <= 0) {
      await env.DB.prepare('DELETE FROM cart_items WHERE id = ?').bind(id).run();
    } else {
      await env.DB.prepare('UPDATE cart_items SET quantity = ? WHERE id = ?').bind(quantity, id).run();
    }

    return jsonResponse({ message: 'Cart updated' });
  },

  async removeItem(request, env) {
    const { id } = request.params;
    await env.DB.prepare('DELETE FROM cart_items WHERE id = ?').bind(id).run();
    return jsonResponse({ message: 'Item removed' });
  },

  async clear(request, env) {
    const cart = await env.DB.prepare(
      'SELECT id FROM cart WHERE user_id = ?'
    ).bind(request.user.uid).first();

    if (cart) {
      await env.DB.prepare('DELETE FROM cart_items WHERE cart_id = ?').bind(cart.id).run();
    }

    return jsonResponse({ message: 'Cart cleared' });
  }
};
