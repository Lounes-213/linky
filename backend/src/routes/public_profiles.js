import { jsonResponse, errorResponse } from '../utils/cors';

const safeUrl = (value) => {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' || url.protocol === 'http:' ? url.toString() : null;
  } catch (_) {
    return null;
  }
};

const managedImageUrl = (value, env) => {
  const url = safeUrl(value);
  if (!url) return null;
  const parsed = new URL(url);
  const configuredHost = env.IMAGE_PUBLIC_BASE_URL ? new URL(env.IMAGE_PUBLIC_BASE_URL).hostname : '';
  return parsed.pathname.startsWith('/api/images/') ||
         parsed.hostname.endsWith('.r2.cloudflarestorage.com') ||
         parsed.hostname.endsWith('.r2.dev') ||
         parsed.hostname === configuredHost ||
         parsed.hostname.includes('googleusercontent.com') ||
         parsed.hostname.includes('google.com') ? url : null;
};

async function portfolioWithImages(env, userId, onlyActive = false) {
  const projects = await env.DB.prepare(`SELECT * FROM portfolio_projects WHERE user_id = ? ${onlyActive ? 'AND is_active = 1' : ''} ORDER BY sort_order, created_at DESC`).bind(userId).all();
  const items = projects.results || [];
  if (!items.length) return [];
  const ids = items.map((p) => p.id);
  const placeholders = ids.map(() => '?').join(',');
  const images = await env.DB.prepare(`SELECT project_id, image_url, sort_order FROM portfolio_images WHERE project_id IN (${placeholders}) ORDER BY sort_order`).bind(...ids).all();
  const byProject = new Map();
  for (const image of images.results || []) {
    byProject.set(image.project_id, [...(byProject.get(image.project_id) || []), image.image_url]);
  }
  return items.map((project) => ({ ...project, images: byProject.get(project.id) || [] }));
}

