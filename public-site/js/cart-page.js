(function() {
  const m = window.location.pathname.match(/\/@([^/]+)\/s\/([^/]+)\/cart/);
  if (!m) { showError('Panier introuvable'); return; }
  const username = m[1], slug = m[2];

  function render() {
    const cart = getCart().filter(i => i.storeSlug === slug);
    const storeName = cart[0]?.storeName || slug;
    const total = cart.reduce((s, i) => s + i.price * i.qty, 0);

    let html = topbar(`${username}/s/${slug}/cart`);

    html += `
      <div class="cart-header">
        <h1>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke="#2D3436" stroke-width="2"/><line x1="3" y1="6" x2="21" y2="6" stroke="#2D3436" stroke-width="2"/><path d="M16 10a4 4 0 01-8 0" stroke="#2D3436" stroke-width="2"/></svg>
          Panier
          <span class="cnt">${cart.length} article${cart.length !== 1 ? 's' : ''}</span>
        </h1>
      </div>
    `;

    if (!cart.length) {
      html += `
        <div class="empty-cart">
          <div class="e-icon">🛒</div>
          <h3>Panier vide</h3>
          <p>Ajoutez des produits depuis la boutique</p>
        </div>
      `;
      show(html);
      return;
    }

    html += `<div class="cart-items">`;
    for (const item of cart) {
      const optsText = Object.entries(item.opts || {}).map(([k, v]) => `${k}: ${v}`).join(' · ');
      html += `
        <div class="cart-item neu-flat">
          <div class="ci-img"><img src="${item.image || ''}" alt="${item.name}"></div>
          <div class="ci-info">
            <div class="ci-name">${item.name}</div>
            ${optsText ? `<div class="ci-opts">${optsText}</div>` : ''}
            <div class="ci-price">${formatPrice(item.price * item.qty)}</div>
          </div>
          <button class="ci-del" onclick="delItem('${item.key}')">
            <svg viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
          </button>
        </div>
      `;
    }
    html += `</div>`;

    // Footer
    html += `
      <div class="cart-footer">
        <div class="cart-total neu-flat" style="padding:16px 20px;">
          <span class="t-lab">Total</span>
          <span class="t-val">${formatPrice(total)}</span>
        </div>
        <button class="cart-sms-btn" onclick="sendSMS()">
          <svg viewBox="0 0 24 24"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          Commander via SMS
        </button>
      </div>
    `;

    show(html);
  }

  window.delItem = function(key) {
    _showDeleteConfirm('Supprimer cet article du panier ?', () => {
      removeFromCart(key);
      render();
    });
  };

  window.sendSMS = function() {
    const cart = getCart().filter(i => i.storeSlug === slug);
    if (!cart.length) return;
    const storePhone = cart[0]?.storePhone || '';
    const total = cart.reduce((s, i) => s + i.price * i.qty, 0);
    let msg = `Bonjour, je souhaite commander :\n\n`;
    for (const item of cart) {
      const optsText = Object.entries(item.opts || {}).map(([k, v]) => `${k}: ${v}`).join(', ');
      msg += `- ${item.name}${optsText ? ` (${optsText})` : ''} x${item.qty} = ${formatPrice(item.price * item.qty)}\n`;
    }
    msg += `\nTotal : ${formatPrice(total)}`;
    if (storePhone) {
      window.open(`sms:${storePhone}?body=${encodeURIComponent(msg)}`, '_blank');
    } else {
      // Copy to clipboard
      navigator.clipboard?.writeText(msg).then(() => showToast('Message copié'));
    }
  };

  render();
})();
