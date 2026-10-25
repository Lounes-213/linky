import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/localization/app_localizations.dart';
import '../core/api/api_service.dart';
import 'story_view_screen.dart';
import 'add_story_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _stories = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _error;
  String? _userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserAvatar();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.get('/api/stories'),
        api.get('/api/categories'),
      ]);

      if (mounted) {
        setState(() {
          _stories = (results[0].data?['stories'] ?? results[0].data?['data'] ?? []) as List;
          _categories = (results[1].data?['categories'] ?? []) as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadUserAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final api = ApiService();
        final res = await api.get('/api/profile');
        if (res.isSuccess && res.data != null) {
          _userAvatarUrl = res.data!['avatar_url']?.toString();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loc = AppLocalizations.of(context);
    final onSurface = clayText(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: clayScaffoldBg(context),
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: clayPrimary(context))),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: clayScaffoldBg(context),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, style: TextStyle(color: clayText(context), fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadData, child: Text(loc.retry)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 24),
              if (_isSearching) ...[
                Text(loc.allCategories, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                const SizedBox(height: 16),
                _buildCategories(),
                const SizedBox(height: 32),
                Text(loc.suggestedForYou, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                const SizedBox(height: 16),
                _buildSuggestedList(loc),
              ] else ...[
                _buildSectionHeader(loc.stories, loc.seeAll),
                const SizedBox(height: 16),
                _buildStoriesList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: clayCard(context),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: clayBorder(context)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Image.asset('assets/logo.png', width: 42, height: 42, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Linky',
          style: TextStyle(color: clayText(context), fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          },
          child: _buildIconButton(Icons.notifications_outlined),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _showMoreMenu(),
          child: _buildIconButton(Icons.more_horiz),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Icon(icon, color: clayText(context), size: 22),
    );
  }

  Widget _buildSearchBar() {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.search, color: clayTextMuted(context), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (val) {
                  if (val.isNotEmpty && !_isSearching) {
                    setState(() => _isSearching = true);
                  } else if (val.isEmpty && _isSearching) {
                    setState(() => _isSearching = false);
                  }
                },
                onTap: () => setState(() => _isSearching = true),
                style: TextStyle(color: clayText(context)),
                decoration: InputDecoration(
                  hintText: '${loc.search} links, people...',
                  hintStyle: TextStyle(color: clayTextMuted(context)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_isSearching)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _searchFocus.unfocus();
                  setState(() => _isSearching = false);
                },
                child: Icon(Icons.close, color: clayTextMuted(context), size: 20),
              )
            else
              Icon(Icons.tune, color: clayPrimary(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      children: [
        Text(title, style: TextStyle(color: clayText(context), fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const Spacer(),
        Text(action, style: TextStyle(color: clayPrimary(context), fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildCategories() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _categories.map((cat) => _buildCategoryChip(cat['name'] ?? cat['slug'] ?? 'Category')).toList(),
    );
  }

  Widget _buildCategoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Text(label, style: TextStyle(color: clayText(context), fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSuggestedList(AppLocalizations loc) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: clayCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: clayBorder(context)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: clayPrimary(context).withValues(alpha: 0.1),
                  child: Text('U${index + 1}', style: TextStyle(color: clayPrimary(context), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User ${index + 1}', style: TextStyle(color: clayText(context), fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('@user${index + 1}', style: TextStyle(color: clayTextMuted(context), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: clayPrimary(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loc.follow,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoriesList() {
    final user = FirebaseAuth.instance.currentUser;
    final myAvatar = (_userAvatarUrl != null && _userAvatarUrl!.isNotEmpty)
        ? _userAvatarUrl
        : user?.photoURL;
    final List<dynamic> displayStories = [
      {'name': 'Your Story', 'images': [myAvatar ?? 'https://i.pravatar.cc/150?u=1'], 'isMine': true},
      ..._stories.take(5),
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayStories.length,
        itemBuilder: (context, index) {
          final story = displayStories[index];
          final String displayImg = (story['images'] as List?)?.first ?? (story['media_url'] as String?) ?? 'https://i.pravatar.cc/150?u=${index + 10}';
          final bool isMine = story['isMine'] == true;

          return GestureDetector(
            onTap: () {
              if (isMine) {
                _showStoryOptions();
              } else {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, _) => StoryViewScreen(
                      stories: displayStories.where((s) => s['isMine'] != true).cast<Map<String, dynamic>>().toList(),
                      initialIndex: isMine ? index - 1 : index,
                    ),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: clayCard(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: clayBorder(context),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMine
                                  ? (_stories.any((s) => s['user_id'] == user?.uid)
                                      ? Colors.lightBlue.shade50
                                      : Colors.grey.shade200)
                                  : (story['viewed'] == true
                                      ? Colors.grey.shade200
                                      : Colors.lightBlue.shade50),
                              width: 2.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            backgroundImage: displayImg.isNotEmpty ? NetworkImage(displayImg) : null,
                            child: (isMine && (myAvatar == null || myAvatar.isEmpty))
                                ? Text(
                                    (user?.displayName ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(fontSize: 28, color: clayTextMuted(context), fontWeight: FontWeight.bold),
                                  )
                                : (!displayImg.isNotEmpty
                                    ? Text(
                                        'U',
                                        style: TextStyle(fontSize: 28, color: clayTextMuted(context), fontWeight: FontWeight.bold),
                                      )
                                    : null),
                          ),
                        ),
                        if (isMine)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: clayPrimary(context),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 14, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story['name']?.toString() ?? 'User ${index + 1}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: clayTextSecondary(context)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMoreMenu() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: clayCard(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Menu', style: TextStyle(color: clayText(ctx), fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: clayCard(ctx),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: clayBorder(ctx)),
                      ),
                      child: Icon(Icons.close, color: clayTextMuted(ctx), size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _menuQuickAction(ctx, Icons.qr_code_scanner_rounded, loc.search, () { Navigator.pop(ctx); }, loc),
                  const SizedBox(width: 12),
                  _menuQuickAction(ctx, Icons.bookmark_outline, loc.wishlist, () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen()));
                  }, loc),
                  const SizedBox(width: 12),
                  _menuQuickAction(ctx, Icons.share_outlined, loc.share, () { Navigator.pop(ctx); }, loc),
                  const SizedBox(width: 12),
                  _menuQuickAction(ctx, Icons.people_outline, loc.share, () { Navigator.pop(ctx); }, loc),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor, height: 1),
              const SizedBox(height: 8),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _menuListItem(
                    ctx,
                    icon: themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    title: loc.darkMode,
                    subtitle: themeProvider.isDarkMode ? 'Passer au thème lumineux' : 'Passer au thème sombre',
                    onTap: () {
                      themeProvider.toggleTheme();
                      Navigator.pop(ctx);
                    },
                    loc: loc,
                  );
                },
              ),
              _menuListItem(
                ctx,
                icon: Icons.chat_bubble_outline,
                title: loc.notifications,
                subtitle: '2 conversations non lues',
                badgeCount: 2,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChatScreen(contact: {
                      'name': 'Alex Rivera',
                      'img': 'https://i.pravatar.cc/150?u=20',
                    }),
                  ));
                },
                loc: loc,
              ),
              _menuListItem(
                ctx,
                icon: Icons.settings_outlined,
                title: loc.settings,
                subtitle: '${loc.account}, ${loc.security}, ${loc.appearance}',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                loc: loc,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuQuickAction(BuildContext ctx, IconData icon, String label, VoidCallback onTap, AppLocalizations loc) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: clayCard(ctx),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: clayBorder(ctx)),
          ),
          child: Column(
            children: [
              Icon(icon, color: clayPrimary(ctx), size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: clayText(ctx), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuListItem(BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badgeCount = 0,
    AppLocalizations? loc,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: clayCard(ctx),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: clayBorder(ctx)),
              ),
              child: Icon(icon, color: clayTextSecondary(ctx), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: clayText(ctx), fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: clayTextMuted(ctx), fontSize: 12)),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: LinkyColors.discount,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            else
              Icon(Icons.chevron_right, color: clayTextMuted(ctx), size: 20),
          ],
        ),
      ),
    );
  }

  void _showStoryOptions() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.add_a_photo, color: clayPrimary(context)),
                title: const Text('Ajouter une story'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddStoryScreen()));
                },
              ),
              if (_stories.any((s) => s['user_id'] == FirebaseAuth.instance.currentUser?.uid))
                ListTile(
                  leading: Icon(Icons.visibility, color: clayPrimary(context)),
                  title: const Text('Voir ma story'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final myStories = _stories.where((s) => s['user_id'] == FirebaseAuth.instance.currentUser?.uid).cast<Map<String, dynamic>>().toList();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, _) => StoryViewScreen(
                          stories: myStories,
                          initialIndex: 0,
                        ),
                        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
