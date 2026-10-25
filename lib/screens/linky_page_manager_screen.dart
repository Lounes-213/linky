import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_service.dart';
import '../core/theme.dart';
import '../core/widgets/neumorphic_ui.dart';

class LinkyPageManagerScreen extends StatefulWidget {
  const LinkyPageManagerScreen({super.key});

  @override
  State<LinkyPageManagerScreen> createState() => _LinkyPageManagerScreenState();
}

class _LinkyPageManagerScreenState extends State<LinkyPageManagerScreen> {
  final _api = ApiService();
  final _imagePicker = ImagePicker();
  bool _loading = true;

  // Real-time State
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _links = [];
  List<Map<String, dynamic>> _socials = [];
  List<Map<String, dynamic>> _portfolio = [];
  Map<String, dynamic> _themeSettings = {};

  static const _platforms = <Map<String, dynamic>>[
    {'id': 'instagram', 'name': 'Instagram', 'asset': 'assets/insta.png', 'color': Color(0xFFE4405F)},
    {'id': 'facebook', 'name': 'Facebook', 'asset': 'assets/fb.png', 'color': Color(0xFF1877F2)},
    {'id': 'youtube', 'name': 'YouTube', 'asset': 'assets/yt.png', 'color': Color(0xFFFF0000)},
    {'id': 'linkedin', 'name': 'LinkedIn', 'asset': 'assets/linkdin.png', 'color': Color(0xFF0A66C2)},
    {'id': 'whatsapp', 'name': 'WhatsApp', 'asset': 'assets/whatsapp.png', 'color': Color(0xFF25D366)},
    {'id': 'tiktok', 'name': 'TikTok', 'asset': 'assets/tik.png', 'color': Color(0xFF010101)},
    {'id': 'pinterest', 'name': 'Pinterest', 'asset': 'assets/pf.png', 'color': Color(0xFFE60023)},
    {'id': 'website', 'name': 'Site Web', 'asset': 'assets/site.png', 'color': Color(0xFF5267FF)},
  ];

