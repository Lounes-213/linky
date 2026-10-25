import { corsHeaders } from '../utils/cors';

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
}

function genId() {
  return crypto.randomUUID();
}

export const playlistRoutes = {
  // List playlists for a user (public)
  listByUser: async (request, env) => {
    const { userId } = request.params;
    const { results } = await env.DB.prepare(
      `SELECT * FROM playlists WHERE user_id = ? ORDER BY created_at DESC`
    ).bind(userId).all();
    return json({ playlists: results });
  },

  // Get single playlist with videos
  getById: async (request, env) => {
    const { id } = request.params;
    const playlist = await env.DB.prepare(`SELECT * FROM playlists WHERE id = ?`).bind(id).first();
    if (!playlist) return json({ error: 'Not found' }, 404);
    const { results: videos } = await env.DB.prepare(
      `SELECT * FROM playlist_videos WHERE playlist_id = ? ORDER BY sort_order`
    ).bind(id).all();
    return json({ ...playlist, videos });
  },

  // Create playlist
  create: async (request, env) => {
    const user = request.user;
    const body = await request.json();
    const { name, description, platform, cover_image } = body;
    if (!name) return json({ error: 'Name required' }, 400);
    const id = genId();
    await env.DB.prepare(
      `INSERT INTO playlists (id, user_id, name, description, platform, cover_image) VALUES (?,?,?,?,?,?)`
    ).bind(id, user.uid, name, description || '', platform || 'youtube', cover_image || '').run();
    return json({ id, success: true }, 201);
  },

  // Update playlist
  update: async (request, env) => {
    const user = request.user;
    const { id } = request.params;
    const playlist = await env.DB.prepare(`SELECT * FROM playlists WHERE id = ?`).bind(id).first();
    if (!playlist || playlist.user_id !== user.uid) return json({ error: 'Forbidden' }, 403);
    const body = await request.json();
    const { name, description, platform, cover_image } = body;
    await env.DB.prepare(
      `UPDATE playlists SET name=?, description=?, platform=?, cover_image=? WHERE id=?`
    ).bind(name || playlist.name, description ?? playlist.description, platform || playlist.platform, cover_image ?? playlist.cover_image, id).run();
    return json({ success: true });
  },

  // Delete playlist
  delete: async (request, env) => {
    const user = request.user;
    const { id } = request.params;
    const playlist = await env.DB.prepare(`SELECT * FROM playlists WHERE id = ?`).bind(id).first();
    if (!playlist || playlist.user_id !== user.uid) return json({ error: 'Forbidden' }, 403);
    await env.DB.prepare(`DELETE FROM playlist_videos WHERE playlist_id = ?`).bind(id).run();
    await env.DB.prepare(`DELETE FROM playlists WHERE id = ?`).bind(id).run();
    return json({ success: true });
  },

  // Add video to playlist
  addVideo: async (request, env) => {
    const user = request.user;
    const { id } = request.params;
    const playlist = await env.DB.prepare(`SELECT * FROM playlists WHERE id = ?`).bind(id).first();
    if (!playlist || playlist.user_id !== user.uid) return json({ error: 'Forbidden' }, 403);
    const body = await request.json();
    const { title, url, thumbnail, duration, platform } = body;
    if (!title || !url) return json({ error: 'Title and URL required' }, 400);
    const videoId = genId();
    const maxOrder = await env.DB.prepare(`SELECT COALESCE(MAX(sort_order),0) as m FROM playlist_videos WHERE playlist_id = ?`).bind(id).first();
    await env.DB.prepare(
      `INSERT INTO playlist_videos (id, playlist_id, title, url, thumbnail, duration, platform, sort_order) VALUES (?,?,?,?,?,?,?,?)`
    ).bind(videoId, id, title, url, thumbnail || '', duration || '', platform || playlist.platform, (maxOrder?.m || 0) + 1).run();
    await env.DB.prepare(`UPDATE playlists SET video_count = video_count + 1 WHERE id = ?`).bind(id).run();
    return json({ id: videoId, success: true }, 201);
  },

  // Delete video
  deleteVideo: async (request, env) => {
    const user = request.user;
    const { id, videoId } = request.params;
    const playlist = await env.DB.prepare(`SELECT * FROM playlists WHERE id = ?`).bind(id).first();
    if (!playlist || playlist.user_id !== user.uid) return json({ error: 'Forbidden' }, 403);
    await env.DB.prepare(`DELETE FROM playlist_videos WHERE id = ? AND playlist_id = ?`).bind(videoId, id).run();
    await env.DB.prepare(`UPDATE playlists SET video_count = MAX(0, video_count - 1) WHERE id = ?`).bind(id).run();
    return json({ success: true });
  },
};
