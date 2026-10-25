const API = 'https://linky-api.bensebalounes2.workers.dev';
const _app = document.getElementById('app');
const _loader = document.getElementById('loader');
const _toast = document.getElementById('toast');
const _storyModal = document.getElementById('storyModal');
const _confirmModal = document.getElementById('confirmModal');
const _deleteConfirmModal = document.getElementById('deleteConfirmModal');
const _floatingCart = document.getElementById('floatingCart');
const _notifPopup = document.getElementById('notifPopup');
const _notifConfetti = document.getElementById('notifConfetti');
const _wilayaModal = document.getElementById('wilayaModal');

let _storyTimer = null;
let _storyIdx = 0;
let _storyImgs = [];
let _confirmCb = null;
let _deleteConfirmCb = null;
let _notifTimer = null;

function show(html) {
  if (_loader) _loader.style.display = 'none';
  if (_app) {
    _app.innerHTML = html;
    _app.style.display = 'block';
  }
  updateCartBadge();
}

function showError(msg) {
  show(`<div class="error-msg">${msg}</div>`);
}

function showToast(msg, type = 'success') {
  if (!_toast) return;
  _toast.textContent = msg;
  _toast.className = 'toast show ' + type;
  setTimeout(() => { _toast.className = 'toast'; }, 3000);
}

function showToastError(msg) { showToast(msg, 'error'); }

const SOCIAL = {
  instagram: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><rect x="2" y="2" width="20" height="20" rx="5" stroke="#E4405F" stroke-width="2"/><circle cx="12" cy="12" r="5" stroke="#E4405F" stroke-width="2"/><circle cx="17.5" cy="6.5" r="1.5" fill="#E4405F"/></svg>`,
    color: '#E4405F'
  },
  facebook: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z" stroke="#1877F2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    color: '#1877F2'
  },
  tiktok: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M9 12a4 4 0 1 0 4 4V4a5 5 0 0 0 5 5" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    color: '#000'
  },
  linkedin: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z" stroke="#0A66C2" stroke-width="2"/><rect x="2" y="9" width="4" height="12" stroke="#0A66C2" stroke-width="2"/><circle cx="4" cy="4" r="2" stroke="#0A66C2" stroke-width="2"/></svg>`,
    color: '#0A66C2'
  },
  whatsapp: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" stroke="#25D366" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    color: '#25D366'
  },
  youtube: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M22.54 6.42a2.78 2.78 0 0 0-1.94-2C18.88 4 12 4 12 4s-6.88 0-8.6.46a2.78 2.78 0 0 0-1.94 2A29 29 0 0 0 1 11.75a29 29 0 0 0 .46 5.33A2.78 2.78 0 0 0 3.4 19.1c1.72.46 8.6.46 8.6.46s6.88 0 8.6-.46a2.78 2.78 0 0 0 1.94-2 29 29 0 0 0 .46-5.25 29 29 0 0 0-.46-5.43z" stroke="#FF0000" stroke-width="2"/><polygon points="9.75,15.02 15.5,11.75 9.75,8.48" stroke="#FF0000" stroke-width="2" stroke-linejoin="round"/></svg>`,
    color: '#FF0000'
  },
  twitter: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M23 3a10.9 10.9 0 0 1-3.14 1.53 4.48 4.48 0 0 0-7.86 3v1A10.66 10.66 0 0 1 3 4s-4 9 5 13a11.64 11.64 0 0 1-7 2c9 5 20 0 20-11.5a4.5 4.5 0 0 0-.08-.83A7.72 7.72 0 0 0 23 3z" stroke="#1DA1F2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    color: '#1DA1F2'
  },
  telegram: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><line x1="22" y1="2" x2="11" y2="13" stroke="#0088cc" stroke-width="2"/><polygon points="22,2 15,22 11,13 2,9" stroke="#0088cc" stroke-width="2" stroke-linejoin="round"/></svg>`,
    color: '#0088cc'
  },
  snapchat: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M12 2C8 2 6 5 6 8v2c-1 0-2 .5-2 1s1 1 2 1c0 2-3 4-3 4s1 2 3 2c0 .5 0 1-.5 1.5S6 19 6 19s2 1 6 1 6-1 6-1-1.5-.5-1.5-1.5S18 15 18 15c2 0 3-2 3-2s1-1 2-1 2-.5 2-1-1-1-2-1V8c0-3-2-6-6-6z" stroke="#FFFC00" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    color: '#FFFC00'
  },
  phone: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" stroke="#059669" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    color: '#059669'
  },
  email: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="#EA4335" stroke-width="2"/><polyline points="22,6 12,13 2,6" stroke="#EA4335" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    color: '#EA4335'
  },
  location: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" stroke="#E4405F" stroke-width="2"/><circle cx="12" cy="10" r="3" stroke="#E4405F" stroke-width="2"/></svg>`,
    color: '#E4405F'
  },
  cash: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><rect x="1" y="4" width="22" height="16" rx="2" stroke="#059669" stroke-width="2"/><circle cx="12" cy="12" r="3" stroke="#059669" stroke-width="2"/><path d="M1 10h2m18 0h2M1 14h2m18 0h2" stroke="#059669" stroke-width="2" stroke-linecap="round"/></svg>`,
    color: '#059669'
  },
  default: {
    svg: `<svg viewBox="0 0 24 24" fill="none"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" stroke="#6C63FF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" stroke="#6C63FF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    color: '#6C63FF'
  }
};

