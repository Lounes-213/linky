import { jsonResponse, errorResponse } from '../utils/cors';

export const storyRoutes = {
  async list(request, env) {
    const stories = await env.DB.prepare(
      `SELECT s.*, u.name as user_name, u.avatar_url as user_avatar, st.name as store_name
       FROM stories s 
       JOIN users u ON s.user_id = u.id
       LEFT JOIN stores st ON s.store_id = st.id
       WHERE s.expires_at > datetime('now')
       ORDER BY s.created_at DESC`
    ).all();

    const grouped = {};
    for (const story of stories.results || []) {
      const userId = story.user_id;
      if (!grouped[userId]) {
        grouped[userId] = {
          user_id: userId,
          user_name: story.user_name,
          user_avatar: story.user_avatar,
          store_name: story.store_name,
          stories: []
        };
      }
      grouped[userId].stories.push({
        id: story.id,
        media_url: story.media_url,
        media_type: story.media_type,
        caption: story.caption,
        views_count: story.views_count,
        created_at: story.created_at,
        expires_at: story.expires_at
      });
    }

    return jsonResponse({ stories: Object.values(grouped) });
  },

  async create(request, env) {
    const { media_url, media_type = 'image', caption = '', duration = 5, store_id } = await request.json();

    if (!media_url) return errorResponse('Media URL required');

    const id = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

    await env.DB.prepare(
      `INSERT INTO stories (id, user_id, store_id, media_url, media_type, caption, duration, expires_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(id, request.user.uid, store_id || null, media_url, media_type, caption, duration, expiresAt).run();

    return jsonResponse({ id, message: 'Story created' }, 201);
  },

  async view(request, env) {
    const { id } = request.params;

    const existing = await env.DB.prepare(
      'SELECT id FROM story_views WHERE story_id = ? AND user_id = ?'
    ).bind(id, request.user.uid).first();

    if (!existing) {
      await env.DB.prepare(
        'INSERT INTO story_views (id, story_id, user_id) VALUES (?, ?, ?)'
      ).bind(crypto.randomUUID(), id, request.user.uid).run();

      await env.DB.prepare(
        'UPDATE stories SET views_count = views_count + 1 WHERE id = ?'
      ).bind(id).run();
    }

    return jsonResponse({ message: 'Story viewed' });
  },

  async update(request, env) {
    const { id } = request.params;
    const story = await env.DB.prepare('SELECT user_id FROM stories WHERE id = ?').bind(id).first();
    if (!story || story.user_id !== request.user.uid) return errorResponse('Unauthorized', 403);

    const { caption } = await request.json();
    await env.DB.prepare('UPDATE stories SET caption = ? WHERE id = ?').bind(caption || '', id).run();
    return jsonResponse({ message: 'Story updated' });
  },

  async delete(request, env) {
    const { id } = request.params;
    const story = await env.DB.prepare('SELECT user_id FROM stories WHERE id = ?').bind(id).first();

    if (!story || story.user_id !== request.user.uid) return errorResponse('Unauthorized', 403);

    await env.DB.prepare('DELETE FROM stories WHERE id = ?').bind(id).run();
    return jsonResponse({ message: 'Story deleted' });
  }
};
