import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/shared_ui.dart';
import '../core/theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/api/api_service.dart';
import '../core/constants/app_constants.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'store_management_screen.dart';
import 'admin_panel_screen.dart';
import 'create_store_screen.dart';
import 'public_profile_screen.dart';
import 'playlists_screen.dart';
import 'polls_screen.dart';
import 'donations_screen.dart';
import 'portfolio_screen.dart';
import 'linky_page_manager_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;

  String _apiUsername = '';
  bool _isAdmin = false;
  String _apiName = '';
  String _apiEmail = '';
  String _apiAvatar = '';
  String _apiBio = '';
  String _apiCountry = '';
  String _apiState = '';
  String _apiPhone = '';
  String _apiWebsite = '';
  String _apiCreatedAt = '';
  Map<String, dynamic> _socialLinks = {};
  Map<String, dynamic> _userSettings = {};
  List<String> _languages = [];
  bool _profileLoaded = false;

  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> _featuredProducts = [];

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _publicUsername {
    if (_apiUsername.isNotEmpty) return _apiUsername;
    final source = _user?.email?.split('@').first ?? _user?.displayName ?? 'user';
    final value = source.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return value.isEmpty ? 'user' : value;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final api = ApiService();
    try {
      final responses = await Future.wait([
        api.get('/api/users/me'),
        api.get('/api/stores?mine=true'),
      api.get('/api/profile/portfolio'),
      ]);

      final userRes = responses[0];
      final storesRes = responses[1];
      final portfolioRes = responses[2];

      if (mounted) {
        if (userRes.isSuccess) {
          final d = userRes.data;
          _apiUsername = d?['username']?.toString() ?? '';
          _apiName = d?['name']?.toString() ?? '';
          _apiEmail = d?['email']?.toString() ?? '';
          _apiAvatar = d?['avatar_url']?.toString() ?? '';
          _apiBio = d?['bio']?.toString() ?? '';
          _apiCountry = d?['country']?.toString() ?? '';
          _apiState = d?['state']?.toString() ?? '';
          _apiPhone = d?['phone']?.toString() ?? '';
          _apiWebsite = d?['website']?.toString() ?? '';
          _apiCreatedAt = d?['created_at']?.toString() ?? '';
          _isAdmin = d?['is_admin'] == 1;

          if (d?['social_links'] != null) {
            try {
              _socialLinks = d!['social_links'] is String
                  ? jsonDecode(d['social_links'])
                  : Map<String, dynamic>.from(d['social_links']);
            } catch (_) {}
          }
          if (d?['settings'] != null) {
            try {
              _userSettings = d!['settings'] is String
                  ? jsonDecode(d['settings'])
                  : Map<String, dynamic>.from(d['settings']);
            } catch (_) {}
          }
          if (d?['languages'] != null) {
            try {
              final lang = d!['languages'];
              final map = lang is String ? jsonDecode(lang) : lang;
              _languages = (map as Map).entries.where((e) => e.value == true).map((e) => e.key.toString()).toList();
            } catch (_) {}
          }
        }

        if (storesRes.isSuccess && storesRes.data != null) {
          final list = storesRes.data!['stores'];
          if (list is List) {
            _stores = list.map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s)).toList();
          }
        }

        if (portfolioRes.isSuccess && portfolioRes.data != null) {
          final list = portfolioRes.data!['projects'] ?? portfolioRes.data!['portfolio'];
          if (list is List) {
            _portfolio = list.map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s)).toList();
          }
        }

        for (final store in _stores) {
          final storeId = store['id']?.toString();
          if (storeId == null) continue;
          final featRes = await api.get('/api/products/featured', queryParams: {'store_id': storeId});
          if (featRes.isSuccess && featRes.data != null) {
            final plist = featRes.data!['products'];
            if (plist is List) {
              _featuredProducts.addAll(plist.map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p)));
            }
          }
        }
        if (_featuredProducts.length > 3) _featuredProducts = _featuredProducts.sublist(0, 3);

        setState(() => _profileLoaded = true);
      }
    } catch (e) {
      if (mounted) setState(() => _profileLoaded = true);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getLangName(String code) {
    switch (code) {
      case 'fr': return 'Français';
      case 'en': return 'English';
      case 'ar': return 'العربية';
      default: return code;
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: _profileLoaded
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 8),
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildStatsCard(),
                    const SizedBox(height: 20),
                    _buildFeatureGrid(),
                    const SizedBox(height: 20),
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    _buildTabContent(),
                    const SizedBox(height: 100),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator(color: LinkyColors.primary)),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Spacer(),
          _topBarIcon(Icons.share_outlined, () => _showShareProfileSheet(context)),
          const SizedBox(width: 12),
          _topBarIcon(Icons.grid_view_rounded, () {}),
          const SizedBox(width: 12),
          _topBarIcon(Icons.more_horiz_rounded, () => _showMoreOptions()),
        ],
      ),
    );
  }

  Widget _topBarIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Icon(icon, color: clayText(context), size: 20),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final photoUrl = _apiAvatar.isNotEmpty ? _apiAvatar : _user?.photoURL;
    final name = _apiName.isNotEmpty ? _apiName : (_user?.displayName ?? 'Utilisateur');

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: clayCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: clayBorder(context)),
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: clayCard(context),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Icon(Icons.person, size: 54, color: clayTextMuted(context))
                    : null,
              ),
            ),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: LinkyColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: clayCard(context), width: 3),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: TextStyle(
              color: clayText(context),
              fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            const SizedBox(width: 6),
            Icon(Icons.verified, color: LinkyColors.primary, size: 22),
          ],
        ),
        const SizedBox(height: 4),
        Text('@$_publicUsername', style: TextStyle(
          color: clayTextSecondary(context), fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (_apiCreatedAt.isNotEmpty)
              _infoPill(Icons.calendar_today_outlined, _formatDate(_apiCreatedAt)),
            if (_apiCountry.isNotEmpty)
              _infoPill(Icons.location_on_outlined, '$_apiCountry${_apiState.isNotEmpty ? ', $_apiState' : ''}'),
          ],
        ),
        if (_apiBio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(_apiBio, textAlign: TextAlign.center, style: TextStyle(
              color: clayTextSecondary(context), fontSize: 14, height: 1.5)),
          ),
        ],
      ],
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: clayPrimary(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: clayPrimary(context)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: clayText(context))),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem('0', loc.subscriptions),
            _statDivider(),
            _statItem(_formatCount(_getFollowersCount()), loc.followers),
            _statDivider(),
            _statItem('0', loc.receivedReviews),
            _statDivider(),
            _statItemWithStar('0', loc.rating),
          ],
        ),
      ),
    );
  }

  Widget _statItemWithStar(String count, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count, style: TextStyle(
              color: clayText(context),
              fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, color: LinkyColors.star, size: 20),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11,
          color: clayTextSecondary(context))),
      ],
    );
  }

  String _formatCount(dynamic count) {
    final n = int.tryParse(count?.toString() ?? '0') ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  int _getFollowersCount() {
    int total = 0;
    for (final s in _stores) {
      total += int.tryParse(s['total_followers']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  Widget _statItem(String count, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(count, style: TextStyle(
          color: clayText(context),
          fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11,
          color: clayTextSecondary(context))),
      ],
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 30, color: clayBorder(context));
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': Icons.link_rounded, 'label': 'Page de liens', 'c1': const Color(0xff7B61FF), 'c2': const Color(0xff45C3FF)},
      {'icon': Icons.storefront_rounded, 'label': 'Boutique', 'c1': const Color(0xff8B5CF6), 'c2': const Color(0xffC084FC)},
      {'icon': Icons.playlist_play_rounded, 'label': 'Playlists', 'c1': const Color(0xff06B6D4), 'c2': const Color(0xff22D3EE)},
      {'icon': Icons.folder_open_rounded, 'label': 'Portfolio', 'c1': const Color(0xffF59E0B), 'c2': const Color(0xffFBBF24)},
      {'icon': Icons.how_to_vote_rounded, 'label': 'Vote', 'c1': const Color(0xff10B981), 'c2': const Color(0xff34D399)},
      {'icon': Icons.favorite_rounded, 'label': 'Donation', 'c1': const Color(0xffEC4899), 'c2': const Color(0xffF472B6)},
      {'icon': Icons.auto_awesome_rounded, 'label': 'Stories', 'c1': const Color(0xff6366F1), 'c2': const Color(0xff818CF8)},
      {'icon': Icons.info_outline_rounded, 'label': 'À propos', 'c1': const Color(0xff64748B), 'c2': const Color(0xff94A3B8)},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: features.map((f) {
          final i = features.indexOf(f);
          return GestureDetector(
            onTap: () {
              switch (i) {
                case 1:
                  if (_stores.isNotEmpty) {
                    final store = _stores.first;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StoreManagementScreen(shop: Map<String, dynamic>.from(store)),
                    ));
                  }
                case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioScreen()));
                case 4: Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsScreen()));
                case 5: Navigator.push(context, MaterialPageRoute(builder: (_) => DonationsScreen(recipientId: _user?.uid ?? '', recipientName: _apiName)));
              }
            },
            child: Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: clayCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: clayBorder(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [f['c1'] as Color, f['c2'] as Color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f['icon'] as IconData, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(f['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: clayText(context)),
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      AppLocalizations.of(context).myStores,
      AppLocalizations.of(context).portfolio,
      AppLocalizations.of(context).activity,
      AppLocalizations.of(context).aboutTab,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isSelected = _activeTabIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _activeTabIndex = i);
                  _tabController.animateTo(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: isSelected ? clayPrimary(context).withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? clayPrimary(context) : clayTextSecondary(context),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTabIndex) {
      case 0: return _buildBoutiquesTab();
      case 1: return _buildPortfolioTab();
      case 2: return _buildActivityTab();
      case 3: return _buildAboutTab();
      default: return _buildBoutiquesTab();
    }
  }

  Widget _buildBoutiquesTab() {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(loc.myStores, loc.seeAll, () {}),
        const SizedBox(height: 12),
        if (_stores.isEmpty)
          _emptyActionState(Icons.storefront_outlined, loc.noStoresYet, 'Créez votre première boutique', loc.createStore, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStoreScreen()));
          })
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _stores.length,
              itemBuilder: (context, i) => _storeCard(_stores[i]),
            ),
          ),
        const SizedBox(height: 24),
        if (_featuredProducts.isNotEmpty) ...[
          _sectionHeader('Produits en vedette', '', null),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _featuredProducts.length,
              itemBuilder: (context, i) => _featuredProductCard(_featuredProducts[i]),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _sectionHeader(loc.portfolio, loc.seeAll, () {}),
        const SizedBox(height: 12),
        if (_portfolio.isEmpty)
          _emptyActionState(Icons.work_outline, loc.noProjects, 'Ajoutez vos réalisations', loc.addProject, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkyPageManagerScreen()));
          })
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _portfolio.length,
              itemBuilder: (context, i) => _portfolioCard(_portfolio[i]),
            ),
          ),
        const SizedBox(height: 24),
        _sectionHeader(loc.linksAndNetworks, '', null),
        const SizedBox(height: 12),
        _buildSocialIconsRow(),
      ],
    );
  }

  Widget _sectionHeader(String title, String? action, VoidCallback? onAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3,
            color: clayText(context))),
          if (action != null && onAction != null)
            GestureDetector(onTap: onAction, child: Text(action, style: TextStyle(
              color: clayPrimary(context), fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _featuredProductCard(Map<String, dynamic> product) {
    final bg = clayCard(context);
    final txt = clayText(context);
    final txtMuted = clayTextSecondary(context);
    final name = product['name']?.toString() ?? '';
    final price = product['base_price'] ?? 0;
    final discountPrice = product['discount_price'];
    List<dynamic> images = [];
    try { images = product['images'] is List ? product['images'] : []; } catch (_) {}
    final imgUrl = images.isNotEmpty ? images[0].toString() : '';

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: clayCard(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: clayBorder(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imgUrl.isNotEmpty
                  ? Image.network(imgUrl, fit: BoxFit.cover, width: double.infinity)
                  : const Center(child: Icon(Icons.inventory_2, color: Colors.grey, size: 28)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
            child: Row(
              children: [
                Text('$price DA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: clayPrimary(context))),
                if (discountPrice != null && discountPrice > 0 && discountPrice < price)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text('${discountPrice.toInt()} DA', style: TextStyle(fontSize: 11, color: txtMuted, decoration: TextDecoration.lineThrough)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeCard(Map<String, dynamic> store) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = store['is_active'] == 1;
    final coverUrl = store['cover_url']?.toString() ?? '';
    final logoUrl = store['logo_url']?.toString() ?? '';
    final name = store['name']?.toString() ?? '';
    final slug = store['slug']?.toString() ?? '';
    final products = store['total_products'] ?? 0;
    final followers = store['total_followers'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => StoreManagementScreen(shop: Map<String, dynamic>.from(store)),
      )),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    color: clayCard(context),
                    image: coverUrl.isNotEmpty ? DecorationImage(
                      image: NetworkImage(coverUrl), fit: BoxFit.cover) : null,
                  ),
                  child: coverUrl.isEmpty
                      ? Center(child: Icon(Icons.storefront, size: 36,
                          color: clayTextMuted(context).withValues(alpha: 0.4)))
                      : null,
                ),
                if (logoUrl.isNotEmpty)
                  Positioned(
                    bottom: -16, left: 14,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: clayCard(context),
                        border: Border.all(color: clayCard(context), width: 2.5),
                      ),
                      child: ClipOval(
                        child: Image.network(logoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.store, size: 18, color: LinkyColors.primary)),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, logoUrl.isNotEmpty ? 22 : 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.3,
                    color: clayText(context))),
                  const SizedBox(height: 2),
                  Text('@$slug', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 12, color: clayTextSecondary(context))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isActive ? 'Boutique active' : 'En pause', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.orange)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('$products Produits', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: clayTextSecondary(context))),
                      const SizedBox(width: 12),
                      Text('$followers Abonnés', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: clayTextSecondary(context))),
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

  Widget _portfolioCard(Map<String, dynamic> project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? imageUrl;
    try {
      final images = project['images'] as List?;
      if (images != null && images.isNotEmpty) imageUrl = images.first.toString();
    } catch (_) {}
    imageUrl ??= project['image_url']?.toString();
    final keywordsStr = project['keywords']?.toString() ?? '';
    final keywords = keywordsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: clayCard(context),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image_outlined, size: 36, color: clayTextMuted(context))),
                      ),
                    )
                  : Center(child: Icon(Icons.image_outlined, size: 36, color: clayTextMuted(context))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project['title']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.3,
                    color: clayText(context))),
                if (project['category']?.toString().isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(project['category']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: clayTextSecondary(context))),
                ],
                if (keywords.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: keywords.take(3).map((kw) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: LinkyColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(kw, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: LinkyColors.primary)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIconsRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final platforms = [
      {'key': 'instagram', 'name': 'Instagram', 'icon': Icons.camera_alt, 'color': const Color(0xFFE4405F), 'gradient': const [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)]},
      {'key': 'tiktok', 'name': 'TikTok', 'icon': Icons.music_note, 'color': const Color(0xFF010101), 'gradient': const [Color(0xFF25F4EE), Color(0xFFFE2C55)]},
      {'key': 'facebook', 'name': 'Facebook', 'icon': Icons.facebook, 'color': const Color(0xFF1877F2), 'gradient': const [Color(0xFF1877F2), Color(0xFF42A5F5)]},
      {'key': 'whatsapp', 'name': 'WhatsApp', 'icon': Icons.chat_rounded, 'color': const Color(0xFF25D366), 'gradient': const [Color(0xFF25D366), Color(0xFF128C7E)]},
      {'key': 'youtube', 'name': 'YouTube', 'icon': Icons.play_arrow_rounded, 'color': const Color(0xFFFF0000), 'gradient': const [Color(0xFFFF0000), Color(0xFFCC0000)]},
    ];

    final activePlatforms = platforms
        .where((p) => _socialLinks.containsKey(p['key']) && _socialLinks[p['key']].toString().isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...activePlatforms.map((p) => GestureDetector(
              onTap: () => _launchUrl(_socialLinks[p['key']].toString()),
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: (p['gradient'] as List<Color>),
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(p['icon'] as IconData, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(p['name'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: clayTextSecondary(context))),
                ],
              ),
            )),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkyPageManagerScreen())),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: clayCard(context),
                      border: Border.all(color: clayBorder(context)),
                    ),
                    child: Icon(Icons.more_horiz_rounded, color: clayTextMuted(context), size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text('Plus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: clayTextMuted(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTab() {
    final loc = AppLocalizations.of(context);
    if (_portfolio.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: _portfolio.map((p) => _portfolioCard(p)).toList(),
        ),
      );
    }
    return _emptyActionState(Icons.work_outline, loc.portfolio, 'Ajoutez vos projets et réalisations', loc.addProject, () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkyPageManagerScreen()));
    });
  }

  Widget _buildActivityTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Column(
          children: [
            Icon(Icons.timeline_outlined, size: 50,
              color: clayTextMuted(context).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(loc.recentActivity, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3,
              color: clayText(context))),
            const SizedBox(height: 8),
            Text(loc.interactionsHere, style: TextStyle(fontSize: 13,
              color: clayTextSecondary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aboutSection(loc.aboutMe, _apiBio.isNotEmpty ? _apiBio : loc.noBio),
          const SizedBox(height: 20),
          _aboutSection(loc.information, null, children: [
            _infoRow(Icons.calendar_today_outlined, loc.memberSince, _formatDate(_apiCreatedAt)),
            _infoRow(Icons.public_outlined, loc.country, _apiCountry.isNotEmpty ? _apiCountry : 'Non renseigné'),
            _infoRow(Icons.language, loc.languages, _languages.map((l) => _getLangName(l)).join(', ')),
          ]),
          const SizedBox(height: 20),
          _aboutSection(loc.coordAndNetworks, null, children: [
            if (_socialLinks['whatsapp']?.toString().isNotEmpty == true)
              _contactRow(Icons.chat, 'WhatsApp', _socialLinks['whatsapp'].toString(), Color(0xFF25D366)),
            if (_apiEmail.isNotEmpty)
              _contactRow(Icons.email_outlined, 'E-mail', _apiEmail, LinkyColors.primary),
            if (_apiWebsite.isNotEmpty)
              _contactRow(Icons.language, 'Site web', _apiWebsite, LinkyColors.primary),
            if (_socialLinks['instagram']?.toString().isNotEmpty == true)
              _contactRow(Icons.camera_alt, 'Instagram', _socialLinks['instagram'].toString(), Color(0xFFE4405F)),
            if (_socialLinks['tiktok']?.toString().isNotEmpty == true)
              _contactRow(Icons.music_note, 'TikTok', _socialLinks['tiktok'].toString(), Colors.black),
            if (_socialLinks['facebook']?.toString().isNotEmpty == true)
              _contactRow(Icons.facebook, 'Facebook', _socialLinks['facebook'].toString(), Color(0xFF1877F2)),
            if (_socialLinks['linkedin']?.toString().isNotEmpty == true)
              _contactRow(Icons.work, 'LinkedIn', _socialLinks['linkedin'].toString(), Color(0xFF0A66C2)),
            if (_socialLinks['youtube']?.toString().isNotEmpty == true)
              _contactRow(Icons.play_circle_filled, 'YouTube', _socialLinks['youtube'].toString(), Color(0xFFFF0000)),
          ]),
          const SizedBox(height: 24),
          _shareProfileCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _aboutSection(String title, String? subtitle, {List<Widget>? children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3,
            color: clayText(context))),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(subtitle, style: TextStyle(fontSize: 14, height: 1.5,
              color: clayTextSecondary(context))),
          ],
          if (children != null) ...[
            const SizedBox(height: 14),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: clayPrimary(context)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14,
            color: clayTextSecondary(context)))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
            color: clayText(context))),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, Color iconColor) {
    return GestureDetector(
      onTap: () {
        if (label == 'WhatsApp' || label == 'E-mail') {
          final url = label == 'WhatsApp' ? 'https://wa.me/${value.replaceAll(RegExp(r'[^0-9+]'), '')}' : 'mailto:$value';
          _launchUrl(url);
        } else {
          _launchUrl(value);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
              color: clayText(context)))),
            Flexible(
              child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: clayTextSecondary(context))),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18,
              color: clayTextMuted(context)),
          ],
        ),
      ),
    );
  }

  Widget _shareProfileCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.shareMyProfile, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                  letterSpacing: -0.3, color: Colors.white)),
                const SizedBox(height: 8),
                Text(loc.shareProfileDesc,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _showShareProfileSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: clayBorder(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.share_outlined, color: Color(0xFF7C3AED), size: 18),
                        const SizedBox(width: 8),
                        Text(loc.shareProfile, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.qr_code_2_rounded, color: Colors.white.withValues(alpha: 0.9), size: 36),
          ),
        ],
      ),
    );
  }

  Widget _emptyActionState(IconData icon, String title, String subtitle, String actionLabel, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: clayTextMuted(context).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3,
              color: clayText(context))),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 13,
              color: clayTextSecondary(context))),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: clayPrimary(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(actionLabel, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: clayTextMuted(context).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3,
              color: clayText(context))),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 13,
              color: clayTextSecondary(context))),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: clayBorder(context),
              borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _menuOption(Icons.edit_outlined, 'Modifier le profil', onTap: () async {
              Navigator.pop(ctx);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              _loadProfile();
            }),
            _menuOption(Icons.auto_awesome, AppLocalizations.of(context).myLinkyPage, onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkyPageManagerScreen()));
            }),
            _menuOption(Icons.language, 'Langue', onTap: () {
              Navigator.pop(ctx);
              _showLanguageSheet();
            }),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return _menuOption(Icons.dark_mode_outlined, 'Mode sombre', trailing: Switch(
                  value: themeProvider.isDarkMode, activeThumbColor: clayPrimary(context),
                  onChanged: (_) => themeProvider.toggleTheme(),
                ));
              },
            ),
            if (_isAdmin)
              _menuOption(Icons.admin_panel_settings, 'Admin Panel', onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
              }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _menuOption(IconData icon, String title, {VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: clayPrimary(context), size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15,
              color: clayText(context)))),
            if (trailing != null) trailing
            else Icon(Icons.chevron_right, size: 20,
              color: clayTextMuted(context)),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final locProvider = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentLocale = locProvider.locale;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context).language, style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                const SizedBox(height: 20),
                _languageOption('Français', 'FR', const Locale('fr'), currentLocale, () {
                  locProvider.setLocale(const Locale('fr')); setModalState(() {});
                }),
                const SizedBox(height: 8),
                _languageOption('English', 'EN', const Locale('en'), currentLocale, () {
                  locProvider.setLocale(const Locale('en')); setModalState(() {});
                }),
                const SizedBox(height: 8),
                _languageOption('العربية', 'AR', const Locale('ar'), currentLocale, () {
                  locProvider.setLocale(const Locale('ar')); setModalState(() {});
                }),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _languageOption(String name, String code, Locale locale, Locale current, VoidCallback onTap) {
    final isSelected = current.languageCode == locale.languageCode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? clayPrimary(context).withValues(alpha: 0.05) : clayCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? clayPrimary(context).withValues(alpha: 0.3) : clayBorder(context)),
        ),
        child: Row(
          children: [
            Text(name, style: TextStyle(
              color: isSelected ? clayPrimary(context) : clayText(context),
              fontWeight: FontWeight.w500)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: clayPrimary(context), size: 22),
          ],
        ),
      ),
    );
  }

  void _showShareProfileSheet(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).share, style: TextStyle(
              color: clayText(context), fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: clayCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: clayBorder(context)),
              ),
              child: GestureDetector(
                onTap: () {
                  final link = 'https://linky-to.pages.dev/@$_publicUsername';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lien copié !'), duration: Duration(seconds: 2)),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.link, color: clayPrimary(context)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('https://linky-to.pages.dev/@$_publicUsername',
                      style: TextStyle(color: clayText(context), fontWeight: FontWeight.w500))),
                    Icon(Icons.copy, size: 18, color: clayPrimary(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: clayPrimary(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('https://linky-to.pages.dev/@$_publicUsername');
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.visibility_outlined),
                label: Text(loc.previewMyPublicPage),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
