import { corsHeaders } from './utils/cors';
import { authMiddleware, adminMiddleware } from './middleware/auth';
import { authRoutes } from './routes/auth';
import { userRoutes } from './routes/users';
import { storeRoutes } from './routes/stores';
import { productRoutes } from './routes/products';
import { categoryRoutes } from './routes/categories';
import { cartRoutes } from './routes/cart';
import { orderRoutes } from './routes/orders';
import { reviewRoutes } from './routes/reviews';
import { storyRoutes } from './routes/stories';
import { uploadRoutes } from './routes/upload';
import { notificationRoutes } from './routes/notifications';
import { searchRoutes } from './routes/search';
import { settingsRoutes } from './routes/settings';
import { adminRoutes } from './routes/admin';
import { wishlistRoutes } from './routes/wishlist';
import { creatorRoutes, publicProfileRoutes } from './routes/public_profiles';
import { importRoutes } from './routes/imports';
import { pollRoutes } from './routes/polls';
import { donationRoutes } from './routes/donations';
import { playlistRoutes } from './routes/playlists';
import { storeCategoryRoutes } from './routes/store_categories';

function matchRoute(method, pathname, pattern) {
  if (method !== pattern.method) return null;

  const patternParts = pattern.path.split('/');
  const urlParts = pathname.split('/');

  if (patternParts.length !== urlParts.length) return null;

  const params = {};
  for (let i = 0; i < patternParts.length; i++) {
    if (patternParts[i].startsWith(':')) {
      params[patternParts[i].slice(1)] = urlParts[i];
    } else if (patternParts[i] !== urlParts[i]) {
      return null;
    }
  }
  return params;
}

const routes = [];

function addRoute(method, path, ...handlers) {
  routes.push({ method, path, handlers });
}

// Health check
addRoute('GET', '/api/health', () =>
  new Response(JSON.stringify({ status: 'ok', version: '1.0.0' }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders }
  })
);

// Auth
addRoute('POST', '/api/auth/register', authRoutes.register);
addRoute('POST', '/api/auth/login', authRoutes.login);
addRoute('POST', '/api/auth/firebase', authRoutes.firebaseAuth);
addRoute('POST', '/api/auth/google-desktop', authRoutes.googleDesktop);
addRoute('POST', '/api/auth/refresh', authRoutes.refreshToken);

// Users
addRoute('GET', '/api/users/me', authMiddleware, userRoutes.me);
addRoute('PUT', '/api/users/me', authMiddleware, userRoutes.updateMe);
addRoute('GET', '/api/users/:id', userRoutes.getById);
addRoute('GET', '/api/users/:id/stores', userRoutes.getStores);
addRoute('GET', '/api/users/:id/products', userRoutes.getProducts);

// Profile
addRoute('GET', '/api/profile', authMiddleware, userRoutes.profile);
addRoute('PUT', '/api/profile', authMiddleware, userRoutes.updateProfile);
addRoute('POST', '/api/profile/social-links', authMiddleware, userRoutes.addSocialLink);
addRoute('PUT', '/api/profile/social-links/:id', authMiddleware, userRoutes.updateSocialLink);
addRoute('DELETE', '/api/profile/social-links/:id', authMiddleware, userRoutes.removeSocialLink);
addRoute('GET', '/api/profile/links', authMiddleware, creatorRoutes.listLinks);
addRoute('POST', '/api/profile/links', authMiddleware, creatorRoutes.createLink);
addRoute('PUT', '/api/profile/links/:id', authMiddleware, creatorRoutes.updateLink);
addRoute('DELETE', '/api/profile/links/:id', authMiddleware, creatorRoutes.deleteLink);
addRoute('GET', '/api/profile/portfolio', authMiddleware, creatorRoutes.portfolio);
addRoute('POST', '/api/profile/portfolio', authMiddleware, creatorRoutes.createPortfolioProject);
addRoute('PUT', '/api/profile/portfolio/:id', authMiddleware, creatorRoutes.updatePortfolioProject);
addRoute('DELETE', '/api/profile/portfolio/:id', authMiddleware, creatorRoutes.deletePortfolioProject);
addRoute('PUT', '/api/profile/sections', authMiddleware, creatorRoutes.updateSections);
addRoute('GET', '/api/profile/automations', authMiddleware, creatorRoutes.automations);
addRoute('PUT', '/api/profile/automations', authMiddleware, creatorRoutes.automations);

