(function() {
  const m = window.location.pathname.match(/\/@([^/]+)\/donation/);
  if (!m) { showError('Page de donation introuvable'); return; }
  const username = m[1];
  let profile = null;
  let selectedAmount = 0;
  let selectedPayment = null;
  let donorName = '';
  let donorMsg = '';

  async function init() {
    try {
      const r = await fetch(`${API}/api/public/${username}`);
      if (!r.ok) throw new Error('not found');
      const data = await r.json();
      profile = data.profile || data;
      loadCommunes().then(() => render());
      render();
    } catch(e) {
      showError('Utilisateur introuvable.');
    }
  }

  function render() {
    if (!profile) return;
    const avatar = profile.avatar_url
      ? `<img src="${profile.avatar_url}" alt="${profile.display_name || username}" style="width:100%;height:100%;border-radius:50%;object-fit:cover;">`
      : getInitials(profile.display_name || username);

    let html = topbar(`${username}/donation`);

    // Hero
    html += `
      <div class="donation-hero">
        <div class="d-avatar">${avatar}</div>
        <h1>Soutenir ${profile.display_name || username}</h1>
        <p>Votre soutien compte énormément</p>
      </div>
    `;

    // Amount grid
    const amounts = [100, 200, 500, 1000, 2000, 5000];
    html += `
      <div class="donation-amounts">
        <h3 class="section-title">Montant</h3>
        <div class="amounts-grid">
          ${amounts.map(a => `
            <button class="amount-btn ${selectedAmount === a ? 'active' : ''}" onclick="selectAmount(${a})">${a} DZD</button>
          `).join('')}
        </div>
        <input type="number" class="custom-amount" placeholder="Montant personnalisé (DZD)" oninput="customAmount(this.value)">
      </div>
    `;

    // Payment methods
    html += `
      <div class="donation-payments">
        <h3 class="section-title">Mode de paiement</h3>
        <div class="payments-grid">
          <button class="payment-btn neu-flat ${selectedPayment === 'ccp' ? 'active' : ''}" onclick="selectPayment('ccp')">
            <div class="p-icon" style="background:rgba(82,103,255,.1);">🏦</div>
            <div class="p-info"><h4>CCP</h4><p>Virement bancaire</p></div>
          </button>
          <button class="payment-btn neu-flat ${selectedPayment === 'baridimob' ? 'active' : ''}" onclick="selectPayment('baridimob')">
            <div class="p-icon" style="background:rgba(5,150,105,.1);">📱</div>
            <div class="p-info"><h4>BaridiMob</h4><p>Paiement mobile</p></div>
          </button>
          <button class="payment-btn neu-flat ${selectedPayment === 'redotpay' ? 'active' : ''}" onclick="selectPayment('redotpay')">
            <div class="p-icon" style="background:rgba(139,92,246,.1);">💳</div>
            <div class="p-info"><h4>RedotPay</h4><p>Crypto & carte</p></div>
          </button>
        </div>
      </div>
    `;

    // Donor input
    html += `
      <div class="donor-input">
        <h3 class="section-title">Votre nom (optionnel)</h3>
        <input type="text" placeholder="Anonyme" value="${donorName}" oninput="donorName=this.value">
        <div style="height:12px;"></div>
        <h3 class="section-title">Message (optionnel)</h3>
        <textarea rows="2" placeholder="Encouragez-le..." oninput="donorMsg=this.value">${donorMsg}</textarea>
      </div>
    `;

    // Donate button
    html += `
      <div class="donate-btn-wrap">
        <button class="donate-btn" onclick="donate()" ${!selectedAmount || !selectedPayment ? 'disabled' : ''}>
          Donner ${selectedAmount ? formatPrice(selectedAmount) : ''}
        </button>
      </div>
    `;

    // Recent donations
    html += `
      <div class="recent-donations" id="recentDonations">
        <h3>Dons récents</h3>
        <div class="loader">Chargement...</div>
      </div>
    `;

    show(html);
    loadRecentDonations();
  }

  async function loadRecentDonations() {
    try {
      const r = await fetch(`${API}/api/donations/feed/${username}`);
      if (!r.ok) return;
      const data = await r.json();
      const donations = data.donations || data || [];
      const el = document.getElementById('recentDonations');
      if (!el) return;
      if (!donations.length) {
        el.innerHTML = '<h3>Dons récents</h3><p style="color:var(--text-muted);font-size:.85rem;">Aucun don pour l\'instant</p>';
        return;
      }
      el.innerHTML = `
        <h3>Dons récents</h3>
        ${donations.slice(0, 10).map(d => `
          <div class="donation-row">
            <div class="d-avatar">${getInitials(d.donor_name || 'Anonyme')}</div>
            <div class="d-info">
              <div class="d-name">${d.donor_name || 'Anonyme'}</div>
              ${d.message ? `<div class="d-msg">${d.message}</div>` : ''}
            </div>
            <div style="text-align:right;">
              <div class="d-amount">${formatPrice(d.amount)}</div>
              <div class="d-time">${timeAgo(d.created_at)}</div>
            </div>
          </div>
        `).join('')}
      `;
    } catch(e) {}
  }

  window.selectAmount = function(a) {
    selectedAmount = a;
    render();
  };

  window.customAmount = function(v) {
    selectedAmount = Number(v) || 0;
    render();
  };

  window.selectPayment = function(p) {
    selectedPayment = p;
    render();
  };

  window.donate = async function() {
    if (!selectedAmount || !selectedPayment) return;
    try {
      const r = await fetch(`${API}/api/donations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId: username,
          amount: selectedAmount,
          payment_method: selectedPayment,
          donor_name: donorName || 'Anonyme',
          message: donorMsg
        })
      });
      if (r.ok) {
        showSuccess();
      } else {
        showToastError('Erreur lors du don');
      }
    } catch(e) {
      showToastError('Erreur de connexion');
    }
  };

  function showSuccess() {
    const overlay = document.createElement('div');
    overlay.className = 'success-overlay';
    overlay.innerHTML = `
      <div class="success-card neu-flat">
        <div class="check"><svg viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg></div>
        <h2>Merci pour votre don !</h2>
        <p>Votre soutien de ${formatPrice(selectedAmount)} a bien été enregistré.</p>
        <button class="back-btn" onclick="this.closest('.success-overlay').remove()">Retour</button>
      </div>
    `;
    document.body.appendChild(overlay);
    launchConfetti();
    showNotif(donorName || 'Anonyme', selectedAmount, donorMsg);
    loadRecentDonations();
  }

  init();
})();
