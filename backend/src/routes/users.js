import { jsonResponse, errorResponse } from '../utils/cors';
import { deleteR2Images } from './upload.js';

const allowedPlatforms = new Set(['instagram', 'tiktok', 'youtube', 'facebook', 'linkedin', 'whatsapp', 'website', 'twitter', 'telegram', 'snapchat', 'pinterest']);

function validHttpUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' || url.protocol === 'http:' ? url.toString() : null;
  } catch (_) {
    return null;
  }
}

function buildSocialUrl(platform, username) {
  if (!username) return null;
  const u = username.replace(/^@/, '');
  switch (platform) {
    case 'instagram': return `https://instagram.com/${u}`;
    case 'facebook': return `https://facebook.com/${u}`;
    case 'youtube': return `https://youtube.com/@${u}`;
    case 'linkedin': return `https://linkedin.com/in/${u}`;
    case 'whatsapp': return `https://wa.me/${u.replace(/[^0-9+]/g, '')}`;
    case 'tiktok': return `https://tiktok.com/@${u}`;
    case 'twitter': return `https://x.com/${u}`;
    case 'telegram': return `https://t.me/${u}`;
    case 'snapchat': return `https://snapchat.com/add/${u}`;
    case 'pinterest': return `https://pinterest.com/${u}`;
    case 'website': return `https://${u}`;
    default: return `https://${u}`;
  }
}

function managedImageUrl(value, env) {
  if (!value) return null;
  try {
    const image = new URL(value);
    const publicBase = env.IMAGE_PUBLIC_BASE_URL ? new URL(env.IMAGE_PUBLIC_BASE_URL) : null;
    const isCloudflareR2 = image.hostname.endsWith('.r2.cloudflarestorage.com') || image.hostname.endsWith('.r2.dev');
    const isConfiguredPublicHost = publicBase && image.origin === publicBase.origin;
    const isWorkerApiImage = image.pathname.startsWith('/api/images/');
    const isGmailPhoto = image.hostname.includes('googleusercontent.com') || image.hostname.includes('google.com');
    return image.protocol === 'https:' && (isCloudflareR2 || isConfiguredPublicHost || isWorkerApiImage || isGmailPhoto) ? image.toString() : null;
  } catch (_) {
    return null;
  }
}

function isR2ManagedUrl(value, env) {
  if (!value) return false;
  try {
    const image = new URL(value);
    const publicBase = env.IMAGE_PUBLIC_BASE_URL ? new URL(env.IMAGE_PUBLIC_BASE_URL) : null;
    return image.pathname.startsWith('/api/images/') ||
           image.hostname.endsWith('.r2.dev') ||
           image.hostname.endsWith('.r2.cloudflarestorage.com') ||
           (publicBase && image.origin === publicBase.origin);
  } catch (_) {
    return false;
  }
}