  static const _badgeOptions = ['🔥 HOT', '✨ NOUVEAU', '🎁 PROMO', '⚡ LIVE', '⭐ TOP'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final responses = await Future.wait([
        _api.get('/api/profile'),
        _api.get('/api/profile/links'),
        _api.get('/api/profile/portfolio'),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(responses[0].data ?? {});
        final rawTheme = _profile['theme_settings'];
        if (rawTheme is String && rawTheme.isNotEmpty) {
          try { _themeSettings = json.decode(rawTheme); } catch (_) {}
        } else if (rawTheme is Map) {
          _themeSettings = Map<String, dynamic>.from(rawTheme);
        }
        
        _socials = List<Map<String, dynamic>>.from(
          responses[0].data?['social_links'] ?? const [],
        );
        _links = List<Map<String, dynamic>>.from(
          responses[1].data?['links'] ?? const [],
        );
        _portfolio = List<Map<String, dynamic>>.from(
          responses[2].data?['projects'] ?? const [],
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      _showToast('Erreur de chargement: $e', isError: true);
    }
  }

  String get _username => _profile['username']?.toString() ?? 'createur';
  String get _name => (_profile['name']?.toString().trim().isNotEmpty ?? false)
      ? _profile['name'].toString()
      : _username;
  String get _bio => _profile['bio']?.toString() ?? 'Bienvenue sur ma page Linky !';
  String get _avatarUrl => _profile['avatar_url']?.toString() ?? '';
  int get _totalClicks => _links.fold<int>(0, (sum, l) => sum + (int.tryParse(l['clicks_count']?.toString() ?? '0') ?? 0));

  Map<String, dynamic> _platformInfo(String platformId) {
    return _platforms.firstWhere(
      (p) => p['id'] == platformId,
      orElse: () => _platforms.last,
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
    if (u.contains('pinterest.com')) return 'pinterest';
    return 'website';
  }

  void _showToast(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── ADD / EDIT LINK MODAL ──────────────────────────────

  Future<void> _openAddLinkModal({Map<String, dynamic>? existingLink, int? index}) async {
    final titleController = TextEditingController(text: existingLink?['title']?.toString() ?? '');
    final urlController = TextEditingController(text: existingLink?['url']?.toString() ?? '');
    String? imageUrl = existingLink?['image_url']?.toString();
    String selectedBadge = existingLink?['badge']?.toString() ?? '';
    bool isFeatured = existingLink?['is_featured'] == true || existingLink?['is_featured'] == 1;
    bool isUploadingImage = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final detectedPlatform = _detectPlatform(urlController.text);
          final platformInfo = _platformInfo(detectedPlatform);

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44, height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Icon(existingLink == null ? Icons.add_link_rounded : Icons.edit_note_rounded,
                          color: const Color(0xFF5267FF), size: 28),
                      const SizedBox(width: 10),
                      Text(
                        existingLink == null ? 'Ajouter un lien Pro' : 'Modifier le lien',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Image & Icon selector
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        setModalState(() => isUploadingImage = true);
                        final picked = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 500,
                          imageQuality: 85,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          final res = await _api.upload(
                            '/api/upload', bytes,
                            'link_${DateTime.now().millisecondsSinceEpoch}.jpg',
                            folder: 'links',
                          );
                          if (res.isSuccess && res.data?['url'] != null) {
                            imageUrl = res.data!['url'].toString();
                          } else {
                            _showToast('Échec de l\'envoi de l\'image', isError: true);
                          }
                        }
                        setModalState(() => isUploadingImage = false);
                      },
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 84, height: 84,
                            decoration: BoxDecoration(
                              color: (platformInfo['color'] as Color).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isFeatured ? const Color(0xFF5267FF) : Colors.grey.shade300,
                                width: isFeatured ? 2.5 : 1,
                              ),
                              image: imageUrl != null && imageUrl!.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: isUploadingImage
                                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                : (imageUrl == null || imageUrl!.isEmpty
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            platformInfo['asset'] as String,
                                            width: 32, height: 32,
                                            errorBuilder: (_, __, ___) => Icon(Icons.link, color: platformInfo['color'] as Color, size: 30),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Image', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                        ],
                                      )
                                    : null),
                          ),
                          if (imageUrl != null && imageUrl!.isNotEmpty)
                            Positioned(
                              top: 2, right: 2,
                              child: GestureDetector(
                                onTap: () => setModalState(() => imageUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title Input
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Titre du lien',
                      hintText: 'Ex: Ma boutique en ligne / Instagram',
                      prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF5267FF)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // URL Input
                  TextField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'Adresse URL',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF5267FF)),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (platformInfo['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          platformInfo['name'] as String,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: platformInfo['color'] as Color),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 18),

                  // Badge Selector Chips
                  const Text('Badge d\'attention (Optionnel)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Aucun'),
                        selected: selectedBadge.isEmpty,
                        onSelected: (_) => setModalState(() => selectedBadge = ''),
                      ),
                      ..._badgeOptions.map((b) {
                        final isSelected = selectedBadge == b;
                        return ChoiceChip(
                          label: Text(b, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF5267FF).withValues(alpha: 0.2),
                          onSelected: (_) => setModalState(() => selectedBadge = b),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Featured Toggle
                  SwitchListTile(
                    value: isFeatured,
                    onChanged: (v) => setModalState(() => isFeatured = v),
                    title: const Text('Mettre en vedette (Featured)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Affiche une carte illuminée qui attire le regard', style: TextStyle(fontSize: 12)),
                    activeColor: const Color(0xFF5267FF),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5267FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final url = urlController.text.trim();
                        if (title.isEmpty || url.isEmpty) {
                          _showToast('Veuillez remplir le titre et l\'URL', isError: true);
                          return;
                        }
                        Navigator.pop(context);

                        if (existingLink == null) {
                          // Real-time optimistic update
                          final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                          final newLinkMap = {
                            'id': tempId,
                            'title': title,
                            'url': url,
                            'image_url': imageUrl ?? '',
                            'badge': selectedBadge,
                            'is_featured': isFeatured,
                            'clicks_count': 0,
                            'sort_order': _links.length,
                          };
                          setState(() {
                            _links.add(newLinkMap);
                          });

                          final res = await _api.post('/api/profile/links', body: {
                            'title': title,
                            'url': url,
                            'image_url': imageUrl ?? '',
                            'badge': selectedBadge,
                            'is_featured': isFeatured,
                          });
                          if (!res.isSuccess) {
                            _showToast('Échec de la sauvegarde serveur', isError: true);
                          }
                          _load();
                        } else {
                          // Edit update
                          final id = existingLink['id'];
                          setState(() {
                            _links[index!] = {
                              ..._links[index!],
                              'title': title,
                              'url': url,
                              'image_url': imageUrl ?? '',
                              'badge': selectedBadge,
                              'is_featured': isFeatured,
                            };
                          });
                          await _api.put('/api/profile/links/$id', body: {
                            'title': title,
                            'url': url,
                            'image_url': imageUrl ?? '',
                            'badge': selectedBadge,
                            'is_featured': isFeatured,
                          });
                          _load();
                        }
                      },
                      child: Text(
                        existingLink == null ? 'Ajouter au profil' : 'Enregistrer les modifications',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── ADD / EDIT SOCIAL LINK MODAL ──────────────────────────────

  Future<void> _openAddSocialModal({Map<String, dynamic>? existingSocial, int? index}) async {
    String selectedPlatform = existingSocial?['platform']?.toString() ?? 'instagram';
    final handleController = TextEditingController(text: existingSocial?['username']?.toString() ?? '');
    final isEditing = existingSocial != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final platformInfo = _platformInfo(selectedPlatform);
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44, height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Icon(isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                          color: const Color(0xFF5267FF), size: 26),
                      const SizedBox(width: 10),
                      Text(isEditing ? 'Modifier le Réseau Social' : 'Ajouter un Réseau Social',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Platform Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9,
                    ),
                    itemCount: _platforms.length,
                    itemBuilder: (context, idx) {
                      final p = _platforms[idx];
                      final isSelected = p['id'] == selectedPlatform;
                      return GestureDetector(
                        onTap: () => setModalState(() {
                          selectedPlatform = p['id'] as String;
                          handleController.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (p['color'] as Color).withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? (p['color'] as Color) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                p['asset'] as String,
                                width: 32, height: 32,
                                errorBuilder: (_, __, ___) => Icon(Icons.language, color: p['color'] as Color, size: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p['name'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? p['color'] as Color : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: handleController,
                    decoration: InputDecoration(
                      labelText: 'Nom d\'utilisateur ou numéro',
                      hintText: selectedPlatform == 'whatsapp' ? '+213...' : 'ton_pseudo',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(platformInfo['asset'] as String, width: 20, height: 20,
                            errorBuilder: (_, __, ___) => const Icon(Icons.language, size: 20)),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: platformInfo['color'] as Color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final input = handleController.text.trim();
                        if (input.isEmpty) return;
                        Navigator.pop(context);

                        if (!isEditing) {
                          // Add new
                          final newSocialMap = {
                            'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                            'platform': selectedPlatform,
                            'username': input,
                            'url': '',
                          };
                          setState(() { _socials.add(newSocialMap); });
                          final res = await _api.post('/api/profile/social-links', body: {
                            'platform': selectedPlatform,
                            'username': input,
                            'url': '',
                          });
                          if (!res.isSuccess) {
                            _showToast('Erreur lors de l\'ajout du réseau social', isError: true);
                          }
                        } else {
                          // Edit existing
                          final id = existingSocial!['id'];
                          setState(() {
                            _socials[index!] = {
                              ..._socials[index],
                              'platform': selectedPlatform,
                              'username': input,
                            };
                          });
                          final res = await _api.put('/api/profile/social-links/$id', body: {
                            'platform': selectedPlatform,
                            'username': input,
                            'url': '',
                          });
                          if (!res.isSuccess) {
                            _showToast('Erreur lors de la modification', isError: true);
                          }
                        }
                        _load();
                      },
                      child: Text(
                        isEditing ? 'Enregistrer les modifications' : 'Ajouter au profil',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── REORDER & DELETE LINK ──────────────────────────────

  Future<void> _moveLink(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _links.removeAt(oldIndex);
      _links.insert(newIndex, item);
    });
    for (int i = 0; i < _links.length; i++) {
      _api.put('/api/profile/links/${_links[i]['id']}', body: {'sort_order': i});
    }
  }

  Future<void> _deleteLink(String id) async {
    setState(() {
      _links.removeWhere((l) => l['id'] == id);
    });
    await _api.delete('/api/profile/links/$id');
    _showToast('Lien supprimé');
  }

  Future<void> _deleteSocial(String id) async {
    setState(() {
      _socials.removeWhere((s) => s['id'] == id);
    });
    await _api.delete('/api/profile/social-links/$id');
    _showToast('Réseau social supprimé');
  }

  // ─── QR CODE MODAL ──────────────────────────────

  final GlobalKey _qrKey = GlobalKey();

  Future<void> _downloadQR(String linkyUrl) async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      if (kIsWeb) {
        // Web: trigger browser download
        final blob = bytes;
        final url = Uri.dataFromBytes(blob, mimeType: 'image/png');
        await launchUrl(url);
      }
      _showToast('QR Code téléchargé !');
    } catch (e) {
      _showToast('Erreur lors du téléchargement', isError: true);
    }
  }

  void _showQRCodeModal() {
    final linkyUrl = 'https://linky-to.pages.dev/@$_username';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF5267FF), Color(0xFF8B5CF6)],
                ).createShader(bounds),
                child: const Icon(Icons.qr_code_2_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text('Mon QR Code Linky',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('@$_username',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF5267FF), fontWeight: FontWeight.w600)),
              const SizedBox(height: 22),

              // QR Widget
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5267FF).withValues(alpha: 0.15),
                        blurRadius: 20, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: linkyUrl,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF5267FF),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Color(0xFF1E293B),
                    ),
                    embeddedImage: const AssetImage('assets/logo.png'),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(40, 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(linkyUrl,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 22),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: linkyUrl));
                        if (mounted) Navigator.pop(ctx);
                        _showToast('Lien copié !');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copier'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: const BorderSide(color: Color(0xFF5267FF)),
                        foregroundColor: const Color(0xFF5267FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadQR(linkyUrl),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Sauvegarder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5267FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse(linkyUrl), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Voir mon profil public'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BUILD MAIN UI ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0F3),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 28, height: 28),
            const SizedBox(width: 10),
            const Text('Ma Page Linky', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Générer QR Code',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF5267FF)),
            onPressed: _showQRCodeModal,
          ),
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5267FF)))
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: _buildDashboard(),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddLinkModal(),
        backgroundColor: const Color(0xFF5267FF),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter un Lien', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  // ─── DASHBOARD CONTENT ──────────────────────────────

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 20),
          _buildAnalyticsRow(),
          const SizedBox(height: 28),

          // ─── THEME & DESIGN SECTION ──────────────────────────────
          _buildSectionTitle(
            title: 'Design & Thème',
            count: 0,
            onAdd: _openThemeSettingsModal,
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 12),
          _buildThemeCard(),
          const SizedBox(height: 32),

          // ─── SOCIAL LINKS SECTION ──────────────────────────────
          _buildSectionTitle(
            title: 'Réseaux Sociaux',
            count: _socials.length,
            onAdd: () => _openAddSocialModal(),
            icon: Icons.add_circle_outline_rounded,
          ),
          const SizedBox(height: 12),
          if (_socials.isEmpty)
            _buildEmptyCard('Affichez vos profils Instagram, TikTok, WhatsApp sur votre profil.')
          else
            Wrap(
              spacing: 12, runSpacing: 12,
              children: List.generate(_socials.length, (idx) => _buildSocialTile(_socials[idx], idx)),
            ),

          const SizedBox(height: 32),

          // ─── CUSTOM LINKS SECTION ──────────────────────────────
          _buildSectionTitle(
            title: 'Mes Liens Pro', 
            count: _links.length, 
            onAdd: () => _openAddLinkModal(), 
            icon: Icons.add_circle_outline_rounded
          ),
          const SizedBox(height: 12),

          if (_links.isEmpty)
            _buildEmptyCard('Ajoutez vos liens importants (Boutique, WhatsApp, Portfolio, Offres).')
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _links.length,
              onReorder: _moveLink,
              proxyDecorator: (child, _, __) => Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                child: child,
              ),
              itemBuilder: (context, index) {
                final link = _links[index];
                return _buildLinkCardItem(link: link, index: index, key: ValueKey(link['id']));
              },
            ),

