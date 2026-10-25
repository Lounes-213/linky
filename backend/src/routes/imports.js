import { jsonResponse, errorResponse } from '../utils/cors';

const validAliExpressUrl = (value) => { try { const url = new URL(value); return ['aliexpress.com', 'www.aliexpress.com'].includes(url.hostname) && /\/item\/\d+/.test(url.pathname) ? url.toString() : null; } catch (_) { return null; } };
const cleanText = (value, max = 5000) => String(value || '').replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, max);
const safeImages = (items) => (Array.isArray(items) ? items : []).filter((value) => { try { return new URL(value).protocol === 'https:'; } catch (_) { return false; } }).slice(0, 8);

export const importRoutes = {
  async preview(request, env) {
    const safeUrl = validAliExpressUrl((await request.json()).url);
    if (!safeUrl) return errorResponse('Use a valid AliExpress item URL', 422);
    if (!env.IMPORT_SERVICE_URL || !env.IMPORT_SERVICE_TOKEN) return errorResponse('Import service is not configured', 503);
    const upstream = await fetch(`${env.IMPORT_SERVICE_URL.replace(/\/$/, '')}/preview`, { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${env.IMPORT_SERVICE_TOKEN}` }, body: JSON.stringify({ url: safeUrl }) });
    const data = await upstream.json().catch(() => ({}));
    if (!upstream.ok) return errorResponse(data.error || 'Unable to import this product', 502);
    const product = data.product;
    return jsonResponse({ source: 'aliexpress', source_id: product.productId, title: product.title, description: cleanText(product.description), images: safeImages(product.images), orders: product.orders || '0', rating: product.ratings?.averageStar || '0', variants: product.variants || { options: [], prices: [] }, source_price: product.salePrice?.min?.value ?? null, source_currency: product.salePrice?.min?.currency ?? product.currencyInfo?.currencyCode ?? '' });
  },
  async publish(request, env) {
    const { store_id, title, description, images, category_id, subcategory_id, selling_price, stock, selected_variants = [] } = await request.json();
    const store = await env.DB.prepare('SELECT owner_id FROM stores WHERE id = ?').bind(store_id).first();
    if (!store || (store.owner_id !== request.user.uid && store.owner_id !== request.user.firebaseUid)) return errorResponse('Unauthorized', 403);
    const price = Number(selling_price);
    if (!title || !Number.isFinite(price) || price <= 0) return errorResponse('Title and selling price are required', 422);
    const id = crypto.randomUUID(); const slug = String(title).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
    await env.DB.prepare(`INSERT INTO products (id, store_id, category_id, subcategory_id, name, slug, description, base_price, images, stock, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)`).bind(id, store_id, category_id || null, subcategory_id || null, String(title).slice(0, 180), `${slug}-${id.slice(0, 6)}`, cleanText(description), price, JSON.stringify(safeImages(images)), Math.max(0, Number(stock) || 0)).run();
    for (const variant of selected_variants.slice(0, 100)) await env.DB.prepare('INSERT INTO product_variants (id, product_id, name, sku, price, stock, image_url, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, 1)').bind(crypto.randomUUID(), id, String(variant.name || 'Variant').slice(0, 120), String(variant.sku || '').slice(0, 100), Number(variant.price) || price, Math.max(0, Number(variant.stock) || 0), safeImages([variant.image])[0] || '').run();
    await env.DB.prepare('UPDATE stores SET total_products = total_products + 1 WHERE id = ?').bind(store_id).run();
    return jsonResponse({ id, slug: `${slug}-${id.slice(0, 6)}` }, 201);
  },
};