const WILAYAS = [
  {code:'01',name:'Adrar',price:700},{code:'02',name:'Chlef',price:500},{code:'03',name:'Laghouat',price:700},
  {code:'04',name:'Oum El Bouaghi',price:500},{code:'05',name:'Batna',price:500},{code:'06',name:'Béjaïa',price:400},
  {code:'07',name:'Biskra',price:600},{code:'08',name:'Béchar',price:800},{code:'09',name:'Blida',price:350},
  {code:'10',name:'Bouira',price:400},{code:'11',name:'Tamanrasset',price:900},{code:'12',name:'Tébessa',price:500},
  {code:'13',name:'Tlemcen',price:500},{code:'14',name:'Tiaret',price:500},{code:'15',name:'Tizi Ouzou',price:350},
  {code:'16',name:'Alger',price:300},{code:'17',name:'Djelfa',price:600},{code:'18',name:'Jijel',price:400},
  {code:'19',name:'Sétif',price:450},{code:'20',name:'Saïda',price:550},{code:'21',name:'Skikda',price:400},
  {code:'22',name:'Sidi Bel Abbès',price:500},{code:'23',name:'Annaba',price:450},{code:'24',name:'Guelma',price:450},
  {code:'25',name:'Constantine',price:450},{code:'26',name:'Médéa',price:400},{code:'27',name:'Mostaganem',price:500},
  {code:'28',name:"M'Sila",price:500},{code:'29',name:'Mascara',price:500},{code:'30',name:'Ouargla',price:700},
  {code:'31',name:'Oran',price:400},{code:'32',name:'El Bayadh',price:600},{code:'33',name:'Illizi',price:900},
  {code:'34',name:'Bordj Bou Arréridj',price:450},{code:'35',name:'Boumerdès',price:350},{code:'36',name:'El Tarf',price:450},
  {code:'37',name:'Tindouf',price:900},{code:'38',name:'Tissemsilt',price:500},{code:'39',name:'El Oued',price:600},
  {code:'40',name:'Khenchela',price:500},{code:'41',name:'Souk Ahras',price:500},{code:'42',name:'Tipaza',price:350},
  {code:'43',name:'Mila',price:450},{code:'44',name:'Aïn Defla',price:400},{code:'45',name:'Naâma',price:700},
  {code:'46',name:'Aïn Témouchent',price:500},{code:'47',name:'Ghardaïa',price:700},{code:'48',name:'Relizane',price:500},
  {code:'49',name:'El M\'Ghair',price:600},{code:'50',name:'El Meniaa',price:700},{code:'51',name:'Ouled Djellal',price:600},
  {code:'52',name:'Bordj Badji Mokhtar',price:900},{code:'53',name:'Béni Abbès',price:800},{code:'54',name:'Timimoun',price:800},
  {code:'55',name:'Touggourt',price:700},{code:'56',name:'Djanet',price:900},{code:'57',name:'In Salah',price:800},
  {code:'58',name:'In Guezzam',price:900}
];

