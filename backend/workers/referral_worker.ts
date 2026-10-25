/**
 * Linky Referral Worker
 * Handles logic for calculating reward days based on signups and conversions.
 */

interface Env {
  DB: D1Database;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    
    if (url.pathname === "/reward/calculate" && request.method === "POST") {
      const { referrerId, type } = await request.json() as { referrerId: string, type: 'signup' | 'conversion' };

      if (type === 'signup') {
        // Logic: 3 new signups = 1 month (30 days) free
        const result = await env.DB.prepare(
          "SELECT COUNT(*) as count FROM referrals WHERE referrer_id = ? AND status = 'successful'"
        ).bind(referrerId).first<{ count: number }>();

        const successfulReferrals = result?.count || 0;
        
        // Every 3 referrals, grant 30 days
        if (successfulReferrals > 0 && successfulReferrals % 3 === 0) {
          await grantRewardDays(env.DB, referrerId, 30);
          return new Response(JSON.stringify({ rewarded: true, days: 30 }), { status: 200 });
        }
      }

      if (type === 'conversion') {
        // Logic: 1 paid conversion = 3 months (90 days) free
        await grantRewardDays(env.DB, referrerId, 90);
        return new Response(JSON.stringify({ rewarded: true, days: 90 }), { status: 200 });
      }

      return new Response(JSON.stringify({ rewarded: false }), { status: 200 });
    }

    if (url.pathname === "/auth/google" && request.method === "POST") {
      const { email, name, photoUrl, referralCode } = await request.json() as { email: string, name: string, photoUrl?: string, referralCode?: string };
      
      // 1. Check if user exists
      let user = await env.DB.prepare("SELECT * FROM users WHERE email = ?").bind(email).first<any>();
      
      if (!user) {
        // 2. Create new user if not exists
        const userId = crypto.randomUUID();
        const myReferralCode = Math.random().toString(36).substring(2, 8).toUpperCase();
        
        await env.DB.prepare(`
          INSERT INTO users (id, username, email, profile_image, referral_code, created_at)
          VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        `).bind(userId, name, email, photoUrl || null, myReferralCode).run();
        
        user = { id: userId, username: name, email, referral_code: myReferralCode };

        // 3. Handle Referral if provided
        if (referralCode) {
          const referrer = await env.DB.prepare("SELECT id FROM users WHERE referral_code = ?").bind(referralCode).first<{ id: string }>();
          if (referrer) {
            await handleNewUserReferral(env.DB, userId, referrer.id);
          }
        }
      }

      return new Response(JSON.stringify({ success: true, user }), { status: 200 });
    }

    if (url.pathname === "/messages" && request.method === "GET") {
      const userId = url.searchParams.get("userId");
      const convs = await env.DB.prepare(`
        SELECT c.*, u.username as other_user_name, u.profile_image as other_user_img
        FROM conversations c
        JOIN users u ON (u.id = c.user1_id OR u.id = c.user2_id) AND u.id != ?
        WHERE c.user1_id = ? OR c.user2_id = ?
        ORDER BY c.updated_at DESC
      `).bind(userId, userId, userId).all();
      return new Response(JSON.stringify(convs.results), { status: 200 });
    }

    if (url.pathname === "/notifications" && request.method === "GET") {
      const userId = url.searchParams.get("userId");
      const notes = await env.DB.prepare(`
        SELECT n.*, u.username as sender_name, u.profile_image as sender_img
        FROM notifications n
        LEFT JOIN users u ON u.id = n.sender_id
        WHERE n.user_id = ?
        ORDER BY n.created_at DESC
      `).bind(userId).all();
      return new Response(JSON.stringify(notes.results), { status: 200 });
    }

    return new Response("Not Found", { status: 404 });
  }
};

async function grantRewardDays(db: D1Database, userId: string, days: number) {
  // Update user's subscription end date
  await db.prepare(`
    UPDATE users 
    SET subscription_ends_at = datetime(COALESCE(subscription_ends_at, CURRENT_TIMESTAMP), '+' || ? || ' days')
    WHERE id = ?
  `).bind(days, userId).run();
}

/**
 * Logic for New Users:
 * New invited users get 1 month free automatically.
 * This should be called during user registration if a referral code is present.
 */
export async function handleNewUserReferral(db: D1Database, userId: string, referrerId: string) {
  // Grant 30 days to the new user
  await db.prepare(`
    UPDATE users 
    SET trial_ends_at = datetime(CURRENT_TIMESTAMP, '+30 days')
    WHERE id = ?
  `).bind(userId).run();

  // Create referral record
  await db.prepare(`
    INSERT INTO referrals (id, referrer_id, referred_user_id, status)
    VALUES (?, ?, ?, 'successful')
  `).bind(crypto.randomUUID(), referrerId, userId).run();
}