export const publicProfileRoutes = {
  async get(request, env) {
    const rawParam = request.params.username || '';
    const cleanUsername = decodeURIComponent(rawParam).trim().replace(/^@+/, '');

    let user = await env.DB.prepare(
      'SELECT id, name, username, bio, avatar_url, location, website, is_verified, created_at, country, state, theme_settings FROM users WHERE lower(username) = lower(?) AND is_private = 0'
    ).bind(cleanUsername).first();

    if (!user) {
      user = await env.DB.prepare(
        'SELECT id, name, username, bio, avatar_url, location, website, is_verified, created_at, country, state, theme_settings FROM users WHERE id = ? OR lower(email) LIKE ?'
      ).bind(cleanUsername, `%${cleanUsername}%`).first();
    }

    if (!user) {
      // Graceful fallback for new users who haven't saved username in DB yet
      user = {
        id: cleanUsername,
        name: cleanUsername.replace(/[-_]/g, ' '),
        username: cleanUsername,
        bio: 'Bienvenue sur ma page Linky !',
        avatar_url: '',
        location: '',
        website: '',
        is_verified: 1,
        created_at: new Date().toISOString(),
        country: 'Algeria',
        state: '',
        theme_settings: '{}'
      };
    }

    const [links, socials, stores, products, portfolio, sections, followersCount, projectsCount, stories] = await Promise.all([
      env.DB.prepare('SELECT id, title, url, icon, clicks_count FROM profile_links WHERE user_id = ? AND is_active = 1 ORDER BY sort_order, created_at').bind(user.id).all(),
      env.DB.prepare('SELECT platform, username, url FROM social_links WHERE user_id = ? AND is_active = 1 ORDER BY sort_order').bind(user.id).all(),
      env.DB.prepare(`SELECT id, name, slug, description, logo_url, cover_url, category, city, is_verified, is_active,
        total_products, total_followers, total_reviews, rating, primary_color, settings, social_links
        FROM stores WHERE owner_id = ? ORDER BY total_followers DESC LIMIT 6`).bind(user.id).all(),
      env.DB.prepare(`SELECT p.id, p.name, p.slug, p.base_price, p.discount_price, p.currency, p.images, s.name AS store_name
        FROM products p JOIN stores s ON s.id = p.store_id WHERE s.owner_id = ? AND p.is_active = 1 AND p.is_featured = 1 LIMIT 8`).bind(user.id).all(),
      portfolioWithImages(env, user.id, true),
      env.DB.prepare('SELECT section_key, is_visible, sort_order FROM profile_sections WHERE user_id = ? ORDER BY sort_order').bind(user.id).all(),
      env.DB.prepare('SELECT COUNT(*) as count FROM store_followers sf JOIN stores s ON s.id = sf.store_id WHERE s.owner_id = ?').bind(user.id).first(),
      env.DB.prepare('SELECT COUNT(*) as count FROM portfolio_projects WHERE user_id = ? AND is_active = 1').bind(user.id).first(),
      env.DB.prepare("SELECT id, media_url, media_type, caption, created_at FROM stories WHERE user_id = ? AND expires_at > datetime('now') ORDER BY created_at DESC").bind(user.id).all(),
    ]);

    const sectionOrder = (sections.results || []).map((s) => ({ key: s.section_key, visible: s.is_visible === 1, order: s.sort_order }));

    return jsonResponse({
      ...user,
      country: user.country || '',
      state: user.state || '',
      theme_settings: user.theme_settings ? (typeof user.theme_settings === 'string' ? JSON.parse(user.theme_settings) : user.theme_settings) : {},
      links: links.results || [],
      social_links: socials.results || [],
      stores: (stores.results || []).map((s) => ({
        ...s,
        settings: s.settings ? (typeof s.settings === 'string' ? JSON.parse(s.settings) : s.settings) : {},
        social_links: s.social_links ? (typeof s.social_links === 'string' ? JSON.parse(s.social_links) : s.social_links) : {},
      })),
      featured_products: products.results || [],
      portfolio,
      section_order: sectionOrder,
      followers_count: followersCount?.count || 0,
      projects_count: projectsCount?.count || 0,
      stories: stories.results || [],
    });
  },

  async click(request, env) {
    const { username, id } = request.params;
    const owner = await env.DB.prepare('SELECT id FROM users WHERE lower(username) = lower(?) AND is_private = 0').bind(username).first();
    if (!owner) return errorResponse('Profile not found', 404);
    const result = await env.DB.prepare('UPDATE profile_links SET clicks_count = clicks_count + 1 WHERE id = ? AND user_id = ? AND is_active = 1').bind(id, owner.id).run();
    if (!result.meta?.changes) return errorResponse('Link not found', 404);
    return jsonResponse({ ok: true });
  },
};