let _communes = [];
let _communesByWilaya = {};
let _communesLoaded = false;

async function loadCommunes() {
  if (_communesLoaded) return;
  try {
    const r = await fetch('https://cdn.jsdelivr.net/npm/geoalgeria/data/ecommerce/communes.json');
    _communes = await r.json();
    _communesByWilaya = {};
    for (const c of _communes) {
      const w = String(c.wilaya_code).padStart(2, '0');
      if (!_communesByWilaya[w]) _communesByWilaya[w] = [];
      _communesByWilaya[w].push(c);
    }
    _communesLoaded = true;
  } catch(e) { console.error('Failed to load communes', e); }
}

function getSocialIcon(type) {
  return SOCIAL[type] || SOCIAL.default;
}

function formatPrice(p) {
  return Number(p).toLocaleString('fr-DZ') + ' DZD';
}

function timeAgo(d) {
  const s = Math.floor((Date.now() - new Date(d)) / 1000);
  if (s < 60) return "à l'instant";
  const m = Math.floor(s / 60);
  if (m < 60) return m + 'min';
  const h = Math.floor(m / 60);
  if (h < 24) return h + 'h';
  const j = Math.floor(h / 24);
  return j + 'j';
}

function formatJoinDate(d) {
  return 'Inscrit en ' + new Date(d).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
}

function getInitials(name) {
  if (!name) return '?';
  return name.split(' ').map(w => w[0]).join('').substring(0, 2).toUpperCase();
}

// === Cart ===
function getCart() {
  try { return JSON.parse(localStorage.getItem('linky_cart') || '[]'); } catch { return []; }
}

function saveCart(cart) {
  localStorage.setItem('linky_cart', JSON.stringify(cart));
}

function addToCart(product, store, qty = 1, opts = {}) {
  const cart = getCart();
  const key = product.id + '-' + JSON.stringify(opts);
  const existing = cart.find(i => i.key === key);
  if (existing) {
    existing.qty += qty;
  } else {
    cart.push({
      key, productId: product.id, storeId: store.id || store.slug,
      storeSlug: store.slug, storeName: store.name || store.store_name,
      name: product.name || product.title, price: Number(product.price),
      image: product.image || product.images?.[0] || '',
      qty, opts
    });
  }
  saveCart(cart);
  updateCartBadge();
  showToast('Ajouté au panier');
}

function removeFromCart(key) {
  const cart = getCart().filter(i => i.key !== key);
  saveCart(cart);
  updateCartBadge();
}

function getCartCount() {
  return getCart().reduce((s, i) => s + i.qty, 0);
}

function getCartTotal() {
  return getCart().reduce((s, i) => s + i.price * i.qty, 0);
}

function updateCartBadge() {
  if (!_floatingCart) return;
  const count = getCartCount();
  if (count > 0) {
    _floatingCart.style.display = 'flex';
    _floatingCart.innerHTML = `<svg viewBox="0 0 24 24"><path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke="white" fill="none" stroke-width="2"/><line x1="3" y1="6" x2="21" y2="6" stroke="white" stroke-width="2"/><path d="M16 10a4 4 0 01-8 0" stroke="white" fill="none" stroke-width="2"/></svg><span class="badge">${count}</span>`;
    _floatingCart.onclick = () => {
      const m = window.location.pathname.match(/\/@([^/]+)/);
      if (m) window.location.href = `/@${m[1]}/cart`;
    };
  } else {
    _floatingCart.style.display = 'none';
  }
}

// === Stories ===
function openStory(stories, idx = 0) {
  if (!_storyModal || !stories?.length) return;
  _storyImgs = stories;
  _storyIdx = idx;
  _storyModal.classList.add('active');
  document.body.style.overflow = 'hidden';
  renderStory();
}