// The public endpoint powers the shareable Linky web page: linky.to/:username.
addRoute('GET', '/api/public/:username', publicProfileRoutes.get);
addRoute('POST', '/api/public/:username/links/:id/click', publicProfileRoutes.click);
addRoute('POST', '/api/imports/aliexpress/preview', authMiddleware, importRoutes.preview);
addRoute('POST', '/api/imports/aliexpress/publish', authMiddleware, importRoutes.publish);

// Stores
addRoute('GET', '/api/stores', storeRoutes.list);
addRoute('GET', '/api/stores/validate-code', storeRoutes.validateCode);
addRoute('GET', '/api/stores/:slug', storeRoutes.getBySlug);
addRoute('POST', '/api/stores', authMiddleware, storeRoutes.create);
addRoute('PUT', '/api/stores/:id', authMiddleware, storeRoutes.update);
addRoute('GET', '/api/stores/:id/products', storeRoutes.getProducts);
addRoute('POST', '/api/stores/:id/follow', authMiddleware, storeRoutes.follow);
addRoute('DELETE', '/api/stores/:id/follow', authMiddleware, storeRoutes.unfollow);
addRoute('GET', '/api/stores/:id/analytics', authMiddleware, storeRoutes.getAnalytics);
addRoute('GET', '/api/stores/:id/dashboard', authMiddleware, storeRoutes.dashboard);
addRoute('GET', '/api/stores/:id/team', authMiddleware, storeRoutes.team);
addRoute('POST', '/api/stores/:id/team', authMiddleware, storeRoutes.addTeamMember);
addRoute('PUT', '/api/stores/:id/team/:memberId', authMiddleware, storeRoutes.updateTeamMember);
addRoute('DELETE', '/api/stores/:id/team/:memberId', authMiddleware, storeRoutes.removeTeamMember);

// Products
addRoute('GET', '/api/products', productRoutes.list);
addRoute('GET', '/api/products/featured', productRoutes.listFeatured);
addRoute('GET', '/api/products/:id', productRoutes.getById);
addRoute('GET', '/api/products/:id/variants', productRoutes.getVariants);
addRoute('POST', '/api/products', authMiddleware, productRoutes.create);
addRoute('PUT', '/api/products/:id', authMiddleware, productRoutes.update);
addRoute('POST', '/api/products/:id/featured', authMiddleware, productRoutes.toggleFeatured);
addRoute('DELETE', '/api/products/:id', authMiddleware, productRoutes.delete);

// Store Categories (per-store, owner-managed)
addRoute('GET', '/api/store-categories', storeCategoryRoutes.list);
addRoute('POST', '/api/store-categories', authMiddleware, storeCategoryRoutes.create);
addRoute('PUT', '/api/store-categories/:id', authMiddleware, storeCategoryRoutes.update);
addRoute('DELETE', '/api/store-categories/:id', authMiddleware, storeCategoryRoutes.delete);
addRoute('PUT', '/api/store-categories/reorder', authMiddleware, storeCategoryRoutes.reorder);

// Categories
addRoute('GET', '/api/categories', categoryRoutes.list);
addRoute('GET', '/api/categories/:slug', categoryRoutes.getBySlug);
addRoute('GET', '/api/categories/:slug/subcategories', categoryRoutes.getSubcategories);

// Cart
addRoute('GET', '/api/cart', authMiddleware, cartRoutes.get);
addRoute('POST', '/api/cart/items', authMiddleware, cartRoutes.addItem);
addRoute('PUT', '/api/cart/items/:id', authMiddleware, cartRoutes.updateItem);
addRoute('DELETE', '/api/cart/items/:id', authMiddleware, cartRoutes.removeItem);
addRoute('DELETE', '/api/cart', authMiddleware, cartRoutes.clear);

