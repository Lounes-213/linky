import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';
import '../core/api/api_service.dart';

class PlaylistsScreen extends StatefulWidget {
  final String? userId;

  const PlaylistsScreen({super.key, this.userId});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _recentVideos = [];
  String? _error;

  final List<String> _platforms = ['Tous', 'YouTube', 'TikTok', 'Reels', 'Facebook'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _platforms.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ApiService();
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Utilisateur non connecte';
      });
      return;
    }

    final platformFilter = _tabController.index == 0
        ? null
        : _platforms[_tabController.index].toLowerCase();

    final queryParams = <String, String>{};
    if (platformFilter != null) {
      queryParams['platform'] = platformFilter;
    }

    final res = await api.get(
      '/api/playlists/user/$userId',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (res.isSuccess && res.data != null) {
      final List<dynamic> playlistsData =
          res.data!['playlists'] ?? res.data!['data'] ?? [];
      final List<dynamic> recentData = res.data!['recent_videos'] ?? [];
      setState(() {
        _playlists = playlistsData.cast<Map<String, dynamic>>();
        _recentVideos = recentData.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = res.error ?? 'Erreur lors du chargement';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(onSurface),
            _buildPlatformTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: LinkyColors.primary))
                  : _error != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: LinkyColors.primary,
                          child: _buildContent(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color onSurface) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Neumorphism.circle(
            context: context,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: onSurface),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Playlists',
            style: TextStyle(
              color: onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPlatformTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Neumorphism.light(
        borderRadius: 12,
        context: context,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicator: BoxDecoration(
            color: LinkyColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: EdgeInsets.zero,
          padding: const EdgeInsets.all(4),
          tabs: _platforms.map((p) {
            return Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(p),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_playlists.isEmpty && _recentVideos.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (_playlists.isNotEmpty) ...[
          _buildSectionHeader('Mes playlists'),
          const SizedBox(height: 12),
          ...List.generate(
            _playlists.length,
            (index) => _buildPlaylistCard(_playlists[index]),
          ),
        ],
        if (_recentVideos.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader('Videos recentes'),
          const SizedBox(height: 12),
          ...List.generate(
            _recentVideos.length,
            (index) => _buildVideoItem(_recentVideos[index]),
          ),
          const SizedBox(height: 16),
          _buildSeeAllLink(),
        ],
        const SizedBox(height: 16),
        _buildCreateButton(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    final name = playlist['name'] ?? 'Playlist';
    final videoCount = playlist['video_count'] ?? 0;
    final coverImage = playlist['cover_image'];
    final platform = playlist['platform'] ?? '';

    return GestureDetector(
      onTap: () => _openPlaylistDetail(playlist),
      child: Neumorphism.light(
        borderRadius: 16,
        context: context,
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: LinkyColors.primary.withValues(alpha: 0.1),
                  ),
                  child: coverImage != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                          ),
                        )
                      : _buildPlaceholderCover(),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Neumorphism.circle(
                    size: 44,
                    context: context,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.play_arrow_rounded, size: 22, color: LinkyColors.primary),
                    ),
                  ),
                ),
                if (platform.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildPlatformBadge(platform),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$videoCount video${videoCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LinkyColors.primary.withValues(alpha: 0.3),
            LinkyColors.accent.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.playlist_play, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildPlatformBadge(String platform) {
    final lower = platform.toLowerCase();
    Color bgColor;
    IconData icon;

    switch (lower) {
      case 'youtube':
        bgColor = const Color(0xFFFF0000);
        icon = Icons.play_circle_filled;
        break;
      case 'tiktok':
        bgColor = const Color(0xFF000000);
        icon = Icons.music_note;
        break;
      case 'reels':
        bgColor = const Color(0xFFE1306C);
        icon = Icons.camera;
        break;
      case 'facebook':
        bgColor = const Color(0xFF1877F2);
        icon = Icons.facebook;
        break;
      default:
        bgColor = LinkyColors.primary;
        icon = Icons.video_library;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '${platform[0].toUpperCase()}${platform.substring(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    final title = video['title'] ?? 'Video';
    final thumbnail = video['thumbnail'];
    final duration = video['duration'];
    final platform = video['platform'] ?? '';

    return GestureDetector(
      onTap: () {},
      child: Neumorphism.light(
        borderRadius: 12,
        context: context,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: LinkyColors.primary.withValues(alpha: 0.1),
                    ),
                    child: thumbnail != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildSmallPlaceholder(),
                            ),
                          )
                        : _buildSmallPlaceholder(),
                  ),
                  if (duration != null)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duration.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (platform.isNotEmpty) _buildSmallPlatformIcon(platform),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LinkyColors.primary.withValues(alpha: 0.2),
            LinkyColors.accent.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 28, color: LinkyColors.primary),
      ),
    );
  }

  Widget _buildSmallPlatformIcon(String platform) {
    final lower = platform.toLowerCase();
    Color color;
    IconData icon;

    switch (lower) {
      case 'youtube':
        color = const Color(0xFFFF0000);
        icon = Icons.play_circle_filled;
        break;
      case 'tiktok':
        color = const Color(0xFF000000);
        icon = Icons.music_note;
        break;
      case 'reels':
        color = const Color(0xFFE1306C);
        icon = Icons.camera;
        break;
      case 'facebook':
        color = const Color(0xFF1877F2);
        icon = Icons.facebook;
        break;
      default:
        color = LinkyColors.primary;
        icon = Icons.video_library;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '${platform[0].toUpperCase()}${platform.substring(1)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSeeAllLink() {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: const Text(
          'Voir tout',
          style: TextStyle(
            color: LinkyColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _showCreatePlaylistSheet,
      child: Neumorphism.button(
        borderRadius: 14,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Creer une playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Neumorphism.light(
            borderRadius: 30,
            context: context,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Icon(
                Icons.playlist_play,
                size: 60,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune playlist',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creez votre premiere playlist\npour organiser vos videos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _showCreatePlaylistSheet,
            child: Neumorphism.button(
              borderRadius: 12,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'Creer une playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: LinkyColors.discount),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadData,
            child: Neumorphism.button(
              borderRadius: 12,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'Reessayer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlaylistDetail(Map<String, dynamic> playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _showCreatePlaylistSheet() {
    final nameController = TextEditingController();
    String selectedPlatform = 'YouTube';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Creer une playlist',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nom de la playlist',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Neumorphism.light(
                      borderRadius: 12,
                      context: context,
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Ma nouvelle playlist',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Plateforme',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['YouTube', 'TikTok', 'Reels', 'Facebook'].map((p) {
                        final isSelected = selectedPlatform == p;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedPlatform = p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LinkyColors.primary
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? LinkyColors.primary
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: LinkyColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _createPlaylist(nameController.text.trim(), selectedPlatform),
                      child: Neumorphism.button(
                        borderRadius: 12,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Creer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createPlaylist(String name, String platform) async {
    if (name.isEmpty) return;

    Navigator.pop(context);

    final api = ApiService();
    final res = await api.post('/api/playlists', body: {
      'name': name,
      'platform': platform.toLowerCase(),
    });

    if (res.isSuccess) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist creee avec succes'),
            backgroundColor: LinkyColors.neonGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error ?? 'Erreur lors de la creation'),
            backgroundColor: LinkyColors.discount,
          ),
        );
      }
    }
  }
}

class PlaylistDetailScreen extends StatefulWidget {
  final Map<String, dynamic> playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _playlistDetail;
  List<Map<String, dynamic>> _videos = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylistDetail();
  }

  Future<void> _loadPlaylistDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ApiService();
    final id = widget.playlist['id'];

    final res = await api.get('/api/playlists/$id');

    if (res.isSuccess && res.data != null) {
      final playlistData = res.data!['playlist'] ?? res.data;
      final List<dynamic> videosData =
          res.data!['videos'] ?? (playlistData is Map<String, dynamic> ? playlistData['videos'] : null) ?? [];
      setState(() {
        _playlistDetail =
            playlistData is Map<String, dynamic> ? playlistData : widget.playlist;
        _videos = videosData.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() {
        _playlistDetail = widget.playlist;
        _videos = [];
        _isLoading = false;
        _error = res.error ?? 'Erreur lors du chargement';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final name = widget.playlist['name'] ?? 'Playlist';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(name, onSurface),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: LinkyColors.primary))
                  : _error != null
                      ? _buildErrorState()
                      : _buildVideoList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Neumorphism.circle(
            context: context,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: onSurface),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Neumorphism.circle(
            size: 40,
            context: context,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.more_vert, size: 18, color: onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    if (_videos.isEmpty) {
      return _buildEmptyVideosState();
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylistDetail,
      color: LinkyColors.primary,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return _buildVideoListItem(_videos[index], index);
        },
      ),
    );
  }

  Widget _buildVideoListItem(Map<String, dynamic> video, int index) {
    final title = video['title'] ?? 'Video ${index + 1}';
    final thumbnail = video['thumbnail'];
    final duration = video['duration'];
    final platform = video['platform'] ?? widget.playlist['platform'] ?? '';

    return GestureDetector(
      onTap: () {},
      child: Neumorphism.light(
        borderRadius: 12,
        context: context,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: LinkyColors.primary.withValues(alpha: 0.1),
                    ),
                    child: thumbnail != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDetailPlaceholder(),
                            ),
                          )
                        : _buildDetailPlaceholder(),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Neumorphism.circle(
                        size: 36,
                        context: context,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.play_arrow_rounded,
                              size: 18, color: LinkyColors.primary),
                        ),
                      ),
                    ),
                  ),
                  if (duration != null)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duration.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildDetailPlatformIcon(platform),
                        const Spacer(),
                        Icon(
                          Icons.playlist_add,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LinkyColors.primary.withValues(alpha: 0.2),
            LinkyColors.accent.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 32, color: LinkyColors.primary),
      ),
    );
  }

  Widget _buildDetailPlatformIcon(String platform) {
    final lower = platform.toLowerCase();
    Color color;
    IconData icon;

    switch (lower) {
      case 'youtube':
        color = const Color(0xFFFF0000);
        icon = Icons.play_circle_filled;
        break;
      case 'tiktok':
        color = const Color(0xFF000000);
        icon = Icons.music_note;
        break;
      case 'reels':
        color = const Color(0xFFE1306C);
        icon = Icons.camera;
        break;
      case 'facebook':
        color = const Color(0xFF1877F2);
        icon = Icons.facebook;
        break;
      default:
        color = LinkyColors.primary;
        icon = Icons.video_library;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '${platform[0].toUpperCase()}${platform.substring(1)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyVideosState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Neumorphism.light(
            borderRadius: 30,
            context: context,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Icon(
                Icons.video_library_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune video',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des videos a cette playlist\npour les retrouver facilement',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: LinkyColors.discount),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadPlaylistDetail,
            child: Neumorphism.button(
              borderRadius: 12,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'Reessayer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
