(function() {
  const m = window.location.pathname.match(/\/@([^/]+)\/s\/([^/]+)/);
  if (!m) { showError('Boutique introuvable'); return; }
  const username = m[1], slug = m[2];
  let currentCat = 'all';

  async function init() {
    try {
      const r = await fetch(`${API}/api/stores/${slug}`);
      if (!r.ok) throw new Error('not found');
      const data = await r.json();
      const store = data.store || data;
      const products = data.products || [];
      const categories = ['all', ...new Set(products.map(p => p.category).filter(Boolean))];

      render(store, products, categories);
    } catch(e) {
      showError('Boutique introuvable ou erreur de chargement.');
    }
  }

  function render(store, products, categories) {
    let html = topbar(`${username}/s/${slug}`);

    // Cover
    const cover = store.cover_image || store.banner || '';
    if (cover) {
      html += `<img class="store-cover" src="${cover}" alt="${store.name || store.store_name}">`;
    }

    // Hero
    const logo = store.logo || store.cover_image || '';
    html += `
      <div class="store-hero">
        <div class="store-hero-card neu-flat">
          <div class="s-logo"><img src="${logo}" alt="${store.name || store.store_name}"></div>
          <h1>${store.name || store.store_name}</h1>
          <div class="s-desc">${store.description || ''}</div>
          <div class="s-stats">
            <span><strong>${products.length}</strong> produits</span>
            <span><strong>${store.followers || 0}</strong> abonnés</span>
          </div>
        </div>
      </div>
    `;

    // Category Chips
    if (categories.length > 1) {
      html += `
        <div class="cat-chips" id="catChips">
          ${categories.map(c => `
            <div class="cat-chip ${c === currentCat ? 'active' : ''}" onclick="filterCat('${c}')">
              ${c === 'all' ? 'Tout' : c}
            </div>
          `).join('')}
        </div>
      `;
    }

    // Products Grid
    const filtered = currentCat === 'all' ? products : products.filter(p => p.category === currentCat);
    html += `
      <div class="products-grid">
        ${filtered.map(p => {
          const stock = p.stock ?? p.quantity ?? 0;
          const stockClass = stock <= 0 ? 'out' : stock <= 5 ? 'low' : 'in';
          const stockText = stock <= 0 ? 'Rupture de stock' : stock <= 5 ? `${stock} restants` : 'En stock';
          return `
            <div class="product-card neu-flat" onclick="window.location.href='/@${username}/p/${p.id}'">
              <div class="p-img"><img src="${p.image || p.images?.[0] || ''}" alt="${p.name || p.title}"></div>
              <div class="p-name">${p.name || p.title}</div>
              <div class="p-price">${formatPrice(p.price)}${p.old_price ? `<span class="p-old">${formatPrice(p.old_price)}</span>` : ''}</div>
              <div class="p-stock ${stockClass}">${stockText}</div>
            </div>
          `;
        }).join('')}
      </div>
    `;

    show(html);

    // Store the data for filtering
    window._storeData = { store, products, categories };
  }

  window.filterCat = function(cat) {
    currentCat = cat;
    const { store, products, categories } = window._storeData;
    render(store, products, categories);
  };

  init();
})();