function renderStory() {
  if (!_storyModal) return;
  const story = _storyImgs[_storyIdx];
  if (!story) { closeStory(); return; }
  const progress = _storyImgs.map((_, i) =>
    `<div class="bar ${i < _storyIdx ? 'filled' : i === _storyIdx ? 'filled' : ''}"></div>`
  ).join('');
  _storyModal.innerHTML = `
    <div class="story-progress">${progress}</div>
    <button class="story-close" onclick="closeStory()"><svg viewBox="0 0 24 24"><line x1="18" y1="6" x2="6" y2="18" stroke="white" stroke-width="2"/><line x1="6" y1="6" x2="18" y2="18" stroke="white" stroke-width="2"/></svg></button>
    <img class="story-img" src="${story.image || story.url || story}" alt="story">
    <div class="story-nav left" onclick="prevStory()"></div>
    <div class="story-nav right" onclick="nextStory()"></div>
  `;
  clearTimeout(_storyTimer);
  _storyTimer = setTimeout(nextStory, 5000);
}

function nextStory() {
  if (_storyIdx < _storyImgs.length - 1) { _storyIdx++; renderStory(); }
  else closeStory();
}

function prevStory() {
  if (_storyIdx > 0) { _storyIdx--; renderStory(); }
}

function closeStory() {
  clearTimeout(_storyTimer);
  if (_storyModal) _storyModal.classList.remove('active');
  document.body.style.overflow = '';
}

// === Confirm ===
function showConfirm(title, msg, onConfirm) {
  _confirmCb = onConfirm;
  if (_confirmModal) {
    _confirmModal.classList.add('active');
    _confirmModal.innerHTML = `
      <div class="confirm-box neu-flat">
        <h3>${title}</h3>
        <p>${msg}</p>
        <div class="c-btns">
          <button class="c-cancel" onclick="closeConfirm()">Annuler</button>
          <button class="c-confirm" onclick="doConfirm()">Confirmer</button>
        </div>
      </div>
    `;
  }
}

function doConfirm() {
  closeConfirm();
  if (_confirmCb) _confirmCb();
}

function closeConfirm() {
  if (_confirmModal) _confirmModal.classList.remove('active');
}

// === Delete Confirm ===
function _showDeleteConfirm(msg, onConfirm) {
  _deleteConfirmCb = onConfirm;
  if (_deleteConfirmModal) {
    _deleteConfirmModal.classList.add('active');
    _deleteConfirmModal.innerHTML = `
      <div class="confirm-box neu-flat">
        <h3>Supprimer</h3>
        <p>${msg || 'Êtes-vous sûr de vouloir supprimer cet article ?'}</p>
        <div class="c-btns">
          <button class="c-cancel" onclick="_closeDeleteConfirm()">Annuler</button>
          <button class="c-confirm" onclick="_doDeleteConfirm()">Supprimer</button>
        </div>
      </div>
    `;
  }
}

function _doDeleteConfirm() {
  _closeDeleteConfirm();
  if (_deleteConfirmCb) _deleteConfirmCb();
}

function _closeDeleteConfirm() {
  if (_deleteConfirmModal) _deleteConfirmModal.classList.remove('active');
}

// === Wilaya Picker ===
let _wilayaSelectCb = null;

function openWilayaPicker(callback) {
  _wilayaSelectCb = callback;
  if (!_wilayaModal) return;
  _wilayaModal.classList.add('active');
  loadCommunes().then(() => renderWilayaList());
}

function renderWilayaList(filter = '') {
  const list = _wilayaModal.querySelector('.wm-list');
  if (!list) return;
  const f = filter.toLowerCase();
  const filtered = WILAYAS.filter(w => !f || w.name.toLowerCase().includes(f));
  list.innerHTML = filtered.map(w => `
    <div class="wm-item" onclick="selectWilaya('${w.code}')">
      <span class="wm-name">${w.code} - ${w.name}</span>
      <span class="wm-price">${formatPrice(w.price)}</span>
    </div>
  `).join('') || '<div class="wm-c-empty">Aucune wilaya trouvée</div>';
}

function selectWilaya(code) {
  const w = WILAYAS.find(w => w.code === code);
  if (!w) return;
  showCommunes(code);
}