          const SizedBox(height: 32),

          // ─── PORTFOLIO SECTION ──────────────────────────────
          _buildSectionTitle(
            title: 'Portfolio',
            count: _portfolio.length,
            onAdd: () => _openAddProjectModal(),
            icon: Icons.add_circle_outline_rounded,
          ),
          const SizedBox(height: 12),
          if (_portfolio.isEmpty)
            _buildEmptyCard('Ajoutez vos projets et réalisations pour montrer votre travail.')
          else
            Column(
              children: List.generate(_portfolio.length, (idx) => _buildPortfolioItem(_portfolio[idx], idx)),
            ),
        ],
      ),
    );
  }

  // ─── HERO HEADER ──────────────────────────────

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5267FF), Color(0xFF7C3AED)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF5267FF).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                child: _avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 28) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('linky-to.pages.dev/@$_username',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: 'https://linky-to.pages.dev/@$_username'));
                    _showToast('Lien public copié !');
                  },
                  icon: const Icon(Icons.content_copy_rounded, color: Colors.white, size: 16),
                  label: const Text('Copier mon lien', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showQRCodeModal,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Mon QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5267FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── ANALYTICS ROW ──────────────────────────────

  Widget _buildAnalyticsRow() {
    return Row(
      children: [
        _analyticCard(Icons.touch_app_rounded, '$_totalClicks', 'Total Clics', const Color(0xFF5267FF)),
        const SizedBox(width: 12),
        _analyticCard(Icons.link_rounded, '${_links.length}', 'Liens Actifs', const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _analyticCard(Icons.share_rounded, '${_socials.length}', 'Réseaux', const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _analyticCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        depth: 3,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── SECTION TITLE ──────────────────────────────

  Widget _buildSectionTitle({required String title, required int count, required VoidCallback onAdd, required IconData icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(
          children: [
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5267FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5267FF))),
              ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onAdd,
              icon: Icon(icon, color: const Color(0xFF5267FF)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeCard() {
    final bgColor = _themeSettings['bgColor']?.toString() ?? '#FFFFFF';
    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: 16,
      depth: 3,
      child: InkWell(
        onTap: _openThemeSettingsModal,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Color(int.tryParse(bgColor.replaceFirst('#', '0xFF')) ?? 0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personnaliser le Design', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Couleurs, image de couverture, animations', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _openThemeSettingsModal() async {
    String bgColor = _themeSettings['bgColor']?.toString() ?? '#FFFFFF';
    bool useAnimations = _themeSettings['animations'] == true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44, height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Design & Thème', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const Text('Couleur de Fond Principale', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: [
                      '#FFFFFF', '#0F172A', '#F8FAFC', '#FDF4FF', '#ECFEFF', '#5267FF'
                    ].map((color) {
                      final isSelected = bgColor.toUpperCase() == color.toUpperCase();
                      return GestureDetector(
                        onTap: () => setModalState(() => bgColor = color),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF5267FF) : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF5267FF).withValues(alpha: 0.3), blurRadius: 8)] : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SwitchListTile(
                    value: useAnimations,
                    onChanged: (v) => setModalState(() => useAnimations = v),
                    title: const Text('Activer les Micro-Animations', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Les boutons flotteront doucement', style: TextStyle(fontSize: 12)),
                    activeColor: const Color(0xFF5267FF),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5267FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final newSettings = {
                          ..._themeSettings,
                          'bgColor': bgColor,
                          'animations': useAnimations,
                        };
                        setState(() { _themeSettings = newSettings; });
                        
                        await _api.put('/api/profile', body: {
                          'theme_settings': newSettings,
                        });
                        _showToast('Thème sauvegardé');
                        _load();
                      },
                      child: const Text('Sauvegarder le Design', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      depth: 2,
      isInnerShadow: true,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ─── SOCIAL TILE ──────────────────────────────

  Widget _buildSocialTile(Map<String, dynamic> social, int index) {
    final platform = social['platform']?.toString() ?? 'website';
    final info = _platformInfo(platform);
    final username = social['username']?.toString() ?? '';

    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 14,
      depth: 3,
      child: InkWell(
        onTap: () => _openAddSocialModal(existingSocial: social, index: index),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(info['asset'] as String, width: 24, height: 24,
                errorBuilder: (_, __, ___) => Icon(Icons.language, color: info['color'] as Color, size: 22)),
            const SizedBox(width: 8),
            Text('@$username', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(width: 10),
            Icon(Icons.edit_rounded, size: 14, color: (info['color'] as Color).withValues(alpha: 0.8)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _deleteSocial(social['id'].toString()),
              child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LINK CARD ITEM ──────────────────────────────

  Widget _buildLinkCardItem({required Map<String, dynamic> link, required int index, required Key key}) {
    final title = link['title']?.toString() ?? 'Lien';
    final url = link['url']?.toString() ?? '';
    final imageUrl = link['image_url']?.toString();
    final badge = link['badge']?.toString() ?? '';
    final isFeatured = link['is_featured'] == true || link['is_featured'] == 1;
    final platform = _detectPlatform(url);
    final info = _platformInfo(platform);

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 14),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: 18,
        depth: isFeatured ? 5 : 3,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          leading: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: (info['color'] as Color).withValues(alpha: 0.12),
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(info['asset'] as String, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.link, color: info['color'] as Color)),
                  )
                : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              ),
              if (badge.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5267FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5267FF))),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 22, color: Color(0xFF5267FF)),
                onPressed: () => _openAddLinkModal(existingLink: link, index: index),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Colors.redAccent),
                onPressed: () => _deleteLink(link['id'].toString()),
              ),
              const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PORTFOLIO SECTION ──────────────────────────────

  Widget _buildPortfolioItem(Map<String, dynamic> project, int index) {
    final title = project['title']?.toString() ?? '';
    final description = project['description']?.toString() ?? '';
    final category = project['category']?.toString() ?? '';
    String imageUrl = project['image_url']?.toString() ?? '';
    if (imageUrl.isEmpty) {
      try {
        final images = project['images'] as List?;
        if (images != null && images.isNotEmpty) imageUrl = images.first.toString();
      } catch (_) {}
    }
    final keywordsStr = project['keywords']?.toString() ?? '';
    final keywords = keywordsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF5267FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageUrl.isNotEmpty
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, fit: BoxFit.cover))
              : const Icon(Icons.work_outline_rounded, color: Color(0xFF5267FF), size: 28),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            if (category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5267FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5267FF))),
                ),
              ),
            if (keywords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
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
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF5267FF)),
              onPressed: () => _openAddProjectModal(existingProject: project, index: index),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
              onPressed: () => _deleteProject(project['id'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddProjectModal({Map<String, dynamic>? existingProject, int? index}) async {
    final titleCtrl = TextEditingController(text: existingProject?['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existingProject?['description']?.toString() ?? '');
    final categoryCtrl = TextEditingController(text: existingProject?['category']?.toString() ?? '');
    final linkCtrl = TextEditingController(text: existingProject?['link']?.toString() ?? existingProject?['url']?.toString() ?? '');
    String? imageUrl = existingProject?['image_url']?.toString() ?? existingProject?['thumbnail']?.toString();
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 16),
                  Text(existingProject != null ? 'Modifier le projet' : 'Nouveau projet', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _neuTextField(titleCtrl, 'Titre du projet', Icons.title),
                  const SizedBox(height: 12),
                  _neuTextField(descCtrl, 'Description', Icons.description_outlined),
                  const SizedBox(height: 12),
                  _neuTextField(categoryCtrl, 'Catégorie', Icons.category_outlined),
                  const SizedBox(height: 12),
                  _neuTextField(linkCtrl, 'Lien (optionnel)', Icons.link),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          _showToast('Titre requis', isError: true);
                          return;
                        }
                        setModalState(() => isSaving = true);
                        final body = {
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'category': categoryCtrl.text.trim(),
                          'project_url': linkCtrl.text.trim(),
                          if (imageUrl != null) 'image_url': imageUrl,
                        };
                        final res = existingProject != null
                            ? await _api.put('/api/profile/portfolio/${existingProject['id']}', body: body)
                            : await _api.post('/api/profile/portfolio', body: body);
                        if (mounted) {
                          if (res.isSuccess) {
                            Navigator.pop(ctx);
                            _showToast(existingProject != null ? 'Projet modifié !' : 'Projet ajouté !');
                            _load();
                          } else {
                            setModalState(() => isSaving = false);
                            _showToast(res.error ?? 'Erreur', isError: true);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5267FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(existingProject != null ? 'Enregistrer' : 'Ajouter', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProject(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce projet ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await _api.delete('/api/profile/portfolio/$id');
    if (res.isSuccess) {
      _showToast('Projet supprimé');
      _load();
    } else {
      _showToast(res.error ?? 'Erreur', isError: true);
    }
  }

  Widget _neuTextField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF5267FF)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

}
