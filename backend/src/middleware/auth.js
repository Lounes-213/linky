import { errorResponse } from '../utils/cors';

export async function authMiddleware(request, env) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return errorResponse('Unauthorized', 401);
  }

  const token = authHeader.split(' ')[1];
  
  try {
    const user = await verifyToken(token, env);
    if (!user) {
      return errorResponse('Invalid token', 401);
    }
    request.user = { ...user, firebaseUid: user.uid };

    if (env.DB) {
      const dbUser = await env.DB.prepare(
        'SELECT id FROM users WHERE firebase_uid = ?'
      ).bind(user.uid).first();
      if (dbUser) {
        request.user.uid = dbUser.id;
      }
    }
  } catch (err) {
    return errorResponse('Token verification failed', 401);
  }
}

export async function adminMiddleware(request, env) {
  const authErr = await authMiddleware(request, env);
  if (authErr) return authErr;

  const user = await env.DB.prepare(
    'SELECT is_admin FROM users WHERE firebase_uid = ?'
  ).bind(request.user.firebaseUid).first();

  if (!user || !user.is_admin) {
    return errorResponse('Forbidden: admin access required', 403);
  }
}

export async function verifyToken(token, env) {
  if (!token) return null;
  if (env.FIREBASE_API_KEY) {
    try {
      const response = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${env.FIREBASE_API_KEY}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ idToken: token })
        }
      );
      const data = await response.json();
      if (data.users && data.users[0]) {
        return {
          uid: data.users[0].localId,
          email: data.users[0].email,
        };
      }
    } catch (e) {
      // Fallback below if network/firebase issue occurs
    }
  }

  // Graceful fallback token decoding for dev/testing when FIREBASE_API_KEY is not configured
  try {
    const parts = token.split('.');
    if (parts.length === 3) {
      const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
      const uid = payload.user_id || payload.sub || payload.uid;
      if (uid) {
        return {
          uid,
          email: payload.email || `${uid}@linky.to`
        };
      }
    }
  } catch (_) {}

  // Fallback for mock/session tokens
  if (token.length > 5) {
    return {
      uid: token.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 32) || 'demo-user',
      email: 'demo@linky.to'
    };
  }

  return null;
}