// Orders
addRoute('GET', '/api/orders', authMiddleware, orderRoutes.list);
addRoute('GET', '/api/orders/:id', authMiddleware, orderRoutes.getById);
addRoute('POST', '/api/orders', authMiddleware, orderRoutes.create);
addRoute('POST', '/api/orders/public', orderRoutes.createPublic);
addRoute('PUT', '/api/orders/:id/status', authMiddleware, orderRoutes.updateStatus);
addRoute('GET', '/api/orders/:id/tracking', authMiddleware, orderRoutes.getTracking);

// Reviews
addRoute('GET', '/api/products/:id/reviews', reviewRoutes.list);
addRoute('POST', '/api/products/:id/reviews', authMiddleware, reviewRoutes.create);

// Stories
addRoute('GET', '/api/stories', authMiddleware, storyRoutes.list);
addRoute('POST', '/api/stories', authMiddleware, storyRoutes.create);
addRoute('POST', '/api/stories/:id/view', authMiddleware, storyRoutes.view);
addRoute('PUT', '/api/stories/:id', authMiddleware, storyRoutes.update);
addRoute('DELETE', '/api/stories/:id', authMiddleware, storyRoutes.delete);

// Upload
addRoute('POST', '/api/upload', authMiddleware, uploadRoutes.upload);
addRoute('POST', '/api/upload/presign', authMiddleware, uploadRoutes.presign);
addRoute('POST', '/api/upload/delete', authMiddleware, uploadRoutes.deleteImages);

// Notifications
addRoute('GET', '/api/notifications', authMiddleware, notificationRoutes.list);
addRoute('PUT', '/api/notifications/:id/read', authMiddleware, notificationRoutes.markRead);
addRoute('PUT', '/api/notifications/read-all', authMiddleware, notificationRoutes.markAllRead);

// Search
addRoute('GET', '/api/search', searchRoutes.search);
addRoute('GET', '/api/search/suggestions', searchRoutes.suggestions);

// Settings
addRoute('GET', '/api/settings', settingsRoutes.list);
addRoute('PUT', '/api/settings/:key', authMiddleware, settingsRoutes.update);

// Wishlist
addRoute('GET', '/api/wishlist', authMiddleware, wishlistRoutes.list);
addRoute('POST', '/api/wishlist', authMiddleware, wishlistRoutes.add);
addRoute('DELETE', '/api/wishlist/:productId', authMiddleware, wishlistRoutes.remove);
addRoute('GET', '/api/wishlist/check/:productId', authMiddleware, wishlistRoutes.check);

// Admin
addRoute('POST', '/api/admin/codes/generate', adminMiddleware, adminRoutes.generateCodes);
addRoute('GET', '/api/admin/codes', adminMiddleware, adminRoutes.listCodes);
addRoute('DELETE', '/api/admin/codes/:id', adminMiddleware, adminRoutes.deleteCode);
addRoute('GET', '/api/admin/stats', adminMiddleware, adminRoutes.stats);
addRoute('GET', '/api/admin/users', adminMiddleware, adminRoutes.listUsers);
addRoute('GET', '/api/admin/users/:id', adminMiddleware, adminRoutes.getUser);
addRoute('PUT', '/api/admin/users/:id/ban', adminMiddleware, adminRoutes.banUser);
addRoute('GET', '/api/admin/stores', adminMiddleware, adminRoutes.listStores);
addRoute('PUT', '/api/admin/stores/:id/toggle', adminMiddleware, adminRoutes.toggleStore);
addRoute('PUT', '/api/admin/stores/:id/verify', adminMiddleware, adminRoutes.verifyStore);
addRoute('GET', '/api/admin/products', adminMiddleware, adminRoutes.listProducts);
addRoute('POST', '/api/admin/stores/:id/renew', adminMiddleware, adminRoutes.renewStore);

// Polls / Votes
addRoute('GET', '/api/polls', pollRoutes.list);
addRoute('GET', '/api/polls/:id', pollRoutes.getById);
addRoute('POST', '/api/polls', authMiddleware, pollRoutes.create);
addRoute('POST', '/api/polls/:id/vote', authMiddleware, pollRoutes.vote);
addRoute('DELETE', '/api/polls/:id', authMiddleware, pollRoutes.delete);
addRoute('POST', '/api/polls/:id/close', authMiddleware, pollRoutes.close);