function showCommunes(wilayaCode) {
  const head = _wilayaModal.querySelector('.wm-head');
  const search = _wilayaModal.querySelector('.wm-search');
  const list = _wilayaModal.querySelector('.wm-list');
  const communes = _communesByWilaya[wilayaCode] || [];
  if (search) search.style.display = 'none';
  if (list) {
    list.innerHTML = `
      <div class="wm-back" onclick="backToWilayas()">
        <svg viewBox="0 0 24 24"><polyline points="15,18 9,12 15,6" stroke="currentColor" stroke-width="2" fill="none"/></svg>
        Retour
      </div>
      ${communes.map(c => `
        <div class="wm-c-item" onclick="pickCommune('${c.commune_name}', '${wilayaCode}')">
          ${c.commune_name}
        </div>
      `).join('') || '<div class="wm-c-empty">Aucune commune</div>'}
    `;
  }
}

function backToWilayas() {
  const search = _wilayaModal.querySelector('.wm-search');
  if (search) search.style.display = '';
  renderWilayaList();
}

function pickCommune(commune, wilayaCode) {
  const w = WILAYAS.find(w => w.code === wilayaCode);
  closeWilayaPicker();
  if (_wilayaSelectCb) _wilayaSelectCb({ wilaya: w, commune });
}

function closeWilayaPicker() {
  if (_wilayaModal) _wilayaModal.classList.remove('active');
}

// === Confetti ===
function launchConfetti() {
  if (!_notifConfetti) return;
  const ctx = _notifConfetti.getContext('2d');
  _notifConfetti.width = window.innerWidth;
  _notifConfetti.height = window.innerHeight;
  const particles = [];
  const colors = ['#5267FF', '#8B5CF6', '#F59E0B', '#059669', '#E4405F', '#1DA1F2'];
  for (let i = 0; i < 80; i++) {
    particles.push({
      x: Math.random() * _notifConfetti.width,
      y: -10 - Math.random() * 100,
      w: 6 + Math.random() * 6,
      h: 4 + Math.random() * 4,
      color: colors[Math.floor(Math.random() * colors.length)],
      vx: (Math.random() - .5) * 4,
      vy: 2 + Math.random() * 4,
      rot: Math.random() * Math.PI * 2,
      vr: (Math.random() - .5) * .2
    });
  }
  let frame = 0;
  function draw() {
    ctx.clearRect(0, 0, _notifConfetti.width, _notifConfetti.height);
    let alive = false;
    for (const p of particles) {
      if (p.y > _notifConfetti.height + 20) continue;
      alive = true;
      p.x += p.vx;
      p.y += p.vy;
      p.vy += .1;
      p.rot += p.vr;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot);
      ctx.fillStyle = p.color;
      ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
      ctx.restore();
    }
    frame++;
    if (alive && frame < 180) requestAnimationFrame(draw);
    else ctx.clearRect(0, 0, _notifConfetti.width, _notifConfetti.height);
  }
  draw();
}

// === Notification ===
function showNotif(name, amount, msg) {
  if (!_notifPopup) return;
  const a = getInitials(name);
  _notifPopup.innerHTML = `
    <div class="n-inner">
      <div class="n-icon"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" stroke="white" fill="none" stroke-width="2"/></svg></div>
      <div class="n-text">
        <strong>${a} vient de donner ${formatPrice(amount)}</strong>
        ${msg ? `<p>${msg}</p>` : ''}
      </div>
    </div>
  `;
  _notifPopup.style.display = 'block';
  launchConfetti();
  try { new Audio('https://cdn.pixabay.com/audio/2022/03/10/audio_090fcb999c.mp3').play(); } catch(e) {}
  clearTimeout(_notifTimer);
  _notifTimer = setTimeout(() => { _notifPopup.style.display = 'none'; }, 6000);
}

// === Topbar ===
function topbar(pageTitle) {
  return `
    <div class="topbar">
      <a href="/"><div class="logo">Linky</div></a>
      <div class="url-pill">
        <svg viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
        <span>linky-to.pages.dev${pageTitle ? '/' + pageTitle : ''}</span>
      </div>
    </div>
  `;
}

// === Keyboard for Stories ===
document.addEventListener('keydown', e => {
  if (_storyModal && _storyModal.classList.contains('active')) {
    if (e.key === 'ArrowRight') nextStory();
    else if (e.key === 'ArrowLeft') prevStory();
    else if (e.key === 'Escape') closeStory();
  }
});

// Init
updateCartBadge();
