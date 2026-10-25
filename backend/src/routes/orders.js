import { jsonResponse, errorResponse } from '../utils/cors';

export const orderRoutes = {
  async list(request, env) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;

    const orders = await env.DB.prepare(
      `SELECT o.*, 
              (SELECT COUNT(*) FROM order_stores WHERE order_id = o.id) as store_count
       FROM orders o WHERE o.user_id = ? ORDER BY o.created_at DESC LIMIT ? OFFSET ?`
    ).bind(request.user.uid, limit, offset).all();

    return jsonResponse({ orders: orders.results || [] });
  },

  async getById(request, env) {
    const { id } = request.params;

    const order = await env.DB.prepare(
      'SELECT * FROM orders WHERE id = ? AND user_id = ?'
    ).bind(id, request.user.uid).first();

    if (!order) return errorResponse('Order not found', 404);

    const stores = await env.DB.prepare(
      `SELECT os.*, s.name as store_name, s.logo_url as store_logo
       FROM order_stores os JOIN stores s ON os.store_id = s.id
       WHERE os.order_id = ?`
    ).bind(id).all();

    for (const store of stores.results || []) {
      store.items = await env.DB.prepare(
        'SELECT * FROM order_items WHERE order_store_id = ?'
      ).bind(store.id).all();
      store.items = store.items.results || [];
    }

    const payment = await env.DB.prepare(
      'SELECT * FROM payments WHERE order_id = ? ORDER BY created_at DESC LIMIT 1'
    ).bind(id).first();

    return jsonResponse({
      ...order,
      stores: stores.results || [],
      payment: payment || null
    });
  },

  async create(request, env) {
    const { shipping_address, payment_method, notes, coupon_code } = await request.json();
    const userId = request.user.uid;
    const allowedPaymentMethods = new Set(['cash_on_delivery', 'gold_card', 'ooredoo']);
    if (!allowedPaymentMethods.has(payment_method)) return errorResponse('Unsupported payment method', 422);

    const cart = await env.DB.prepare(
      'SELECT id FROM cart WHERE user_id = ?'
    ).bind(userId).first();

    if (!cart) return errorResponse('Cart not found', 404);

    const cartItems = await env.DB.prepare(
      `SELECT ci.*, p.name as product_name, p.images, p.base_price, p.discount_price,
              p.store_id, s.name as store_name,
              pv.price as variant_price, pv.color, pv.size
       FROM cart_items ci
       JOIN products p ON ci.product_id = p.id
       JOIN stores s ON p.store_id = s.id
       LEFT JOIN product_variants pv ON ci.variant_id = pv.id
       WHERE ci.cart_id = ?`
    ).bind(cart.id).all();

    if (!cartItems.results || cartItems.results.length === 0) {
      return errorResponse('Cart is empty');
    }

    const orderId = crypto.randomUUID();
    const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`;

    let subtotal = 0;
    const storeGroups = {};

    for (const item of cartItems.results) {
      const price = item.variant_price || item.discount_price || item.base_price;
      const itemTotal = price * item.quantity;
      subtotal += itemTotal;

      if (!storeGroups[item.store_id]) {
        storeGroups[item.store_id] = {
          id: crypto.randomUUID(),
          store_id: item.store_id,
          items: [],
          subtotal: 0
        };
      }
      storeGroups[item.store_id].items.push({
        id: crypto.randomUUID(),
        product_id: item.product_id,
        variant_id: item.variant_id,
        product_name: item.product_name,
        product_image: JSON.parse(item.images || '[]')[0] || '',
        variant_name: [item.color, item.size].filter(Boolean).join(' - '),
        quantity: item.quantity,
        price,
        total: itemTotal
      });
      storeGroups[item.store_id].subtotal += itemTotal;
    }

    const shippingCost = subtotal >= 5000 ? 0 : 500;
    const total = subtotal + shippingCost;

    await env.DB.prepare(
      `INSERT INTO orders (id, user_id, order_number, subtotal, shipping_cost, total, payment_method, notes, status, payment_status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending')`
    ).bind(orderId, userId, orderNumber, subtotal, shippingCost, total, payment_method || '', notes || '').run();

    for (const storeId of Object.keys(storeGroups)) {
      const sg = storeGroups[storeId];
      await env.DB.prepare(
        `INSERT INTO order_stores (id, order_id, store_id, subtotal, status, shipping_status)
         VALUES (?, ?, ?, ?, 'pending', 'pending')`
      ).bind(sg.id, orderId, storeId, sg.subtotal).run();

      for (const item of sg.items) {
        await env.DB.prepare(
          `INSERT INTO order_items (id, order_store_id, product_id, variant_id, product_name, product_image, variant_name, quantity, price, total)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
        ).bind(
          item.id, sg.id, item.product_id, item.variant_id,
          item.product_name, item.product_image, item.variant_name,
          item.quantity, item.price, item.total
        ).run();

        await env.DB.prepare(
          'UPDATE products SET stock = stock - ?, total_sold = total_sold + ? WHERE id = ?'
        ).bind(item.quantity, item.quantity, item.product_id).run();
      }
    }

    await env.DB.prepare(
      'INSERT INTO payments (id, order_id, amount, currency, method, status) VALUES (?, ?, ?, ?, ?, ?)'
    ).bind(crypto.randomUUID(), orderId, total, 'DA', payment_method, payment_method === 'cash_on_delivery' ? 'pending' : 'awaiting_payment').run();

    // Clear cart
    await env.DB.prepare('DELETE FROM cart_items WHERE cart_id = ?').bind(cart.id).run();

    // Create notifications for stores
    for (const storeId of Object.keys(storeGroups)) {
      const store = await env.DB.prepare('SELECT owner_id FROM stores WHERE id = ?').bind(storeId).first();
      if (store) {
        await env.DB.prepare(
          `INSERT INTO notifications (id, user_id, type, title, body, data)
           VALUES (?, ?, 'new_order', 'Nouvelle commande', ?, ?)`
        ).bind(
          crypto.randomUUID(), store.owner_id,
          `Commande ${orderNumber} reçue`,
          JSON.stringify({ order_id: orderId, order_number: orderNumber })
        ).run();
      }
    }

    return jsonResponse({
      id: orderId,
      order_number: orderNumber,
      subtotal,
      shipping_cost: shippingCost,
      total
    }, 201);
  },

  async updateStatus(request, env) {
    const { id } = request.params;
    const { status } = await request.json();

    await env.DB.prepare(
      `UPDATE orders SET status = ?, updated_at = datetime('now') WHERE id = ?`
    ).bind(status, id).run();

    const order = await env.DB.prepare('SELECT user_id, order_number FROM orders WHERE id = ?').bind(id).first();
    if (order) {
      await env.DB.prepare(
        `INSERT INTO notifications (id, user_id, type, title, body, data)
         VALUES (?, ?, 'order_update', 'Commande mise à jour', ?, ?)`
      ).bind(
        crypto.randomUUID(), order.user_id,
        `Votre commande ${order.order_number} est maintenant: ${status}`,
        JSON.stringify({ order_id: id, status })
      ).run();
    }

    return jsonResponse({ message: 'Order status updated' });
  },

  async getTracking(request, env) {
    const { id } = request.params;

    const orderStore = await env.DB.prepare(
      `SELECT os.*, s.name as store_name FROM order_stores os 
       JOIN stores s ON os.store_id = s.id WHERE os.order_id = ?`
    ).bind(id).all();

    const shipping = [];
    for (const os of orderStore.results || []) {
      const s = await env.DB.prepare(
        'SELECT * FROM shipping WHERE order_store_id = ?'
      ).bind(os.id).first();
      if (s) shipping.push({ ...os, shipping: s });
    }

    return jsonResponse({ tracking: shipping });
  },

  // Public order from website (no auth required)
  async createPublic(request, env) {
    const data = await request.json();
    const {
      store_id, store_name,
      customer_name, customer_phone,
      wilaya, wilaya_name, commune, address, notes,
      items, subtotal, delivery, total
    } = data;

    if (!customer_name || !customer_phone || !wilaya || !commune || !address || !items?.length) {
      return errorResponse('Données incomplètes');
    }

    const orderId = crypto.randomUUID();
    const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`;

    // Create order in D1
    await env.DB.prepare(
      `INSERT INTO orders (id, order_number, subtotal, shipping_cost, total, payment_method, notes, status, payment_status)
       VALUES (?, ?, ?, ?, ?, 'cash_on_delivery', ?, 'pending', 'pending')`
    ).bind(orderId, orderNumber, subtotal, delivery, total, notes || '').run();

    if (store_id) {
      const storeOrderId = crypto.randomUUID();
      await env.DB.prepare(
        `INSERT INTO order_stores (id, order_id, store_id, subtotal, status, shipping_status)
         VALUES (?, ?, ?, ?, 'pending', 'pending')`
      ).bind(storeOrderId, orderId, store_id, subtotal).run();

      for (const item of items) {
        await env.DB.prepare(
          `INSERT INTO order_items (id, order_store_id, product_id, product_name, variant_name, quantity, price, total)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        ).bind(
          crypto.randomUUID(), storeOrderId, item.product_id || '',
          item.name, item.selected_size || '',
          item.quantity, item.price, item.price * item.quantity
        ).run();
      }
    }

    // Send SMS to store phone
    const store = store_id ? await env.DB.prepare('SELECT phone FROM stores WHERE id = ?').bind(store_id).first() : null;
    const storePhone = store?.phone || '';

    if (storePhone && env.SMS_API_KEY) {
      try {
        const itemsList = items.map(i => `${i.name} x${i.quantity} = ${i.price * i.quantity} DA`).join('%0A');
        const message = [
          `📦 NOUVELLE COMMANDE — ${store_name || 'Boutique'}`,
          `Commande: ${orderNumber}`,
          ``,
          `👤 Client: ${customer_name}`,
          `📞 Tél: ${customer_phone}`,
          `📍 ${address}, ${commune}, ${wilaya_name}`,
          notes ? `📝 Notes: ${notes}` : '',
          ``,
          `--- Articles ---`,
          ...items.map(i => `• ${i.name} x${i.quantity} — ${i.price * i.quantity} DA`),
          ``,
          `Livraison: ${delivery} DA`,
          `💰 TOTAL: ${total} DA`,
        ].filter(Boolean).join('\n');

        await fetch(`https://api.sms.to/v1/sms/send`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.SMS_API_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            to: storePhone.startsWith('+') ? storePhone : `+213${storePhone.replace(/^0/, '')}`,
            body: message,
            sender: 'Linky'
          })
        });
      } catch (e) {
        console.log('SMS failed:', e.message);
      }
    }

    return jsonResponse({
      id: orderId,
      order_number: orderNumber,
      total,
      message: 'Commande enregistrée'
    }, 201);
  },
};
