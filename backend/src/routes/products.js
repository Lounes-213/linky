import { jsonResponse, errorResponse } from '../utils/cors';
import { deleteR2Images } from './upload.js';

export const productRoutes = {
  async list(request, env) {
    const url = new URL(request.url);
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1') || 1);
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20') || 20));
    const category = url.searchParams.get('category');
    const subcategory = url.searchParams.get('subcategory');
    const store_id = url.searchParams.get('store_id');
    const sort = url.searchParams.get('sort') || 'newest';
    const q = (url.searchParams.get('q') || '').trim().slice(0, 100);
    const minPrice = Number(url.searchParams.get('min_price'));
    const maxPrice = Number(url.searchParams.get('max_price'));
    const minRating = Number(url.searchParams.get('min_rating'));
    const inStock = url.searchParams.get('in_stock') === 'true';
    const discounted = url.searchParams.get('discounted') === 'true';
    const digital = url.searchParams.get('digital');
    const offset = (page - 1) * limit;

    let query = `SELECT p.*, s.name as store_name, s.slug as store_slug 
                 FROM products p JOIN stores s ON p.store_id = s.id 
                 WHERE p.is_active = 1`;
    const params = [];

    if (category) {
      query += ' AND p.category_id = ?';
      params.push(category);
    }
    if (subcategory) { query += ' AND p.subcategory_id = ?'; params.push(subcategory); }
    if (store_id) {
      query += ' AND p.store_id = ?';
      params.push(store_id);
    }
    if (q) { query += ' AND (lower(p.name) LIKE ? OR lower(p.description) LIKE ? OR lower(p.tags) LIKE ?)'; const term = `%${q.toLowerCase()}%`; params.push(term, term, term); }
    if (Number.isFinite(minPrice) && minPrice >= 0) { query += ' AND COALESCE(p.discount_price, p.base_price) >= ?'; params.push(minPrice); }
    if (Number.isFinite(maxPrice) && maxPrice >= 0) { query += ' AND COALESCE(p.discount_price, p.base_price) <= ?'; params.push(maxPrice); }
    if (Number.isFinite(minRating) && minRating > 0) { query += ' AND p.avg_rating >= ?'; params.push(Math.min(minRating, 5)); }
    if (inStock) query += ' AND p.stock > 0';
    if (discounted) query += ' AND p.discount_price IS NOT NULL AND p.discount_price < p.base_price';
    if (digital === 'true' || digital === 'false') { query += ' AND p.is_digital = ?'; params.push(digital === 'true' ? 1 : 0); }

    switch (sort) {
      case 'popular': query += ' ORDER BY p.total_sold DESC'; break;
      case 'rating': query += ' ORDER BY p.avg_rating DESC'; break;
      case 'price_asc': query += ' ORDER BY p.base_price ASC'; break;
      case 'price_desc': query += ' ORDER BY p.base_price DESC'; break;
      default: query += ' ORDER BY p.created_at DESC';
    }

    query += ' LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const products = await env.DB.prepare(query).bind(...params).all();
    return jsonResponse({ products: products.results || [] });
  },

  async getById(request, env) {
    const { id } = request.params;

    const product = await env.DB.prepare(
      `SELECT p.*, s.name as store_name, s.slug as store_slug, s.logo_url as store_logo,
              c.name as category_name, c.slug as category_slug
       FROM products p 
       LEFT JOIN stores s ON p.store_id = s.id 
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.id = ?`
    ).bind(id).first();

    if (!product) return errorResponse('Product not found', 404);

    const variants = await env.DB.prepare(
      'SELECT * FROM product_variants WHERE product_id = ? AND is_active = 1'
    ).bind(id).all();

    const reviews = await env.DB.prepare(
      `SELECT r.*, u.name as user_name, u.avatar_url as user_avatar 
       FROM reviews r JOIN users u ON r.user_id = u.id 
       WHERE r.product_id = ? ORDER BY r.created_at DESC LIMIT 10`
    ).bind(id).all();

    return jsonResponse({
      ...product,
      images: JSON.parse(product.images || '[]'),
      videos: JSON.parse(product.videos || '[]'),
      tags: JSON.parse(product.tags || '[]'),
      variants: variants.results || [],
      reviews: reviews.results || []
    });
  },

  async getVariants(request, env) {
    const { id } = request.params;
    const variants = await env.DB.prepare(
      'SELECT * FROM product_variants WHERE product_id = ? AND is_active = 1'
    ).bind(id).all();

    return jsonResponse({ variants: variants.results || [] });
  },

  async create(request, env) {
    const {
      store_id, category_id, subcategory_id, name, description,
      base_price, discount_price, images, videos, tags, stock,
      sku, weight, is_digital, seo_title, seo_description,
      variants, has_variants, variant_unit_type
    } = await request.json();

    if (!name || !base_price || !store_id) {
      return errorResponse('Name, price and store are required');
    }

    const store = await env.DB.prepare('SELECT owner_id FROM stores WHERE id = ?').bind(store_id).first();
    if (!store || (store.owner_id !== request.user.uid && store.owner_id !== request.user.firebaseUid)) return errorResponse('Unauthorized', 403);

    const id = crypto.randomUUID();
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

    await env.DB.prepare(
      `INSERT INTO products (id, store_id, category_id, subcategory_id, name, slug, description,
       base_price, discount_price, images, videos, tags, stock, sku, weight, is_digital,
       seo_title, seo_description, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)`
    ).bind(
      id, store_id, category_id || null, subcategory_id || null, name,
      `${slug}-${id.slice(0, 6)}`, description || '', base_price,
      discount_price || null, JSON.stringify(images || []),
      JSON.stringify(videos || []), JSON.stringify(tags || []),
      stock || 0, sku || '', weight || 0, is_digital ? 1 : 0,
      seo_title || '', seo_description || ''
    ).run();

    if (Array.isArray(variants) && variants.length > 0) {
      for (const v of variants.slice(0, 100)) {
        await env.DB.prepare(
          `INSERT INTO product_variants (id, product_id, name, type, color_hex, price_extra, price, stock, is_active)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`
        ).bind(
          crypto.randomUUID(), id,
          String(v.name || '').slice(0, 120),
          String(v.type || '').slice(0, 20),
          String(v.hex || v.color_hex || '').slice(0, 10),
          Number(v.price_modifier || v.price_extra) || 0,
          Number(v.price) || Number(base_price) || 0,
          Math.max(0, Number(v.stock) || 0)
        ).run();
      }
    }

    await env.DB.prepare(
      'UPDATE stores SET total_products = total_products + 1 WHERE id = ?'
    ).bind(store_id).run();

    return jsonResponse({ id, name, slug }, 201);
  },

  async update(request, env) {
    const { id } = request.params;
    const product = await env.DB.prepare(
      'SELECT p.store_id, p.images, s.owner_id FROM products p JOIN stores s ON p.store_id = s.id WHERE p.id = ?'
    ).bind(id).first();

    if (!product) return errorResponse('Product not found', 404);
    if (product.owner_id !== request.user.uid && product.owner_id !== request.user.firebaseUid) return errorResponse('Unauthorized', 403);

    const data = await request.json();
    const fields = ['name', 'description', 'base_price', 'discount_price', 'stock', 'is_active', 'category_id', 'subcategory_id'];
    
    let query = 'UPDATE products SET updated_at = datetime(\'now\')';
    const params = [];

    for (const field of fields) {
      if (data[field] !== undefined) {
        query += `, ${field} = ?`;
        params.push(data[field]);
      }
    }

    if (data.images) {
      let oldImages = [];
      try { oldImages = JSON.parse(product.images || '[]'); } catch (_) {}
      const newImages = Array.isArray(data.images) ? data.images : [];
      const removed = oldImages.filter(img => !newImages.includes(img));
      if (removed.length > 0) {
        await deleteR2Images(env, removed);
      }
      query += ', images = ?';
      params.push(JSON.stringify(data.images));
    }

    if (data.tags !== undefined) {
      query += ', tags = ?';
      params.push(JSON.stringify(data.tags));
    }

    query += ' WHERE id = ?';
    params.push(id);

    await env.DB.prepare(query).bind(...params).run();

    if (Array.isArray(data.variants)) {
      await env.DB.prepare('DELETE FROM product_variants WHERE product_id = ?').bind(id).run();
      for (const v of data.variants.slice(0, 100)) {
        await env.DB.prepare(
          `INSERT INTO product_variants (id, product_id, name, type, color_hex, price_extra, price, stock, is_active)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`
        ).bind(
          crypto.randomUUID(), id,
          String(v.name || '').slice(0, 120),
          String(v.type || '').slice(0, 20),
          String(v.hex || v.color_hex || '').slice(0, 10),
          Number(v.price_modifier || v.price_extra) || 0,
          Number(v.price) || Number(data.base_price) || 0,
          Math.max(0, Number(v.stock) || 0)
        ).run();
      }
    }

    return jsonResponse({ message: 'Product updated' });
  },

  async delete(request, env) {
    const { id } = request.params;
    const product = await env.DB.prepare(
      'SELECT p.store_id, p.images, s.owner_id FROM products p JOIN stores s ON p.store_id = s.id WHERE p.id = ?'
    ).bind(id).first();

    if (!product) return errorResponse('Product not found', 404);
    if (product.owner_id !== request.user.uid && product.owner_id !== request.user.firebaseUid) return errorResponse('Unauthorized', 403);

    let images = [];
    try { images = JSON.parse(product.images || '[]'); } catch (_) {}
    if (images.length > 0) {
      await deleteR2Images(env, images);
    }

    await env.DB.prepare('UPDATE products SET is_active = 0 WHERE id = ?').bind(id).run();
    await env.DB.prepare(
      'UPDATE stores SET total_products = total_products - 1 WHERE id = ?'
    ).bind(product.store_id).run();

    return jsonResponse({ message: 'Product deleted' });
  },

  async toggleFeatured(request, env) {
    const { id } = request.params;
    const product = await env.DB.prepare(
      'SELECT p.id, p.store_id, p.is_featured, s.owner_id FROM products p JOIN stores s ON p.store_id = s.id WHERE p.id = ?'
    ).bind(id).first();

    if (!product) return errorResponse('Product not found', 404);
    if (product.owner_id !== request.user.uid && product.owner_id !== request.user.firebaseUid) return errorResponse('Unauthorized', 403);

    const newFeatured = product.is_featured ? 0 : 1;

    if (newFeatured === 1) {
      const count = await env.DB.prepare(
        'SELECT COUNT(*) as cnt FROM products WHERE store_id = ? AND is_featured = 1 AND is_active = 1'
      ).bind(product.store_id).first();
      if (count && count.cnt >= 3) return errorResponse('Maximum 3 featured products per store', 422);
    }

    await env.DB.prepare('UPDATE products SET is_featured = ? WHERE id = ?').bind(newFeatured, id).run();
    return jsonResponse({ is_featured: newFeatured });
  },

  async listFeatured(request, env) {
    const url = new URL(request.url);
    const storeId = url.searchParams.get('store_id');
    if (!storeId) return errorResponse('store_id required', 400);

    const products = await env.DB.prepare(
      'SELECT id, name, slug, base_price, discount_price, images, avg_rating FROM products WHERE store_id = ? AND is_featured = 1 AND is_active = 1 ORDER BY updated_at DESC LIMIT 3'
    ).bind(storeId).all();

    return jsonResponse({ products: (products.results || []).map(p => ({ ...p, images: JSON.parse(p.images || '[]') })) });
  }
};
