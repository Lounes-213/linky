(function() {
  const m = window.location.pathname.match(/\/@([^/]+)/);
  if (!m) { showError('Profil introuvable'); return; }
  const username = m[1];

  async function init() {
    try {
      const r = await fetch(`${API}/api/public/${username}`);
      if (!r.ok) throw new Error('not found');
      const data = await r.json();
      const p = data.profile || data;
      const stores = data.stores || [];
      const products = data.products || [];
      const stories = data.stories || [];
      const donation = data.donation || null;
      const stats = p.stats || { links: 0, stores: 0, followers: 0, rating: 0 };

      let html = topbar(username);

      // Hero
      const avatar = p.avatar_url
        ? `<img src="${p.avatar_url}" alt="${p.display_name || username}">`
        : getInitials(p.display_name || username);
      html += `
        <div class="profile-hero">
          <div class="profile-hero-card neu-flat">
            <div class="profile-avatar">${avatar}</div>
            <h1>${p.display_name || username}</h1>
            <div class="uname">@${username}</div>
            <div class="joined">
              <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
              ${formatJoinDate(p.created_at)}
            </div>
          </div>
        </div>
      `;

      // Stats
      html += `
        <div class="profile-stats">
          <div class="stat neu-flat">
            <div class="icon"><svg viewBox="0 0 24 24"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg></div>
            <div class="val">${stats.links || 0}</div>
            <div class="lab">Liens</div>
          </div>
          <div class="stat neu-flat">
            <div class="icon"><svg viewBox="0 0 24 24"><path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 01-8 0"/></svg></div>
            <div class="val">${stores.length || stats.stores || 0}</div>
            <div class="lab">Boutiques</div>
          </div>
          <div class="stat neu-flat">
            <div class="icon"><svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></div>
            <div class="val">${stats.followers || 0}</div>
            <div class="lab">Abonnés</div>
          </div>
          <div class="stat neu-flat">
            <div class="icon"><svg viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></div>
            <div class="val">${stats.rating || '0.0'}</div>
            <div class="lab">Note</div>
          </div>
        </div>
      `;

      // Stories
      if (stories.length) {
        html += `
          <div class="section-pad">
            <div class="stories-row">
              <h3>Stories</h3>
              <div class="stories-scroll">
                ${stories.map((s, i) => `
                  <div class="story-ring" onclick="openStory(${JSON.stringify(stories).replace(/"/g, '&quot;')}, ${i})">
                    <div class="sr"><div class="si"><img src="${s.image || s.url}" alt="story"></div></div>
                    <span>${s.title || 'Story'}</span>
                  </div>
                `).join('')}
              </div>
            </div>
          </div>
        `;
      }

      // Links
      const links = p.links || [];
      if (links.length) {
        html += `
          <div class="section-pad">
            <h3 class="section-title">Liens</h3>
            <div class="links-grid">
              ${links.map(l => {
                const si = getSocialIcon(l.type || 'default');
                return `
                  <a href="${l.url}" target="_blank" class="link-card neu-flat">
                    <div class="icon">${si.svg}</div>
                    <div class="name">${l.title || l.type || 'Lien'}</div>
                    <div class="clicks">${l.clicks || 0} clics</div>
                  </a>
                `;
              }).join('')}
            </div>
          </div>
        `;
      }

      // Featured Products
      if (products.length) {
        html += `
          <div class="section-pad">
            <div class="featured-products">
              <h3>Produits en vedette</h3>
              <div class="products-scroll">
                ${products.slice(0, 6).map(p => `
                  <div class="mini-product" onclick="window.location.href='/@${username}/p/${p.id}'">
                    <div class="mp-img"><img src="${p.image || p.images?.[0] || ''}" alt="${p.name || p.title}"></div>
                    <div class="mp-name">${p.name || p.title}</div>
                    <div class="mp-price">${formatPrice(p.price)}</div>
                  </div>
                `).join('')}
              </div>
            </div>
          </div>
        `;
      }

      // Stores
      if (stores.length) {
        html += `
          <div class="section-pad">
            <h3 class="section-title">Boutiques</h3>
            <div class="stores-list">
              ${stores.map(s => `
                <div class="store-row neu-flat" onclick="window.location.href='/@${username}/s/${s.slug || s.id}'">
                  <div class="s-logo"><img src="${s.logo || s.cover_image || ''}" alt="${s.name || s.store_name}"></div>
                  <div class="s-info">
                    <div class="s-name">${s.name || s.store_name}</div>
                    <div class="s-desc">${s.description || ''}</div>
                  </div>
                  <div class="s-arrow">›</div>
                </div>
              `).join('')}
            </div>
          </div>
        `;
      }

      // Portfolio
      const portfolio = p.portfolio || [];
      if (portfolio.length) {
        html += `
          <div class="section-pad">
            <div class="portfolio">
              <h3>Portfolio</h3>
              <div class="port-scroll">
                ${portfolio.map(item => `
                  <div class="port-item neu-flat" onclick="window.location.href='/@${username}/portfolio/${item.id}'">
                    <img src="${item.image || item.thumbnail || ''}" alt="${item.title || 'Projet'}">
                    <div class="pi-cap">
                      <h4>${item.title || 'Projet'}</h4>
                      <p>${item.description || ''}</p>
                    </div>
                  </div>
                `).join('')}
              </div>
            </div>
          </div>
        `;
      }

      // Donation CTA
      html += `
        <div class="section-pad">
          <div class="donation-cta">
            <div class="donation-cta-card neu-flat" onclick="window.location.href='/@${username}/donation'">
              <div class="d-icon">❤️</div>
              <h3>Soutenir ${p.display_name || username}</h3>
              <p>Votre soutien compte énormément</p>
              <div class="d-btn">
                <svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
                Faire un don
              </div>
            </div>
          </div>
        </div>
      `;

      show(html);
    } catch(e) {
      showError('Profil introuvable ou erreur de chargement.');
    }
  }

  init();
})();
