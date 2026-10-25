import { jsonResponse, errorResponse } from '../utils/cors';

export const notificationRoutes = {
  async list(request, env) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '30');
    const offset = (page - 1) * limit;

    const notifications = await env.DB.prepare(
      `SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?`
    ).bind(request.user.uid, limit, offset).all();

    const unreadCount = await env.DB.prepare(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0'
    ).bind(request.user.uid).first();

    return jsonResponse({
      notifications: (notifications.results || []).map(n => ({
        ...n,
        data: JSON.parse(n.data || '{}')
      })),
      unread_count: unreadCount?.count || 0
    });
  },

  async markRead(request, env) {
    const { id } = request.params;
    await env.DB.prepare(
      'UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?'
    ).bind(id, request.user.uid).run();

    return jsonResponse({ message: 'Marked as read' });
  },

  async markAllRead(request, env) {
    await env.DB.prepare(
      'UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0'
    ).bind(request.user.uid).run();

    return jsonResponse({ message: 'All marked as read' });
  }
};