export const creatorRoutes = {
  async listLinks(request, env) {
    const userId = request.user.uid;
    const links = await env.DB.prepare('SELECT * FROM profile_links WHERE user_id = ? ORDER BY sort_order, created_at').bind(userId).all();
    return jsonResponse({ links: links.results || [] });
  },
  async createLink(request, env) {
    const userId = request.user.uid;
    const body = await request.json();
    const title = String(body.title || '').trim().slice(0, 80);
    const url = safeUrl(String(body.url || '').trim());
    const imageUrl = body.image_url ? managedImageUrl(String(body.image_url), env) : '';
    if (!title || !url) return errorResponse('A title and valid HTTP(S) URL are required');
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM profile_links WHERE user_id = ?').bind(userId).first();
    if ((count?.count || 0) >= 30) return errorResponse('Maximum of 30 profile links reached', 422);
    const id = crypto.randomUUID();
    await env.DB.prepare('INSERT INTO profile_links (id, user_id, title, url, icon, image_url, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?)')
      .bind(id, userId, title, url, String(body.icon || 'link').slice(0, 30), imageUrl || '', count?.count || 0).run();
    return jsonResponse({ id, title, url, image_url: imageUrl || '' }, 201);
  },
  async updateLink(request, env) {
    const userId = request.user.uid;
    const body = await request.json();
    const title = body.title == null ? null : String(body.title).trim().slice(0, 80);
    const url = body.url == null ? null : safeUrl(String(body.url).trim());
    const imageUrl = body.image_url != null ? (body.image_url ? managedImageUrl(String(body.image_url), env) : '') : null;
    if (body.url != null && !url) return errorResponse('Valid HTTP(S) URL required');
    if (body.image_url != null && body.image_url && !imageUrl) return errorResponse('Invalid image URL');
    await env.DB.prepare(`UPDATE profile_links SET title = COALESCE(?, title), url = COALESCE(?, url), image_url = COALESCE(?, image_url), is_active = COALESCE(?, is_active), sort_order = COALESCE(?, sort_order), updated_at = datetime('now') WHERE id = ? AND user_id = ?`)
      .bind(title, url, imageUrl, typeof body.is_active === 'boolean' ? Number(body.is_active) : null, Number.isInteger(body.sort_order) ? body.sort_order : null, request.params.id, userId).run();
    return jsonResponse({ ok: true });
  },
  async deleteLink(request, env) {
    const userId = request.user.uid;
    await env.DB.prepare('DELETE FROM profile_links WHERE id = ? AND user_id = ?').bind(request.params.id, userId).run();
    return jsonResponse({ ok: true });
  },
  async portfolio(request, env) {
    const userId = request.user.uid;
    return jsonResponse({ projects: await portfolioWithImages(env, userId) });
  },
  async createPortfolioProject(request, env) {
    const userId = request.user.uid;
    const body = await request.json();
    const title = String(body.title || '').trim().slice(0, 100);
    const keywords = String(body.keywords || '').trim().slice(0, 300);
    const imageUrls = Array.isArray(body.images) ? body.images : [];
    if (imageUrls.length > 5) return errorResponse('A project can contain at most 5 images', 422);
    const images = imageUrls.map((image) => managedImageUrl(String(image), env));
    const rawUrl = body.project_url || body.url || body.link || '';
    const projectUrl = rawUrl ? safeUrl(String(rawUrl)) : '';
    if (!title || images.some((image) => !image) || (rawUrl && !projectUrl)) return errorResponse('Project title or URL is invalid');
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM portfolio_projects WHERE user_id = ?').bind(userId).first();
    if ((count?.count || 0) >= 20) return errorResponse('Maximum of 20 projects reached', 422);
    const id = crypto.randomUUID();
    await env.DB.prepare('INSERT INTO portfolio_projects (id, user_id, title, description, image_url, project_url, category, keywords, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)')
      .bind(id, userId, title, String(body.description || '').slice(0, 500), images[0] || '', projectUrl, String(body.category || '').slice(0, 50), keywords, count?.count || 0).run();
    for (let index = 0; index < images.length; index++) {
      await env.DB.prepare('INSERT INTO portfolio_images (id, project_id, image_url, sort_order) VALUES (?, ?, ?, ?)').bind(crypto.randomUUID(), id, images[index], index).run();
    }
    return jsonResponse({ id, images }, 201);
  },
  async updatePortfolioProject(request, env) {
    const userId = request.user.uid;
    const body = await request.json();
    const title = body.title == null ? null : String(body.title).trim().slice(0, 100);
    const description = body.description == null ? null : String(body.description).slice(0, 500);
    const keywords = body.keywords == null ? null : String(body.keywords).trim().slice(0, 300);
    const rawUrl = body.project_url ?? body.url ?? body.link ?? null;
    const projectUrl = rawUrl != null ? (rawUrl ? safeUrl(String(rawUrl)) : '') : null;
    const category = body.category == null ? null : String(body.category).slice(0, 50);
    const isActive = typeof body.is_active === 'boolean' ? Number(body.is_active) : null;
    const sortOrder = Number.isInteger(body.sort_order) ? body.sort_order : null;

    let imageUrl = null;
    if (body.image_url != null) {
      imageUrl = body.image_url ? managedImageUrl(String(body.image_url), env) : '';
      if (body.image_url && !imageUrl) return errorResponse('Invalid image URL');
    }

    const existing = await env.DB.prepare('SELECT id, image_url FROM portfolio_projects WHERE id = ? AND user_id = ?').bind(request.params.id, userId).first();
    if (!existing) return errorResponse('Project not found', 404);

    await env.DB.prepare(
      `UPDATE portfolio_projects SET
        title = COALESCE(?, title),
        description = COALESCE(?, description),
        project_url = COALESCE(?, project_url),
        category = COALESCE(?, category),
        image_url = COALESCE(?, image_url),
        keywords = COALESCE(?, keywords),
        is_active = COALESCE(?, is_active),
        sort_order = COALESCE(?, sort_order)
       WHERE id = ? AND user_id = ?`
    ).bind(title, description, projectUrl, category, imageUrl, keywords, isActive, sortOrder, request.params.id, userId).run();

    if (imageUrl !== null && imageUrl !== existing.image_url) {
      await env.DB.prepare('DELETE FROM portfolio_images WHERE project_id = ?').bind(request.params.id).run();
      if (imageUrl) {
        await env.DB.prepare('INSERT INTO portfolio_images (id, project_id, image_url, sort_order) VALUES (?, ?, ?, 0)').bind(crypto.randomUUID(), request.params.id, imageUrl).run();
      }
    }

    return jsonResponse({ ok: true });
  },
  async deletePortfolioProject(request, env) {
    const userId = request.user.uid;
    const project = await env.DB.prepare('SELECT id, image_url FROM portfolio_projects WHERE id = ? AND user_id = ?').bind(request.params.id, userId).first();
    if (project) {
      await env.DB.prepare('DELETE FROM portfolio_images WHERE project_id = ?').bind(request.params.id).run();
    }
    await env.DB.prepare('DELETE FROM portfolio_projects WHERE id = ? AND user_id = ?').bind(request.params.id, userId).run();
    return jsonResponse({ ok: true });
  },
  async updateSections(request, env) {
    const userId = request.user.uid;
    const { sections } = await request.json();
    if (!Array.isArray(sections)) return errorResponse('sections must be an array');
    for (let i = 0; i < sections.length; i++) {
      const s = sections[i];
      if (!s.key) continue;
      await env.DB.prepare(
        `INSERT INTO profile_sections (id, user_id, section_key, is_visible, sort_order)
         VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(user_id, section_key) DO UPDATE SET is_visible = excluded.is_visible, sort_order = excluded.sort_order`
      ).bind(crypto.randomUUID(), userId, s.key, s.visible ? 1 : 0, i).run();
    }
    return jsonResponse({ ok: true });
  },
  async automations(request, env) {
    const userId = request.user.uid;
    if (request.method === 'GET') {
      const rules = await env.DB.prepare('SELECT type, is_active, config FROM automation_rules WHERE user_id = ? ORDER BY type').bind(userId).all();
      return jsonResponse({ rules: rules.results || [] });
    }
    const { type, is_active, config } = await request.json();
    if (!['welcome_message', 'low_stock', 'order_update'].includes(type) || typeof is_active !== 'boolean') return errorResponse('Invalid automation rule');
    await env.DB.prepare(`INSERT INTO automation_rules (id, user_id, type, is_active, config) VALUES (?, ?, ?, ?, ?) ON CONFLICT(user_id, type) DO UPDATE SET is_active = excluded.is_active, config = excluded.config, updated_at = datetime('now')`)
      .bind(crypto.randomUUID(), userId, type, Number(is_active), JSON.stringify(config || {})).run();
    return jsonResponse({ ok: true });
  },
};