export const userRoutes = {
  async me(request, env) {
    const user = await env.DB.prepare(
      'SELECT id, email, name, username, bio, avatar_url, phone, location, website, is_verified, is_admin, created_at, theme_settings FROM users WHERE firebase_uid = ?'
    ).bind(request.user.firebaseUid).first();

    if (!user) return errorResponse('User not found', 404);

    const socialLinks = await env.DB.prepare(
      'SELECT id, platform, username, url, is_active FROM social_links WHERE user_id = ? ORDER BY sort_order'
    ).bind(user.id).all();

    const addresses = await env.DB.prepare(
      'SELECT * FROM user_addresses WHERE user_id = ? ORDER BY is_default DESC'
    ).bind(user.id).all();

    return jsonResponse({
      ...user,
      social_links: socialLinks.results || [],
      addresses: addresses.results || []
    });
  },

  async updateMe(request, env) {
    const { name, bio, phone, location, website, username, photoUrl, avatar_url, theme_settings } = await request.json();
    const userId = request.user.firebaseUid;
    const avatarUrl = photoUrl ?? avatar_url;
    const safeAvatarUrl = avatarUrl == null ? null : managedImageUrl(avatarUrl, env);
    if (avatarUrl != null && !safeAvatarUrl) return errorResponse('Profile image must be a Linky Cloudflare image URL', 422);

    if (avatarUrl != null && safeAvatarUrl) {
      const current = await env.DB.prepare('SELECT avatar_url FROM users WHERE firebase_uid = ?').bind(userId).first();
      if (current && current.avatar_url && current.avatar_url !== safeAvatarUrl && isR2ManagedUrl(current.avatar_url, env)) {
        await deleteR2Images(env, [current.avatar_url]);
      }
    }

    const existing = await env.DB.prepare(
      'SELECT id FROM users WHERE username = ? AND firebase_uid != ?'
    ).bind(username ?? null, userId).first();

    if (existing) return errorResponse('Username already taken');

    await env.DB.prepare(
      `UPDATE users SET name = COALESCE(?, name), bio = COALESCE(?, bio), phone = COALESCE(?, phone),
       location = COALESCE(?, location), website = COALESCE(?, website), username = COALESCE(?, username),
       avatar_url = COALESCE(?, avatar_url), theme_settings = COALESCE(?, theme_settings),
       updated_at = datetime('now') WHERE firebase_uid = ?`
    ).bind(
      name ?? null, 
      bio ?? null, 
      phone ?? null, 
      location ?? null, 
      website ?? null, 
      username ?? null, 
      safeAvatarUrl ?? null, 
      theme_settings ?? null, 
      request.user.firebaseUid
    ).run();

    return jsonResponse({ message: 'Profile updated' });
  },

  async profile(request, env) {
    return userRoutes.me(request, env);
  },

  async updateProfile(request, env) {
    return userRoutes.updateMe(request, env);
  },

  async getById(request, env) {
    const { id } = request.params;
    const user = await env.DB.prepare(
      'SELECT id, name, username, bio, avatar_url, location, is_verified, created_at FROM users WHERE id = ?'
    ).bind(id).first();

    if (!user) return errorResponse('User not found', 404);

    const stores = await env.DB.prepare(
      'SELECT id, name, slug, logo_url, rating, total_products FROM stores WHERE owner_id = ?'
    ).bind(id).all();

    const followersCount = await env.DB.prepare(
      'SELECT COUNT(*) as count FROM store_followers WHERE user_id = ?'
    ).bind(id).first();

    return jsonResponse({
      ...user,
      stores: stores.results || [],
      followers_count: followersCount?.count || 0
    });
  },

  async getStores(request, env) {
    const { id } = request.params;
    const stores = await env.DB.prepare(
      'SELECT id, name, slug, description, logo_url, cover_url, rating, total_products, total_followers FROM stores WHERE owner_id = ?'
    ).bind(id).all();

    return jsonResponse({ stores: stores.results || [] });
  },

  async getProducts(request, env) {
    const { id } = request.params;
    const products = await env.DB.prepare(
      'SELECT p.*, s.name as store_name FROM products p JOIN stores s ON p.store_id = s.id WHERE s.owner_id = ? ORDER BY p.created_at DESC'
    ).bind(id).all();

    return jsonResponse({ products: products.results || [] });
  },

  async addSocialLink(request, env) {
    const { platform, username, url } = await request.json();
    const safePlatform = String(platform || '').toLowerCase();
    const safeUsername = String(username || '').trim().replace(/^@/, '').slice(0, 100);
    if (!allowedPlatforms.has(safePlatform)) return errorResponse('Invalid platform');
    if (!safeUsername && !url) return errorResponse('Username or URL is required');

    let safeUrl = validHttpUrl(String(url || '').trim());
    if (!safeUrl && safeUsername) safeUrl = buildSocialUrl(safePlatform, safeUsername);
    if (!safeUrl) return errorResponse('Invalid URL or username');

    const userId = request.user.uid;
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM social_links WHERE user_id = ?').bind(userId).first();
    if ((count?.count || 0) >= 12) return errorResponse('Maximum of 12 social links reached', 422);
    const id = crypto.randomUUID();

    await env.DB.prepare(
      'INSERT INTO social_links (id, user_id, platform, username, url) VALUES (?, ?, ?, ?, ?)'
    ).bind(id, userId, safePlatform, safeUsername, safeUrl).run();

    return jsonResponse({ id, platform: safePlatform, username: safeUsername, url: safeUrl }, 201);
  },

  async removeSocialLink(request, env) {
    const { id } = request.params;
    const userId = request.user.uid;

    await env.DB.prepare(
      'DELETE FROM social_links WHERE id = ? AND user_id = ?'
    ).bind(id, userId).run();

    return jsonResponse({ message: 'Social link removed' });
  },

  async updateSocialLink(request, env) {
    const { id } = request.params;
    const { platform, username, url } = await request.json();
    const safePlatform = String(platform || '').toLowerCase();
    const safeUsername = String(username || '').trim().replace(/^@/, '').slice(0, 100);
    if (!allowedPlatforms.has(safePlatform)) return errorResponse('Invalid platform');
    if (!safeUsername && !url) return errorResponse('Username or URL is required');

    let safeUrl = validHttpUrl(String(url || '').trim());
    if (!safeUrl && safeUsername) safeUrl = buildSocialUrl(safePlatform, safeUsername);
    if (!safeUrl) return errorResponse('Invalid URL or username');

    const userId = request.user.uid;
    await env.DB.prepare(
      'UPDATE social_links SET platform = ?, username = ?, url = ? WHERE id = ? AND user_id = ?'
    ).bind(safePlatform, safeUsername, safeUrl, id, userId).run();

    return jsonResponse({ id, platform: safePlatform, username: safeUsername, url: safeUrl });
  }
};
