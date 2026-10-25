import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api/api_service.dart';
import 'store_landing_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.username});
  final String username;
  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await _api.get('/api/public/${Uri.encodeComponent(widget.username)}');
    if (mounted) setState(() {
      _profile = response.isSuccess ? response.data : null;
      _loading = false;
    });
  }

  String get _name => (_profile?['name']?.toString().trim().isNotEmpty ?? false)
      ? _profile!['name'].toString() : widget.username;
  String get _bio => _profile?['bio']?.toString() ?? '';
  String get _avatar => _profile?['avatar_url']?.toString() ?? '';
  String get _country => _profile?['country']?.toString() ?? '';
  String get _state => _profile?['state']?.toString() ?? '';
  String get _createdAt => _profile?['created_at']?.toString() ?? '';
  bool get _isVerified => _profile?['is_verified'] == 1;
  List<dynamic> get _links => _profile?['links'] as List<dynamic>? ?? const [];
  List<dynamic> get _socials => _profile?['social_links'] as List<dynamic>? ?? const [];
  List<dynamic> get _stores => _profile?['stores'] as List<dynamic>? ?? const [];
  List<dynamic> get _products => _profile?['featured_products'] as List<dynamic>? ?? const [];
  List<dynamic> get _portfolio => _profile?['portfolio'] as List<dynamic>? ?? const [];
  int get _followersCount => _profile?['followers_count'] ?? 0;
  int get _projectsCount => _profile?['projects_count'] ?? 0;

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) { return dateStr; }
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openLink(Map<String, dynamic> item) async {
    final url = item['url']?.toString() ?? '';
    final id = item['id'];
    if (id != null) _api.post('/api/public/${Uri.encodeComponent(widget.username)}/links/$id/click');
    _openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF5267FF))));
    if (_profile == null) {
      return const Scaffold(
        body: Center(child: Text('Profil introuvable', style: TextStyle(fontSize: 18, color: Colors.grey))),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final side = isMobile ? 16.0 : (width - 720) / 2;

    final sectionOrder = (_profile?['section_order'] as List<dynamic>?) ?? [];
    final visibility = <String, bool>{};
    final order = <String, int>{};
    for (var i = 0; i < sectionOrder.length; i++) {
      final s = sectionOrder[i];
      visibility[s['key']?.toString() ?? ''] = s['visible'] ?? true;
      order[s['key']?.toString() ?? ''] = s['order'] ?? i;
    }

    final sections = <Widget>[];
    sections.add(_buildNavBar(isMobile));
    sections.add(_buildHeroSection(side, isMobile));
    sections.add(SizedBox(height: isMobile ? 24 : 32));
    sections.add(_buildStatsRow(side, isMobile));

    final sectionWidgets = <int, Widget>{};
    if (visibility['links'] ?? true) sectionWidgets[order['links'] ?? 0] = _buildLinksSection(side, isMobile);
    if ((visibility['stores'] ?? true) && _stores.isNotEmpty) sectionWidgets[order['stores'] ?? 1] = _buildStoresSection(side, isMobile);
    if ((visibility['portfolio'] ?? true) && _portfolio.isNotEmpty) sectionWidgets[order['portfolio'] ?? 2] = _buildPortfolioSection(side, isMobile);
    if ((visibility['products'] ?? true) && _products.isNotEmpty) sectionWidgets[order['products'] ?? 3] = _buildProductsSection(side, isMobile);

    final sortedKeys = sectionWidgets.keys.toList()..sort();
    for (final key in sortedKeys) {
      sections.add(SizedBox(height: isMobile ? 28 : 36));
      sections.add(sectionWidgets[key]!);
    }

    sections.add(SizedBox(height: 40));
    sections.add(_buildFooter());
    sections.add(SizedBox(height: 30));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(children: sections),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 10),
      child: Row(
        children: [
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.maybePop(context),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text('linky.com/${widget.username}', style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: 'https://linky-to.pages.dev/@${widget.username}'));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lien copié'), backgroundColor: Color(0xFF5267FF)));
            },
            icon: const Icon(Icons.ios_share_rounded, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(double side, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: side),
      padding: EdgeInsets.fromLTRB(24, isMobile ? 28 : 36, 24, isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFE0E7FF), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: isMobile ? _buildMobileHero() : _buildDesktopHero(),
    );
  }

  Widget _buildMobileHero() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _avatar.isNotEmpty ? NetworkImage(_avatar) : null,
                child: _avatar.isEmpty ? Icon(Icons.person, size: 48, color: Colors.grey.shade400) : null,
              ),
            ),
            if (_isVerified)
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF5267FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            if (_isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, color: Color(0xFF5267FF), size: 22),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text('@${widget.username}', style: const TextStyle(
          color: Color(0xFF5267FF), fontWeight: FontWeight.w700, fontSize: 15)),
        if (_bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(_bio, textAlign: TextAlign.center, style: const TextStyle(
            fontSize: 15, height: 1.5, color: Color(0xFF64748B))),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
          children: [
            if (_country.isNotEmpty)
              _heroPill(Icons.location_on_outlined, '$_country${_state.isNotEmpty ? ', $_state' : ''}'),
            if (_createdAt.isNotEmpty)
              _heroPill(Icons.calendar_today_outlined, _formatDate(_createdAt)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHero() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _avatar.isNotEmpty ? NetworkImage(_avatar) : null,
                child: _avatar.isEmpty ? Icon(Icons.person, size: 54, color: Colors.grey.shade400) : null,
              ),
            ),
            if (_isVerified)
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF5267FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 15),
              ),
          ],
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  if (_isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Color(0xFF5267FF), size: 24),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text('@${widget.username}', style: const TextStyle(
                color: Color(0xFF5267FF), fontWeight: FontWeight.w700, fontSize: 16)),
              if (_bio.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(_bio, style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF64748B))),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10, runSpacing: 8,
                children: [
                  if (_country.isNotEmpty)
                    _heroPill(Icons.location_on_outlined, '$_country${_state.isNotEmpty ? ', $_state' : ''}'),
                  if (_createdAt.isNotEmpty)
                    _heroPill(Icons.calendar_today_outlined, _formatDate(_createdAt)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF5267FF)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildStatsRow(double side, bool isMobile) {
    final storesCount = _stores.length;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem(Icons.storefront_outlined, '$storesCount', 'Boutiques', const Color(0xFF5267FF)),
            _statDivider(isMobile),
            _statItem(Icons.folder_outlined, '$_projectsCount', 'Projets', const Color(0xFF8B5CF6)),
            _statDivider(isMobile),
            _statItem(Icons.people_outline, _formatCount(_followersCount), 'Abonnés', const Color(0xFF06B6D4)),
            _statDivider(isMobile),
            _statItem(Icons.star_rounded, '0', 'Note', const Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _statDivider(bool isMobile) {
    return Container(width: 1, height: isMobile ? 36 : 40, color: const Color(0xFFE2E8F0));
  }

  Widget _buildLinksSection(double side, bool isMobile) {
    final allLinks = <Map<String, dynamic>>[];

    if (_stores.isNotEmpty) {
      allLinks.add({'title': 'Ma boutique', 'subtitle': 'Voir la boutique', 'icon': Icons.storefront_rounded,
        'color': const Color(0xFF5267FF), 'url': '', 'asset': null, 'image_url': null});
    }

    for (final l in _links) {
      final link = Map<String, dynamic>.from(l);
      final platform = _detectPlatform(link['url']?.toString() ?? '');
      allLinks.add({
        'title': link['title']?.toString() ?? 'Lien',
        'subtitle': link['url']?.toString() ?? '',
        'icon': _socialIcon(platform),
        'color': _socialColor(platform),
        'url': link['url']?.toString() ?? '',
        'asset': null,
        'image_url': link['image_url']?.toString(),
      });
    }

    for (final s in _socials) {
      final social = Map<String, dynamic>.from(s);
      final platform = social['platform']?.toString().toLowerCase() ?? '';
      final url = social['url']?.toString() ?? '';
      final username = social['username']?.toString() ?? '';
      allLinks.add({
        'title': _socialName(platform),
        'subtitle': username.isNotEmpty ? '@$username' : url,
        'icon': _socialIcon(platform),
        'color': _socialColor(platform),
        'url': url,
        'asset': _socialAsset(platform),
        'image_url': null,
      });
    }

    if (allLinks.isEmpty) return const SizedBox();

    final displayedLinks = isMobile ? allLinks.take(6).toList() : allLinks;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Liens & réseaux', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          isMobile
              ? Wrap(
                  spacing: 12, runSpacing: 12,
                  children: displayedLinks.map((l) => _linkPill(l)).toList(),
                )
              : Wrap(
                  spacing: 14, runSpacing: 14,
                  children: displayedLinks.map((l) => _linkPill(l)).toList(),
                ),
          if (isMobile && allLinks.length > 6) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Voir tous les liens', style: TextStyle(color: Color(0xFF5267FF), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linkPill(Map<String, dynamic> link) {
    final icon = link['icon'] as IconData;
    final color = link['color'] as Color;
    final title = link['title'] as String;
    final subtitle = link['subtitle'] as String;
    final url = link['url'] as String;
    final asset = link['asset'] as String?;
    final imageUrl = link['image_url'] as String?;

    return GestureDetector(
      onTap: url.isNotEmpty ? () => _openUrl(url) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? (asset != null
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(asset, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 20)),
                        )
                      : Icon(icon, color: color, size: 20))
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                if (subtitle.isNotEmpty)
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresSection(double side, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: side),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mes boutiques', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              Text('Voir toutes (${_stores.length})', style: const TextStyle(
                color: Color(0xFF5267FF), fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isMobile ? 260 : 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: side),
            itemCount: _stores.length,
            itemBuilder: (context, i) => _storeCard(Map<String, dynamic>.from(_stores[i]), isMobile),
          ),
        ),
      ],
    );
  }

  Widget _storeCard(Map<String, dynamic> store, bool isMobile) {
    final isActive = store['is_active'] == 1;
    final coverUrl = store['cover_url']?.toString() ?? '';
    final logoUrl = store['logo_url']?.toString() ?? '';
    final name = store['name']?.toString() ?? '';
    final slug = store['slug']?.toString() ?? '';
    final description = store['description']?.toString() ?? '';
    final products = store['total_products'] ?? 0;
    final followers = store['total_followers'] ?? 0;
    final reviews = store['total_reviews'] ?? 0;
    final rating = (store['rating'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreLandingScreen(slug: slug, initialData: store),
        ),
      ),
      child: Container(
        width: isMobile ? 260 : 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: isMobile ? 100 : 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    color: const Color(0xFFF1F5F9),
                    image: coverUrl.isNotEmpty ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover) : null,
                  ),
                  child: coverUrl.isEmpty
                      ? Center(child: Icon(Icons.storefront, size: 32, color: Colors.grey.shade300))
                      : null,
                ),
                if (logoUrl.isNotEmpty)
                  Positioned(
                    bottom: -14, left: 14,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: ClipOval(child: Image.network(logoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.store, size: 16, color: Colors.grey.shade400))),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, logoUrl.isNotEmpty ? 20 : 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(isActive ? 'Active' : 'En pause', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: isActive ? const Color(0xFF059669) : const Color(0xFFD97706))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('@$slug', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(description, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _storeStat('$products', 'Produits'),
                      const SizedBox(width: 16),
                      _storeStat(_formatCount(followers), 'Abonnés'),
                      const SizedBox(width: 16),
                      _storeStat('${(rating * 100).toInt()}%', 'Avis positif'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildPortfolioSection(double side, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: side),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mon portfolio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const Text('Voir tout le portfolio', style: TextStyle(
                color: Color(0xFF5267FF), fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isMobile ? 170 : 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: side),
            itemCount: _portfolio.length,
            itemBuilder: (context, i) => _portfolioCard(Map<String, dynamic>.from(_portfolio[i]), isMobile),
          ),
        ),
      ],
    );
  }

  Widget _portfolioCard(Map<String, dynamic> project, bool isMobile) {
    String? imageUrl;
    try {
      final images = project['images'] as List?;
      if (images != null && images.isNotEmpty) imageUrl = images.first.toString();
    } catch (_) {}
    final title = project['title']?.toString() ?? '';
    final category = project['category']?.toString() ?? '';
    final keywordsStr = project['keywords']?.toString() ?? '';
    final keywords = keywordsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return GestureDetector(
      onTap: () => _openUrl(project['project_url']?.toString() ?? ''),
      child: Container(
        width: isMobile ? 160 : 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: const Color(0xFFF1F5F9),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image, color: Colors.grey.shade300, size: 32))),
                      )
                    : Center(child: Icon(Icons.work_outline, color: Colors.grey.shade300, size: 32)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(category, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                  if (keywords.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: keywords.take(3).map((kw) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(kw, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6))),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(double side, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shopping_bag_outlined, color: Color(0xFF5267FF), size: 22),
              SizedBox(width: 8),
              Text('Produits en vedette', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 3,
              mainAxisSpacing: 14, crossAxisSpacing: 14,
              childAspectRatio: 0.66,
            ),
            itemCount: _products.length,
            itemBuilder: (context, i) => _productCard(Map<String, dynamic>.from(_products[i])),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    String? image;
    try {
      final images = jsonDecode(product['images']?.toString() ?? '[]');
      if (images is List && images.isNotEmpty) image = images.first.toString();
    } catch (_) {}
    final price = product['discount_price'] ?? product['base_price'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: image == null || image.isEmpty
                  ? const ColoredBox(color: Color(0xFFF1F5F9), child: Center(child: Icon(Icons.inventory_2_outlined, size: 36)))
                  : Image.network(image, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF1F5F9))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('$price ${product['currency'] ?? 'DA'}',
                  style: const TextStyle(color: Color(0xFF5267FF), fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text('Créé avec ♥ Linky', style: TextStyle(
        color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  String _detectPlatform(String url) {
    final u = url.toLowerCase();
    if (u.contains('instagram.com') || u.contains('instagr.am')) return 'instagram';
    if (u.contains('tiktok.com')) return 'tiktok';
    if (u.contains('youtube.com') || u.contains('youtu.be')) return 'youtube';
    if (u.contains('facebook.com') || u.contains('fb.com')) return 'facebook';
    if (u.contains('linkedin.com')) return 'linkedin';
    if (u.contains('wa.me') || u.contains('whatsapp.com')) return 'whatsapp';
    if (u.contains('t.me') || u.contains('telegram.org')) return 'telegram';
    if (u.contains('snapchat.com')) return 'snapchat';
    if (u.contains('x.com') || u.contains('twitter.com')) return 'twitter';
    if (u.contains('pinterest.com')) return 'pinterest';
    return 'website';
  }

  String _socialName(String platform) {
    switch (platform) {
      case 'instagram': return 'Instagram';
      case 'tiktok': return 'TikTok';
      case 'facebook': return 'Facebook';
      case 'whatsapp': return 'WhatsApp';
      case 'youtube': return 'YouTube';
      case 'twitter': return 'Twitter';
      case 'linkedin': return 'LinkedIn';
      case 'snapchat': return 'Snapchat';
      case 'pinterest': return 'Pinterest';
      case 'telegram': return 'Telegram';
      default: return platform[0].toUpperCase() + platform.substring(1);
    }
  }

  String _socialAsset(String platform) {
    switch (platform) {
      case 'instagram': return 'assets/insta.png';
      case 'facebook': return 'assets/fb.png';
      case 'youtube': return 'assets/yt.png';
      case 'linkedin': return 'assets/linkdin.png';
      case 'whatsapp': return 'assets/whatsapp.png';
      case 'tiktok': return 'assets/tik.png';
      case 'pinterest': return 'assets/pf.png';
      case 'website': return 'assets/site.png';
      default: return 'assets/site.png';
    }
  }

  IconData _socialIcon(String platform) {
    switch (platform) {
      case 'instagram': return Icons.camera_alt;
      case 'tiktok': return Icons.music_note;
      case 'facebook': return Icons.facebook;
      case 'whatsapp': return Icons.chat_rounded;
      case 'youtube': return Icons.play_arrow_rounded;
      case 'twitter': return Icons.tag;
      case 'linkedin': return Icons.work;
      case 'snapchat': return Icons.camera;
      default: return Icons.language;
    }
  }

  Color _socialColor(String platform) {
    switch (platform) {
      case 'instagram': return const Color(0xFFE4405F);
      case 'tiktok': return const Color(0xFF010101);
      case 'facebook': return const Color(0xFF1877F2);
      case 'whatsapp': return const Color(0xFF25D366);
      case 'youtube': return const Color(0xFFFF0000);
      case 'twitter': return const Color(0xFF1DA1F2);
      case 'linkedin': return const Color(0xFF0A66C2);
      case 'snapchat': return const Color(0xFFFFFC00);
      default: return const Color(0xFF5267FF);
    }
  }
}
