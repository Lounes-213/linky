(function() {
  const m = window.location.pathname.match(/\/@([^/]+)\/portfolio\/([^/]+)/);
  if (!m) { showError('Portfolio introuvable'); return; }
  const username = m[1], portfolioId = m[2];

  async function init() {
    try {
      const r = await fetch(`${API}/api/public/${username}`);
      if (!r.ok) throw new Error('not found');
      const data = await r.json();
      const profile = data.profile || data;
      const portfolio = profile.portfolio || [];
      const item = portfolio.find(p => String(p.id) === String(portfolioId));
      if (!item) throw new Error('not found');

      let html = topbar(`${username}/portfolio/${portfolioId}`);
      html += `
        <div class="pd-hero">
          <div class="pd-img neu-flat"><img src="${item.image || item.thumbnail || ''}" alt="${item.title || 'Projet'}"></div>
          <div class="pd-info">
            <h1>${item.title || 'Projet'}</h1>
            <div class="pd-desc">${item.description || ''}</div>
            ${item.url ? `<a href="${item.url}" target="_blank" class="cta-btn" style="display:inline-block;margin-top:16px;padding:12px 24px;border-radius:20px;background:linear-gradient(135deg,var(--primary),var(--purple));color:white;font-weight:700;font-size:.85rem;">Voir le projet</a>` : ''}
          </div>
        </div>
      `;
      show(html);
    } catch(e) {
      showError('Projet introuvable.');
    }
  }

  init();
})();
