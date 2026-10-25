(function() {
  const m = window.location.pathname.match(/\/@([^/]+)\/p\/([^/]+)/);
  if (!m) { showError('Produit introuvable'); return; }
  const username = m[1], productId = m[2];
  let product = null, store = null, qty = 1, selectedColor = null, selectedSize = null, selectedOption = null;

  async function init() {
    try {
      const r = await fetch(`${API}/api/products/${productId}`);
      if (!r.ok) throw new Error('not found');
      const data = await r.json();
      product = data.product || data;
      store = data.store || {};
      render();
    } catch(e) {
      showError('Produit introuvable ou erreur de chargement.');
    }
  }

  function getDisplayPrice() {
    let price = Number(product.price) || 0;
    if (selectedColor && product.color_extras?.[selectedColor]) price += Number(product.color_extras[selectedColor]) || 0;
    if (selectedSize && product.size_extras?.[selectedSize]) price += Number(product.size_extras[selectedSize]) || 0;
    if (selectedOption && product.option_extras?.[selectedOption]) price += Number(product.option_extras[selectedOption]) || 0;
    return price;
  }

  function render() {
    const stock = product.stock ?? product.quantity ?? 0;
    const stockClass = stock <= 0 ? 'out' : stock <= 5 ? 'low' : 'in';
    const stockText = stock <= 0 ? 'Rupture de stock' : stock <= 5 ? `${stock} restants` : 'En stock';
    const displayPrice = getDisplayPrice();
    const images = product.images?.length ? product.images : [product.image || ''];
    const colors = product.colors?.length ? product.colors : null;
    const sizes = product.sizes?.length ? product.sizes : null;
    const options = product.options?.length ? product.options : null;

    let html = topbar(`${username}/p/${productId}`);

    // Hero image
    html += `
      <div class="pd-hero">
        <div class="pd-img neu-flat"><img src="${images[0]}" alt="${product.name || product.title}"></div>
        <div class="pd-info">
          <h1>${product.name || product.title}</h1>
          <div class="pd-price">${formatPrice(displayPrice)}</div>
          ${product.old_price ? `<div class="pd-old">${formatPrice(product.old_price)}</div>` : ''}
          <div class="pd-desc">${product.description || ''}</div>
          <div class="pd-stock ${stockClass}">${stockText}</div>
        </div>
      </div>
    `;

    // Variant selectors
    html += `<div class="pd-variants">`;

    if (colors) {
      html += `
        <div class="pd-var-group">
          <label>Couleur</label>
          <div class="pd-colors">
            ${colors.map(c => `
              <div class="pd-color ${selectedColor === c ? 'active' : ''}" style="background:${c}" onclick="selectColor('${c}')"></div>
            `).join('')}
          </div>
        </div>
      `;
    }

    if (sizes) {
      html += `
        <div class="pd-var-group">
          <label>Taille</label>
          <div class="pd-sizes">
            ${sizes.map(s => `
              <div class="pd-size ${selectedSize === s ? 'active' : ''}" onclick="selectSize('${s}')">${s}</div>
            `).join('')}
          </div>
        </div>
      `;
    }

    if (options) {
      html += `
        <div class="pd-var-group">
          <label>Option</label>
          <div class="pd-options">
            ${options.map(o => `
              <div class="pd-opt ${selectedOption === o ? 'active' : ''}" onclick="selectOption('${o}')">${o}</div>
            `).join('')}
          </div>
          ${((selectedColor && product.color_extras?.[selectedColor]) || (selectedSize && product.size_extras?.[selectedSize]) || (selectedOption && product.option_extras?.[selectedOption])) ? `
            <div class="pd-extras">+ ${formatPrice(
              (product.color_extras?.[selectedColor] || 0) +
              (product.size_extras?.[selectedSize] || 0) +
              (product.option_extras?.[selectedOption] || 0)
            )}</div>
          ` : ''}
        </div>
      `;
    }

    html += `</div>`;

    // Bottom bar
    html += `
      <div class="pd-bottom neu-flat">
        <div class="pd-qty">
          <button onclick="changeQty(-1)">−</button>
          <span id="qtyVal">${qty}</span>
          <button onclick="changeQty(1)">+</button>
        </div>
        <button class="pd-add-btn" onclick="addProdToCart()" ${stock <= 0 ? 'disabled' : ''}>
          Ajouter au panier · ${formatPrice(displayPrice * qty)}
        </button>
      </div>
    `;

    show(html);
  }

  window.selectColor = function(c) { selectedColor = c; render(); };
  window.selectSize = function(s) { selectedSize = s; render(); };
  window.selectOption = function(o) { selectedOption = o; render(); };

  window.changeQty = function(d) {
    qty = Math.max(1, qty + d);
    render();
  };

  window.addProdToCart = function() {
    if (!product || !store) return;
    const opts = {};
    if (selectedColor) opts.color = selectedColor;
    if (selectedSize) opts.size = selectedSize;
    if (selectedOption) opts.option = selectedOption;
    addToCart(product, store, qty, opts);
  };

  init();
})();
