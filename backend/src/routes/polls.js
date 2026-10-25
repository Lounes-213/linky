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

export const pollRoutes = {
  // List polls (public)
  list: async (request, env) => {
    const url = new URL(request.url);
    const status = url.searchParams.get('status') || 'active';
    const userId = url.searchParams.get('user_id') || '';
    let query = `SELECT p.*, u.username, u.name as creator_name, u.avatar_url,
      (SELECT COUNT(*) FROM poll_votes WHERE poll_id = p.id) as total_votes
      FROM polls p JOIN users u ON p.user_id = u.id WHERE p.status = ?`;
    const params = [status];
    if (userId) { query += ` AND p.user_id = ?`; params.push(userId); }
    query += ` ORDER BY p.created_at DESC LIMIT 50`;
    const { results } = await env.DB.prepare(query).bind(...params).all();
    return json({ polls: results });
  },

  // Get single poll with options
  getById: async (request, env) => {
    const { id } = request.params;
    const poll = await env.DB.prepare(
      `SELECT p.*, u.username, u.name as creator_name, u.avatar_url FROM polls p JOIN users u ON p.user_id = u.id WHERE p.id = ?`
    ).bind(id).first();
    if (!poll) return json({ error: 'Poll not found' }, 404);
    const { results: options } = await env.DB.prepare(
      `SELECT * FROM poll_options WHERE poll_id = ? ORDER BY sort_order`
    ).bind(id).all();
    return json({ ...poll, options });
  },

  // Create poll
  create: async (request, env) => {
    const user = request.user;
    const body = await request.json();
    const { question, description, type, options, ends_at } = body;
    if (!question || !options || options.length < 2) {
      return json({ error: 'Question and at least 2 options required' }, 400);
    }
    const pollId = genId();
    await env.DB.prepare(
      `INSERT INTO polls (id, user_id, question, description, type, ends_at) VALUES (?, ?, ?, ?, ?, ?)`
    ).bind(pollId, user.uid, question, description || '', type || 'poll', ends_at || null).run();
    for (let i = 0; i < options.length; i++) {
      const optId = genId();
      await env.DB.prepare(
        `INSERT INTO poll_options (id, poll_id, option_text, option_image, sort_order) VALUES (?, ?, ?, ?, ?)`
      ).bind(optId, pollId, options[i].text || options[i], options[i].image || '', i).run();
    }
    return json({ id: pollId, success: true }, 201);
  },

  // Vote
  vote: async (request, env) => {
    const user = request.user;
    const { id } = request.params;
    const { option_id } = await request.json();
    if (!option_id) return json({ error: 'option_id required' }, 400);
    const poll = await env.DB.prepare(`SELECT * FROM polls WHERE id = ? AND status = 'active'`).bind(id).first();
    if (!poll) return json({ error: 'Poll not found or closed' }, 404);
    const existing = await env.DB.prepare(`SELECT id FROM poll_votes WHERE poll_id = ? AND user_id = ?`).bind(id, user.uid).first();
    if (existing) return json({ error: 'Already voted' }, 409);
    const voteId = genId();
    await env.DB.prepare(`INSERT INTO poll_votes (id, poll_id, option_id, user_id) VALUES (?, ?, ?, ?)`).bind(voteId, id, option_id, user.uid).run();
    await env.DB.prepare(`UPDATE poll_options SET votes_count = votes_count + 1 WHERE id = ?`).bind(option_id).run();
    return json({ success: true }, 201);
  },

  // Delete poll
  delete: async (request, env) => {
    const user = request.user;
    const { id } = request.params;
    const poll = await env.DB.prepare(`SELECT * FROM polls WHERE id = ?`).bind(id).first();
    if (!poll) return json({ error: 'Not found' }, 404);
    if (poll.user_id !== user.uid) return json({ error: 'Forbidden' }, 403);
    await env.DB.prepare(`DELETE FROM poll_votes WHERE poll_id = ?`).bind(id).run();
    await env.DB.prepare(`DELETE FROM poll_options WHERE poll_id = ?`).bind(id).run();
    await env.DB.prepare(`DELETE FROM polls WHERE id = ?`).bind(id).run();
    return json({ success: true });
  },

  // Close poll
  close: async (request, env) => {
    const user = request.user;
    const { id } = request.params;
    const poll = await env.DB.prepare(`SELECT * FROM polls WHERE id = ?`).bind(id).first();
    if (!poll || poll.user_id !== user.uid) return json({ error: 'Forbidden' }, 403);
    await env.DB.prepare(`UPDATE polls SET status = 'closed' WHERE id = ?`).bind(id).run();
    return json({ success: true });
  },
};
