import { corsHeaders } from '../utils/cors';
import { buildSofizpayUrl } from '../utils/sofizpay';

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
}

function genId() {
  return crypto.randomUUID();
}

export const donationRoutes = {
  getSettings: async (request, env) => {
    const { userId } = request.params;
    const settings = await env.DB.prepare(`SELECT * FROM donation_settings WHERE user_id = ?`).bind(userId).first();
    const totalDonations = await env.DB.prepare(
      `SELECT COUNT(*) as count, COALESCE(SUM(amount),0) as total FROM donations WHERE recipient_id = ? AND status = 'completed'`
    ).bind(userId).first();
    return json({
      settings: settings || { is_enabled: 0, description: '', preset_amounts: '100,200,500,1000', payment_methods: 'CIB/Edahabiya' },
      stats: totalDonations,
    });
  },

  updateSettings: async (request, env) => {
    const user = request.user;
    const body = await request.json();
    const { is_enabled, description, preset_amounts, payment_methods } = body;
    const existing = await env.DB.prepare(`SELECT user_id FROM donation_settings WHERE user_id = ?`).bind(user.uid).first();
    if (existing) {
      await env.DB.prepare(
        `UPDATE donation_settings SET is_enabled=?, description=?, preset_amounts=?, payment_methods=? WHERE user_id=?`
      ).bind(is_enabled ? 1 : 0, description || '', preset_amounts || '100,200,500,1000', payment_methods || 'CIB/Edahabiya', user.uid).run();
    } else {
      await env.DB.prepare(
        `INSERT INTO donation_settings (user_id, is_enabled, description, preset_amounts, payment_methods) VALUES (?,?,?,?,?)`
      ).bind(user.uid, is_enabled ? 1 : 0, description || '', preset_amounts || '100,200,500,1000', payment_methods || 'CIB/Edahabiya', user.uid).run();
    }
    return json({ success: true });
  },

  donate: async (request, env) => {
    const body = await request.json();
    const { recipient_id, amount, donor_name, donor_phone, donor_email, donor_message, payment_method } = body;
    if (!recipient_id || !amount || amount <= 0) return json({ error: 'Donation invalide' }, 400);
    if (!donor_name || !donor_name.trim()) return json({ error: 'Le nom est obligatoire' }, 400);
    if (amount > 2000) return json({ error: 'Le montant ne peut pas dépasser 2000 DA' }, 400);

    const donationId = genId();
    const frontendUrl = env.FRONTEND_URL || 'https://linky-to.pages.dev';
    const apiUrl = env.API_URL || 'https://linky-api.bensebalounes2.workers.dev';

    await env.DB.prepare(
      `INSERT INTO donations (id, recipient_id, donor_name, donor_message, amount, payment_method, status) VALUES (?,?,?,?,?,?,?)`
    ).bind(donationId, recipient_id, donor_name.trim(), donor_message || '', amount, payment_method || 'cod', 'pending').run();

    if (payment_method === 'cib' && env.SOFIZPAY_SECRET_KEY) {
      const sofizpayUrl = buildSofizpayUrl({
        account: env.SOFIZPAY_SECRET_KEY,
        amount,
        full_name: donor_name.trim(),
        phone: donor_phone || '+213555000000',
        email: donor_email || `donation-${Date.now()}@linky-to.pages.dev`,
        return_url: `${frontendUrl}/payment/result?donationId=${donationId}`,
        webhook_url: `${apiUrl}/api/donations/webhook`,
        order_id: donationId,
        language: 'ar',
        memo: (donor_message || '').substring(0, 28),
      });

      return json({
        id: donationId,
        success: true,
        payment: { redirectUrl: sofizpayUrl },
      });
    }

    await env.DB.prepare(`UPDATE donations SET status = 'completed' WHERE id = ?`).bind(donationId).run();
    return json({ id: donationId, success: true }, 201);
  },

  webhook: async (request, env) => {
    try {
      let body;
      const contentType = request.headers.get('content-type') || '';
      if (contentType.includes('application/json')) {
        body = await request.json();
      } else {
        const url = new URL(request.url);
        body = {};
        for (const [k, v] of url.searchParams) body[k] = v;
      }

      console.log('Webhook received:', JSON.stringify(body));

      const donationId = body.invoice_id || body.order_id || body.internal_order_id || '';
      const transactionId = body.cib_transaction_id || body.order_number || body.transaction_id || '';
      const respCode = body.respCode || body.orderStatus || body.status || '';

      let donation = null;
      if (donationId) {
        donation = await env.DB.prepare(`SELECT id, status FROM donations WHERE id = ?`).bind(donationId).first();
      }
      if (!donation && transactionId) {
        donation = await env.DB.prepare(`SELECT id, status FROM donations WHERE transaction_id = ?`).bind(transactionId).first();
      }
      if (!donation) return json({ error: 'Donation not found' }, 404);

      if (donation.status === 'completed') return json({ success: true, already: true });

      if (respCode === '00' || respCode === 2 || respCode === '2' || respCode === '0' || body.status === 'completed' || body.status === 'successful' || body.status === 'approved') {
        await env.DB.prepare(`UPDATE donations SET status = 'completed', transaction_id = ? WHERE id = ?`).bind(transactionId || '', donation.id).run();
      } else if (body.status === 'failed' || body.status === 'declined' || body.status === 'error') {
        await env.DB.prepare(`UPDATE donations SET status = 'failed' WHERE id = ?`).bind(donation.id).run();
      }

      return json({ success: true });
    } catch (err) {
      console.error('Webhook error:', err);
      return json({ error: 'Webhook processing failed' }, 500);
    }
  },

  verifyPayment: async (request, env) => {
    const { donationId } = request.params;
    const donation = await env.DB.prepare(
      `SELECT id, status, transaction_id, amount, donor_name, donor_message, created_at, recipient_id FROM donations WHERE id = ?`
    ).bind(donationId).first();

    if (!donation) return json({ error: 'Donation not found' }, 404);
    return json({ status: donation.status, amount: donation.amount, donor_name: donation.donor_name, created_at: donation.created_at, recipient_id: donation.recipient_id });
  },

  updateStatus: async (request, env) => {
    const body = await request.json();
    const { donationId, status } = body;
    if (!donationId || !status) return json({ error: 'Missing params' }, 400);
    if (!['completed', 'failed'].includes(status)) return json({ error: 'Invalid status' }, 400);

    const donation = await env.DB.prepare(`SELECT id, status FROM donations WHERE id = ?`).bind(donationId).first();
    if (!donation) return json({ error: 'Donation not found' }, 404);
    if (donation.status === 'completed') return json({ success: true, already: true });

    await env.DB.prepare(`UPDATE donations SET status = ? WHERE id = ?`).bind(status, donationId).run();
    return json({ success: true });
  },

  checkPayment: async (request, env) => {
    const { donationId } = request.params;
    const donation = await env.DB.prepare(
      `SELECT id, status, transaction_id, amount, donor_name, created_at FROM donations WHERE id = ?`
    ).bind(donationId).first();
    if (!donation) return json({ error: 'Donation not found' }, 404);
    return json({ status: donation.status, amount: donation.amount, donor_name: donation.donor_name, created_at: donation.created_at, transaction_id: donation.transaction_id });
  },

  listReceived: async (request, env) => {
    const user = request.user;
    const { results } = await env.DB.prepare(
      `SELECT * FROM donations WHERE recipient_id = ? ORDER BY created_at DESC LIMIT 50`
    ).bind(user.uid).all();
    return json({ donations: results });
  },

  listMade: async (request, env) => {
    const user = request.user;
    const { results } = await env.DB.prepare(
      `SELECT * FROM donations WHERE recipient_id = ? ORDER BY created_at DESC LIMIT 50`
    ).bind(user.uid).all();
    return json({ donations: results });
  },

  getFeed: async (request, env) => {
    const { userId } = request.params;
    const limit = Math.min(parseInt(new URL(request.url).searchParams.get('limit') || '20'), 50);
    const { results } = await env.DB.prepare(
      `SELECT id, donor_name, donor_message, amount, currency, payment_method, created_at
       FROM donations WHERE recipient_id = ? AND status = 'completed' ORDER BY created_at DESC LIMIT ?`
    ).bind(userId, limit).all();
    return json({ donations: results });
  },

  getPublicSettings: async (request, env) => {
    const { userId } = request.params;
    const user = await env.DB.prepare(
      'SELECT id, name, username, avatar_url FROM users WHERE id = ?'
    ).bind(userId).first();
    if (!user) return json({ error: 'User not found' }, 404);

    const settings = await env.DB.prepare(`SELECT * FROM donation_settings WHERE user_id = ?`).bind(userId).first();
    const totalDonations = await env.DB.prepare(
      `SELECT COUNT(*) as count, COALESCE(SUM(amount),0) as total FROM donations WHERE recipient_id = ? AND status = 'completed'`
    ).bind(userId).first();
    return json({
      user,
      settings: settings || { is_enabled: 0, description: 'Soutenez mon travail !', preset_amounts: '100,200,500,1000', payment_methods: 'CIB/Edahabiya' },
      stats: totalDonations,
    });
  },

  getMyStats: async (request, env) => {
    const user = request.user;
    const stats = await env.DB.prepare(
      `SELECT COUNT(*) as count, COALESCE(SUM(amount),0) as total, COALESCE(SUM(CASE WHEN status='completed' THEN amount ELSE 0 END),0) as total_completed
       FROM donations WHERE recipient_id = ?`
    ).bind(user.uid).first();
    const { results: donations } = await env.DB.prepare(
      `SELECT id, donor_name, donor_message, amount, payment_method, status, created_at
       FROM donations WHERE recipient_id = ? ORDER BY created_at DESC LIMIT 20`
    ).bind(user.uid).all();
    return json({ stats, donations });
  },
};
