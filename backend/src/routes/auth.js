import { jsonResponse, errorResponse } from '../utils/cors';
import { v4 as uuidv4 } from 'uuid';

async function verifiedFirebaseUser(firebaseToken, env) {
  if (!firebaseToken || !env.FIREBASE_API_KEY) return null;
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${env.FIREBASE_API_KEY}`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ idToken: firebaseToken }) }
  );
  if (!response.ok) return null;
  const data = await response.json();
  return data.users?.[0] || null;
}

async function exchangeGoogleCode(code, redirectUri, env) {
  const clientId = env.GOOGLE_CLIENT_ID_DESKTOP;
  const clientSecret = env.GOOGLE_CLIENT_SECRET_DESKTOP;
  if (!clientId || !clientSecret) return null;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code',
    }).toString(),
  });

  if (!tokenRes.ok) return null;
  const tokenData = await tokenRes.json();
  if (tokenData.error) return null;
  return tokenData;
}

async function getGoogleIdToken(accessToken, env) {
  const apiKey = env.FIREBASE_API_KEY;
  if (!apiKey) return null;

  const postBody = `access_token=${accessToken}&providerId=google.com`;
  const firebaseRes = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: postBody,
    }
  );

  if (!firebaseRes.ok) return null;
  const firebaseData = await firebaseRes.json();
  return firebaseData.idToken || null;
}

export const authRoutes = {
  async register(request, env) {
    return errorResponse('Create accounts with Firebase Authentication', 410);
  },

  async login(request, env) {
    return errorResponse('Sign in with Firebase Authentication', 410);
  },

  async firebaseAuth(request, env) {
    const { firebase_token, username } = await request.json();
    const firebaseUser = await verifiedFirebaseUser(firebase_token, env);
    if (!firebaseUser?.localId) return errorResponse('Invalid Firebase session', 401);
    const firebase_uid = firebaseUser.localId;
    const email = firebaseUser.email || '';
    const name = firebaseUser.displayName || '';
    const avatar_url = firebaseUser.photoUrl || '';

    let user = await env.DB.prepare(
      'SELECT id, email, name, username, avatar_url FROM users WHERE firebase_uid = ?'
    ).bind(firebase_uid).first();

    if (!user) {
      const id = uuidv4();
      const safeUsername = (username || (email ? email.split('@')[0] : `user_${id.slice(0, 8)}`))
        .toLowerCase().replace(/[^a-z0-9_]/g, '').slice(0, 20) || `user_${id.slice(0, 8)}`;

      await env.DB.prepare(
        `INSERT INTO users (id, firebase_uid, email, name, avatar_url, username) VALUES (?, ?, ?, ?, ?, ?)`
      ).bind(id, firebase_uid, email, name, avatar_url, safeUsername).run();

      await env.DB.prepare(
        `INSERT INTO cart (id, user_id) VALUES (?, ?)`
      ).bind(uuidv4(), id).run();

      user = { id, email, name, username: safeUsername, avatar_url };
    }
    return jsonResponse({ user });
  },

  async refreshToken(request, env) {
    return errorResponse('Refresh Firebase ID tokens in the client SDK', 410);
  },

  async googleDesktop(request, env) {
    const { code, redirect_uri } = await request.json();
    if (!code || !redirect_uri) return errorResponse('Code and redirect_uri required', 400);

    const tokenData = await exchangeGoogleCode(code, redirect_uri, env);
    if (!tokenData) return errorResponse('Failed to exchange Google code', 400);

    const firebaseToken = await getGoogleIdToken(tokenData.access_token, env);
    if (!firebaseToken) return errorResponse('Failed to get Firebase token', 400);

    const firebaseUser = await verifiedFirebaseUser(firebaseToken, env);
    if (!firebaseUser?.localId) return errorResponse('Invalid Firebase session', 401);

    const firebase_uid = firebaseUser.localId;
    const email = firebaseUser.email || '';
    const name = firebaseUser.displayName || '';
    const avatar_url = firebaseUser.photoUrl || '';

    let user = await env.DB.prepare(
      'SELECT id, email, name, username, avatar_url FROM users WHERE firebase_uid = ?'
    ).bind(firebase_uid).first();

    if (!user) {
      const id = uuidv4();
      const safeUsername = (email ? email.split('@')[0] : `user_${id.slice(0, 8)}`)
        .toLowerCase().replace(/[^a-z0-9_]/g, '').slice(0, 20) || `user_${id.slice(0, 8)}`;

      await env.DB.prepare(
        `INSERT INTO users (id, firebase_uid, email, name, avatar_url, username) VALUES (?, ?, ?, ?, ?, ?)`
      ).bind(id, firebase_uid, email, name, avatar_url, safeUsername).run();

      await env.DB.prepare(
        `INSERT INTO cart (id, user_id) VALUES (?, ?)`
      ).bind(uuidv4(), id).run();

      user = { id, email, name, username: safeUsername, avatar_url };
    }

    return jsonResponse({ user, firebase_token: firebaseToken });
  },
};