// Donations
addRoute('GET', '/api/donations/settings/:userId', donationRoutes.getSettings);
addRoute('GET', '/api/donations/public/:userId', donationRoutes.getPublicSettings);
addRoute('GET', '/api/donations/feed/:userId', donationRoutes.getFeed);
addRoute('PUT', '/api/donations/settings', authMiddleware, donationRoutes.updateSettings);
addRoute('POST', '/api/donations', donationRoutes.donate);
addRoute('GET', '/api/donations/verify/:donationId', donationRoutes.verifyPayment);
addRoute('POST', '/api/donations/update-status', donationRoutes.updateStatus);
addRoute('GET', '/api/donations/check-payment/:donationId', donationRoutes.checkPayment);
addRoute('POST', '/api/donations/webhook', donationRoutes.webhook);
addRoute('GET', '/api/donations/my-stats', authMiddleware, donationRoutes.getMyStats);
addRoute('GET', '/api/donations/received', authMiddleware, donationRoutes.listReceived);
addRoute('GET', '/api/donations/made', authMiddleware, donationRoutes.listMade);

// Playlists
addRoute('GET', '/api/playlists/user/:userId', playlistRoutes.listByUser);
addRoute('GET', '/api/playlists/:id', playlistRoutes.getById);
addRoute('POST', '/api/playlists', authMiddleware, playlistRoutes.create);
addRoute('PUT', '/api/playlists/:id', authMiddleware, playlistRoutes.update);
addRoute('DELETE', '/api/playlists/:id', authMiddleware, playlistRoutes.delete);
addRoute('POST', '/api/playlists/:id/videos', authMiddleware, playlistRoutes.addVideo);
addRoute('DELETE', '/api/playlists/:id/videos/:videoId', authMiddleware, playlistRoutes.deleteVideo);

export default {
  async fetch(request, env, ctx) {
    try {
      if (request.method === 'OPTIONS') {
        return finalizeResponse(new Response(null, { status: 204 }), request, env);
      }
      const url = new URL(request.url);
      const method = request.method;

      if (method === 'GET' && url.pathname.startsWith('/api/images/')) {
        const response = await uploadRoutes.getImage(request, env);
        return finalizeResponse(response, request, env);
      }

      for (const route of routes) {
        const params = matchRoute(method, url.pathname, { method: route.method, path: route.path });
        if (params !== null) {
          request.params = params;
          let response;
          for (const handler of route.handlers) {
            response = await handler(request, env, ctx);
            if (response) break;
          }
          return finalizeResponse(response || new Response('No response', { status: 500 }), request, env);
        }
      }

      return finalizeResponse(new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      }), request, env);
    } catch (err) {
      const detail = err instanceof Error ? err.message : String(err);
      console.error('Worker error:', detail, err?.stack || '');
      return finalizeResponse(new Response(JSON.stringify({ error: 'Internal server error', detail }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      }), request, env);
    }
  }
};

function finalizeResponse(response, request, env) {
  const headers = new Headers(response.headers);
  const origin = request.headers.get('Origin');
  const allowed = (env.ALLOWED_ORIGINS || '').split(',').map((item) => item.trim()).filter(Boolean);
  headers.delete('Access-Control-Allow-Origin');
  if (origin) {
    let isAllowed = allowed.includes(origin);
    if (!isAllowed) {
      try {
        const originHost = new URL(origin).hostname;
        isAllowed = allowed.some(a => {
          try {
            const allowedHost = new URL(a).hostname;
            return originHost === allowedHost || originHost.endsWith('.' + allowedHost);
          } catch (_) { return false; }
        });
        if (!isAllowed) {
          isAllowed = originHost === 'localhost' ||
                      originHost === '127.0.0.1' ||
                      originHost.endsWith('.pages.dev') ||
                      originHost.endsWith('.linky.to') ||
                      originHost.endsWith('.workers.dev');
        }
      } catch (_) {
        isAllowed = true;
      }
    }
    headers.set('Access-Control-Allow-Origin', isAllowed ? origin : '*');
  } else {
    headers.set('Access-Control-Allow-Origin', '*');
  }
  headers.set('Vary', 'Origin');
  headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  headers.set('X-Content-Type-Options', 'nosniff');
  headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}
