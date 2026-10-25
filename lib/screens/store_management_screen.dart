import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'store_team_screen.dart';
import 'store_landing_screen.dart';
import '../core/api/api_service.dart';
import '../core/shared_ui.dart';
import 'aliexpress_import_screen.dart';
import 'catalog_add_product_screen.dart';
import 'add_product_screen.dart';

class StoreManagementScreen extends StatefulWidget {
  final Map<String, dynamic> shop;
  const StoreManagementScreen({super.key, required this.shop});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _imagePicker = ImagePicker();
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic> _storeData = {};
  List<Map<String, dynamic>> _stories = [];
  String _announcementBanner = '';
  bool _bannerActive = true;

  // Products
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = false;

  // Tabs
  late TabController _tabController;
  int _currentTab = 0;

  // Dynamic categories
  List<Map<String, dynamic>> _categories = [];
  String _selectedCategory = 'Tous';
  bool _isEditingCategories = false;

  static const List<Color> _availableColors = [
    Color(0xFF5267FF), Color(0xFFEC4899), Color(0xFF8B5CF6),
    Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFFEF4444),
    Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF14B8A6),
    Color(0xFF0EA5E9), Color(0xFFF97316), Color(0xFF84CC16),
    Color(0xFF64748B), Color(0xFFDC2626), Color(0xFF7C3AED),
  ];

  static const List<Map<String, dynamic>> _frameStyles = [
    {'key': 'filled', 'label': 'Rempli', 'icon': Icons.stop_rounded},
    {'key': 'outline', 'label': 'Contour', 'icon': Icons.crop_square_rounded},
    {'key': 'pill', 'label': 'Pilule', 'icon': Icons.album_rounded},
    {'key': 'rounded', 'label': 'Arrondi', 'icon': Icons.rounded_corner_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _storeData = Map<String, dynamic>.from(widget.shop);
    _dashboard = {'summary': {'revenue': 0, 'orders': 0, 'delivered': 0}};

    final settings = _parseJson(_storeData['settings']);
    _announcementBanner = settings['announcement']?.toString() ?? '';
    _bannerActive = settings['banner_active'] ?? true;

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTab = _tabController.index);
    });

    _loadDashboard();
    _loadStories();
    _loadProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseJson(dynamic value) {
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(value));
      } catch (_) {}
    }
    return {};
  }

  Future<void> _loadDashboard() async {
    final id = _storeData['id']?.toString();
    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _dashboard = {'summary': {'revenue': 0, 'orders': 0, 'delivered': 0}});
      return;
    }
    try {
      final response = await _api.get('/api/stores/$id/dashboard');
      if (mounted) {
        setState(() => _dashboard = response.isSuccess ? response.data : {'summary': {'revenue': 0, 'orders': 0, 'delivered': 0}});
      }
    } catch (_) {
      if (mounted) setState(() => _dashboard = {'summary': {'revenue': 0, 'orders': 0, 'delivered': 0}});
    }
  }

  Future<void> _loadStories() async {
    final id = _storeData['id']?.toString();
    if (id == null || id.isEmpty) return;
    final res = await _api.get('/api/stories');
    if (mounted && res.isSuccess) {
      setState(() {
        _stories = List<Map<String, dynamic>>.from(res.data?['stories'] ?? []);
      });
    }
  }

  /// Normalize product data from API (base_price→price, images string→array)
  Map<String, dynamic> _normalizeProduct(Map<String, dynamic> raw) {
    final images = raw['images'];
    List<dynamic> parsedImages = [];
    if (images is String && images.isNotEmpty) {
      try { parsedImages = json.decode(images); } catch (_) {}
    } else if (images is List) {
      parsedImages = images;
    }
    return {
      'id': raw['id'],
      'name': raw['name'] ?? '',
      'slug': raw['slug'] ?? '',
      'description': raw['description'] ?? '',
      'base_price': raw['base_price'] ?? 0,
      'discount_price': raw['discount_price'],
      'images': parsedImages,
      'category': raw['category'] ?? raw['category_name'] ?? '',
      'category_id': raw['category_id'] ?? '',
      'avg_rating': raw['avg_rating'] ?? 0,
      'total_sold': raw['total_sold'] ?? 0,
      'stock': raw['stock'] ?? 0,
      'is_active': raw['is_active'] ?? true,
      'created_at': raw['created_at'] ?? '',
      'variants': raw['variants'] ?? [],
    };
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final storeId = _storeData['id']?.toString();
      if (storeId == null) {
        if (mounted) setState(() => _isLoadingProducts = false);
        return;
      }
      // Use /api/stores/{storeId}/products instead of /api/products (which returns empty)
      final res = await _api.get('/api/stores/$storeId/products', queryParams: {'limit': '50'});
      if (res.isSuccess && res.data != null) {
        final list = res.data?['products'] ?? res.data?['data'] ?? res.data?['results'] ?? [];
        if (list is List) {
          _products = list.map((e) => _normalizeProduct(Map<String, dynamic>.from(e))).toList();
        }
      } else {
        debugPrint('StoreManagement: Failed to load products: ${res.error}');
      }
    } catch (e) {
      debugPrint('StoreManagement: Error loading products: $e');
    }
    if (mounted) setState(() => _isLoadingProducts = false);
  }

  // ─── CATEGORIES CRUD ──────────────────────────────

  Future<void> _loadCategories() async {
    final storeId = _storeData['id']?.toString();
    if (storeId == null || storeId.isEmpty) {
      _setDefaultCategories();
      return;
    }
    try {
      final res = await _api.get('/api/store-categories', queryParams: {'store_id': storeId});
      if (res.isSuccess && res.data != null) {
        final list = res.data?['categories'] ?? [];
        if (list is List && list.isNotEmpty) {
          setState(() {
            _categories = list.map<Map<String, dynamic>>((c) => {
              'id': c['id'],
              'name': c['name'] ?? '',
              'color_val': c['color_val'] ?? 0xFF5267FF,
              'frame_style': c['frame_style'] ?? 'filled',
              'order': c['sort_order'] ?? 0,
            }).toList();
          });
          return;
        }
      }
    } catch (_) {}
    _setDefaultCategories();
  }

  void _setDefaultCategories() {
    setState(() {
      _categories = [
        {'id': '1', 'name': 'Catégorie 1', 'color_val': 0xFF5267FF, 'frame_style': 'filled', 'order': 0},
        {'id': '2', 'name': 'Catégorie 2', 'color_val': 0xFFEC4899, 'frame_style': 'filled', 'order': 1},
        {'id': '3', 'name': 'Catégorie 3', 'color_val': 0xFF10B981, 'frame_style': 'filled', 'order': 2},
      ];
    });
  }

  Future<void> _saveCategories() async {
    final storeId = _storeData['id']?.toString();
    if (storeId == null) return;
    try {
      final order = _categories.map((c) => c['id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      await _api.put('/api/store-categories/reorder', body: {'store_id': storeId, 'order': order});
    } catch (e) {
      debugPrint('StoreManagement: Error reordering categories: $e');
    }
  }

  void _addCategory() {
    _openCategoryModal(isEdit: false);
  }

  void _editCategory(int index) {
    _openCategoryModal(isEdit: true, categoryIndex: index);
  }

  Future<void> _deleteCategory(int index) async {
    final catId = _categories[index]['id']?.toString();
    if (catId != null && catId.length > 10) {
      await _api.delete('/api/store-categories/$catId');
    }
    setState(() {
      _categories.removeAt(index);
      for (int i = 0; i < _categories.length; i++) {
        _categories[i]['order'] = i;
      }
    });
    _showToast('Catégorie supprimée');
  }

  void _reorderCategories(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
      for (int i = 0; i < _categories.length; i++) {
        _categories[i]['order'] = i;
      }
    });
    _saveCategories();
  }

  // ─── CATEGORY MODAL ──────────────────────────────

  void _openCategoryModal({required bool isEdit, int categoryIndex = -1}) {
    final nameCtrl = TextEditingController(
      text: isEdit && categoryIndex >= 0 ? _categories[categoryIndex]['name']?.toString() ?? '' : '',
    );
    int selectedColorVal = isEdit && categoryIndex >= 0 ? (_categories[categoryIndex]['color_val'] ?? 0xFFEC4899) : 0xFFEC4899;
    String selectedFrameStyle = isEdit && categoryIndex >= 0 ? (_categories[categoryIndex]['frame_style'] ?? 'filled') : 'filled';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMState) => Container(
          height: MediaQuery.sizeOf(context).height * 0.60,
          decoration: BoxDecoration(
            color: clayScaffoldBg(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 20),
                Text(isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Name field (max 10 chars)
                TextField(
                  controller: nameCtrl,
                  maxLength: 10,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Nom (10 car. max)',
                    prefixIcon: const Icon(Icons.abc, color: Color(0xFF5267FF), size: 20),
                    filled: true, fillColor: const Color(0xFFF8F9FC),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: clayBorder(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5267FF), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 24),

                // Color picker
                const Text('Couleur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _availableColors.map((c) {
                    final isSelected = selectedColorVal == c.toARGB32();
                    return GestureDetector(
                      onTap: () => setMState(() => selectedColorVal = c.toARGB32()),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Frame style picker
                const Text('Style du cadre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: _frameStyles.map((fs) {
                    final isSelected = selectedFrameStyle == fs['key'];
                    final color = Color(selectedColorVal);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setMState(() => selectedFrameStyle = fs['key']),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
                          ),
                          child: Column(
                            children: [
                              Icon(fs['icon'] as IconData, color: isSelected ? color : Colors.grey, size: 24),
                              const SizedBox(height: 4),
                              Text(fs['label'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Live preview
                Center(
                  child: _buildCategoryChipPreview(
                    nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Aperçu',
                    Color(selectedColorVal),
                    selectedFrameStyle,
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5267FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        _showToast('Entrez un nom', isError: true);
                        return;
                      }
                      Navigator.pop(context);
                      final storeId = _storeData['id']?.toString();
                      if (storeId == null) return;

                      if (isEdit && categoryIndex >= 0) {
                        final catId = _categories[categoryIndex]['id']?.toString();
                        if (catId != null && catId.length > 10) {
                          await _api.put('/api/store-categories/$catId', body: {
                            'name': name, 'color_val': selectedColorVal, 'frame_style': selectedFrameStyle,
                          });
                        }
                        setState(() {
                          _categories[categoryIndex]['name'] = name;
                          _categories[categoryIndex]['color_val'] = selectedColorVal;
                          _categories[categoryIndex]['frame_style'] = selectedFrameStyle;
                        });
                      } else {
                        final res = await _api.post('/api/store-categories', body: {
                          'store_id': storeId, 'name': name, 'color_val': selectedColorVal, 'frame_style': selectedFrameStyle,
                        });
                        if (res.isSuccess && res.data != null) {
                          setState(() {
                            _categories.add({
                              'id': res.data!['id'],
                              'name': name,
                              'color_val': selectedColorVal,
                              'frame_style': selectedFrameStyle,
                              'order': _categories.length,
                            });
                          });
                        }
                      }
                      _showToast(isEdit ? 'Catégorie modifiée !' : 'Catégorie ajoutée !');
                    },
                    child: Text(isEdit ? 'Modifier' : 'Ajouter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChipPreview(String name, Color color, String style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: _categoryDecoration(color, style),
      child: Text(
        name,
        style: TextStyle(
          color: style == 'outline' || style == 'ghost' ? color : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  BoxDecoration _categoryDecoration(Color color, String style) {
    switch (style) {
      case 'outline':
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 2),
        );
      case 'pill':
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(50),
        );
      case 'rounded':
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        );
      case 'filled':
      default:
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        );
    }
  }

  // ─── ASSIGN CATEGORY TO PRODUCT ──────────────────────────────

  void _showAssignCategorySheet(Map<String, dynamic> product) {
    final currentCategory = product['category']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: clayScaffoldBg(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 44, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            const Text('Assigner une catégorie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(_categories.length, (i) {
              final cat = _categories[i];
              final catColor = Color(cat['color_val'] ?? 0xFF5267FF);
              final style = cat['frame_style'] ?? 'filled';
              final isCurrent = currentCategory == cat['name'];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: _categoryChipDecoration(catColor, style, false),
                  child: Text(
                    (cat['name']?.toString() ?? '').substring(0, (cat['name']?.toString() ?? '').length > 4 ? 4 : (cat['name']?.toString() ?? '').length),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: style == 'outline' || style == 'ghost' ? catColor : Colors.white),
                  ),
                ),
                title: Text(cat['name']?.toString() ?? '', style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500)),
                trailing: isCurrent ? const Icon(Icons.check_circle, color: Color(0xFF5267FF)) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  final id = _storeData['id']?.toString();
                  if (id != null) {
                    final res = await _api.put('/api/products/${product['id']}', body: {'category': cat['name']});
                    if (res.isSuccess) {
                      _showToast('Produit assigné à ${cat['name']}');
                      _loadProducts();
                    }
                  }
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showToast(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── SAFE IMAGE EXTRACTION ──────────────────────────────

  List<String> _extractImages(Map<String, dynamic> product) {
    final images = product['images'];
    if (images == null) return [];
    if (images is List) return images.map((e) => e.toString()).toList();
    if (images is String && images.isNotEmpty) {
      try {
        final decoded = json.decode(images);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    final imageUrl = product['image_url']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) return [imageUrl];
    final thumbnail = product['thumbnail']?.toString();
    if (thumbnail != null && thumbnail.isNotEmpty) return [thumbnail];
    return [];
  }

  // ─── 3-DOT MENU ──────────────────────────────

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: clayScaffoldBg(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 16),
            _menuOption(Icons.category_outlined, 'Gérer les catégories', () {
              Navigator.pop(ctx);
              _tabController.animateTo(1);
            }),
            _menuOption(Icons.edit_rounded, 'Modifier la boutique', () {
              Navigator.pop(ctx);
              _openEditStoreModal();
            }),
            _menuOption(Icons.campaign_rounded, 'Bannière publicitaire', () {
              Navigator.pop(ctx);
              _openAnnouncementBannerModal();
            }),
            _menuOption(Icons.auto_awesome_motion_rounded, 'Ajouter une story', () {
              Navigator.pop(ctx);
              _openAddStoryModal();
            }),
            _menuOption(Icons.groups_outlined, 'Gestion de l\'équipe', () {
              Navigator.pop(ctx);
              final id = _storeData['id']?.toString();
              if (id != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => StoreTeamScreen(storeId: id, storeName: _storeData['name']?.toString() ?? 'Store')));
              }
            }),
            _menuOption(Icons.cloud_download_outlined, 'Importer AliExpress', () {
              Navigator.pop(ctx);
              final id = _storeData['id']?.toString();
              if (id != null) Navigator.push(context, MaterialPageRoute(builder: (_) => AliExpressImportScreen(storeId: id)));
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _menuOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF5267FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF5267FF), size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  // ─── EDIT STORE MODAL ──────────────────────────────

  Future<void> _openEditStoreModal() async {
    final nameCtrl = TextEditingController(text: _storeData['name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: _storeData['description']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: _storeData['phone']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: _storeData['email']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: _storeData['address']?.toString() ?? '');
    final cityCtrl = TextEditingController(text: _storeData['city']?.toString() ?? '');
    final websiteCtrl = TextEditingController(text: _storeData['website']?.toString() ?? '');
    final mapsUrlCtrl = TextEditingController(text: _storeData['maps_url']?.toString() ?? '');
    String? logoUrl = _storeData['logo_url']?.toString();
    String? coverUrl = _storeData['cover_url']?.toString();
    final settings = _parseJson(_storeData['settings']);
    final deliveryFeeCtrl = TextEditingController(text: (settings['delivery_fee'] ?? 500).toString());
    String deliveryMode = settings['delivery_mode'] ?? 'fixed';
    final ctaCtrl = TextEditingController(text: settings['cta_button']?.toString() ?? 'Commander');
    final countryCtrl = TextEditingController(text: _storeData['country']?.toString() ?? 'Algeria');
    final stateCtrl = TextEditingController(text: _storeData['state']?.toString() ?? '');
    final socialLinks = _parseJson(_storeData['social_links']);
    final socialIgCtrl = TextEditingController(text: socialLinks['instagram']?.toString() ?? '');
    final socialTiktokCtrl = TextEditingController(text: socialLinks['tiktok']?.toString() ?? '');
    final socialFbCtrl = TextEditingController(text: socialLinks['facebook']?.toString() ?? '');
    final socialWACtrl = TextEditingController(text: socialLinks['whatsapp']?.toString() ?? '');
    final socialYtCtrl = TextEditingController(text: socialLinks['youtube']?.toString() ?? '');
    bool showReviews = settings['show_reviews'] ?? true;
    bool showFollowers = settings['show_followers'] ?? true;
    bool showPopular = settings['show_popular'] ?? true;
    bool showStories = settings['show_stories'] ?? true;
    String primaryColor = settings['primary_color']?.toString() ?? '#5267FF';

    final categories = ['Beauty', 'Fashion', 'Electronics', 'Home', 'Sports', 'Food', 'Automotive', 'Health', 'Kids', 'Other'];
    String selectedCategory = _storeData['category']?.toString() ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMState) => Container(
          height: MediaQuery.sizeOf(context).height * 0.92,
          decoration: BoxDecoration(
            color: clayScaffoldBg(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 20),
                const Text('Modifier la Boutique', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Cover & Logo
                GestureDetector(
                  onTap: () async {
                    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final upload = await _api.upload('/api/upload', bytes, 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg', folder: 'stores');
                      if (upload.isSuccess && upload.data?['url'] != null) setMState(() => coverUrl = upload.data!['url'].toString());
                    }
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5267FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      image: coverUrl != null && coverUrl!.isNotEmpty ? DecorationImage(image: NetworkImage(coverUrl!), fit: BoxFit.cover) : null,
                    ),
                    child: coverUrl == null || coverUrl!.isEmpty
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF5267FF), size: 32),
                            SizedBox(height: 4),
                            Text('Changer la couverture', style: TextStyle(fontSize: 12, color: Color(0xFF5267FF))),
                          ])
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        final upload = await _api.upload('/api/upload', bytes, 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg', folder: 'stores');
                        if (upload.isSuccess && upload.data?['url'] != null) setMState(() => logoUrl = upload.data!['url'].toString());
                      }
                    },
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF5267FF), width: 3),
                        image: logoUrl != null && logoUrl!.isNotEmpty ? DecorationImage(image: NetworkImage(logoUrl!), fit: BoxFit.cover) : null,
                        color: const Color(0xFFF8F9FC),
                      ),
                      child: logoUrl == null || logoUrl!.isEmpty ? const Icon(Icons.add_a_photo_outlined, color: Color(0xFF5267FF)) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── INFORMATIONS ──
                _sectionTitle('Informations'),
                const SizedBox(height: 10),
                _neuTextField(nameCtrl, 'Nom de la Boutique', Icons.store_rounded),
                const SizedBox(height: 12),
                _neuTextField(descCtrl, 'Description', Icons.description_outlined, maxLines: 2),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _neuTextField(phoneCtrl, 'Téléphone', Icons.phone_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _neuTextField(emailCtrl, 'Email', Icons.email_outlined)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _neuTextField(cityCtrl, 'Ville', Icons.location_city_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _neuTextField(addressCtrl, 'Adresse', Icons.location_on_outlined)),
                ]),
                const SizedBox(height: 12),
                _neuTextField(websiteCtrl, 'Site web', Icons.language),
                const SizedBox(height: 12),
                _neuTextField(mapsUrlCtrl, 'Google Maps URL', Icons.map_outlined),
                const SizedBox(height: 24),

                // ─── CATEGORIE ──
                _sectionTitle('Catégorie'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: categories.map((c) {
                    final sel = selectedCategory == c;
                    return GestureDetector(
                      onTap: () => setMState(() => selectedCategory = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF5267FF) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? const Color(0xFF5267FF) : clayBorder(context)),
                        ),
                        child: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade700)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ─── LOCALISATION ──
                _sectionTitle('Localisation'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _neuTextField(countryCtrl, 'Pays', Icons.public)),
                  const SizedBox(width: 12),
                  Expanded(child: _neuTextField(stateCtrl, 'Wilaya / Région', Icons.map)),
                ]),
                const SizedBox(height: 24),

                // ─── LIVRAISON ──
                _sectionTitle('Livraison'),
                const SizedBox(height: 10),
                Row(children: [
                  _deliveryChip('Gratuite', Icons.check_circle_outline, 'free', deliveryMode, (v) => setMState(() => deliveryMode = v)),
                  const SizedBox(width: 8),
                  _deliveryChip('Fixe', Icons.attach_money, 'fixed', deliveryMode, (v) => setMState(() => deliveryMode = v)),
                  const SizedBox(width: 8),
                  _deliveryChip('Wilaya', Icons.map_outlined, 'wilaya', deliveryMode, (v) => setMState(() => deliveryMode = v)),
                ]),
                if (deliveryMode == 'fixed') ...[
                  const SizedBox(height: 12),
                  _neuTextField(deliveryFeeCtrl, 'Prix fixe (DA)', Icons.local_shipping_outlined, keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 12),
                _neuTextField(ctaCtrl, 'Texte bouton CTA', Icons.ads_click),
                const SizedBox(height: 24),

                // ─── RESEAUX SOCIAUX ──
                _sectionTitle('Réseaux Sociaux'),
                const SizedBox(height: 10),
                _neuTextField(socialIgCtrl, 'Instagram', Icons.camera_alt_outlined),
                const SizedBox(height: 12),
                _neuTextField(socialTiktokCtrl, 'TikTok', Icons.music_note),
                const SizedBox(height: 12),
                _neuTextField(socialFbCtrl, 'Facebook', Icons.facebook),
                const SizedBox(height: 12),
                _neuTextField(socialWACtrl, 'WhatsApp', Icons.chat),
                const SizedBox(height: 12),
                _neuTextField(socialYtCtrl, 'YouTube', Icons.play_circle_outline),
                const SizedBox(height: 24),

                // ─── AFFICHAGE ──
                _sectionTitle('Affichage du Store'),
                const SizedBox(height: 10),
                _toggleRow('Afficher les avis', showReviews, (v) => setMState(() => showReviews = v)),
                _toggleRow('Afficher les abonnés', showFollowers, (v) => setMState(() => showFollowers = v)),
                _toggleRow('Afficher les populaires', showPopular, (v) => setMState(() => showPopular = v)),
                _toggleRow('Afficher les stories', showStories, (v) => setMState(() => showStories = v)),
                const SizedBox(height: 24),

                // ─── COULEUR ──
                _sectionTitle('Couleur du thème'),
                const SizedBox(height: 10),
                Row(
                  children: ['#5267FF', '#EF4444', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899'].map((c) {
                    final sel = primaryColor == c;
                    return GestureDetector(
                      onTap: () => setMState(() => primaryColor = c),
                      child: Container(
                        width: 36, height: 36, margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: sel ? Border.all(color: Colors.black, width: 3) : null,
                        ),
                        child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // ─── SAVE ──
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5267FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final id = _storeData['id']?.toString();
                      if (id == null) return;
                      Navigator.pop(context);
                      final body = {
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'address': addressCtrl.text.trim(),
                        'city': cityCtrl.text.trim(),
                        'website': websiteCtrl.text.trim(),
                        'maps_url': mapsUrlCtrl.text.trim(),
                        'category': selectedCategory,
                        'country': countryCtrl.text.trim(),
                        'state': stateCtrl.text.trim(),
                        if (logoUrl != null) 'logo_url': logoUrl,
                        if (coverUrl != null) 'cover_url': coverUrl,
                        'social_links': {
                          if (socialIgCtrl.text.isNotEmpty) 'instagram': socialIgCtrl.text.trim(),
                          if (socialTiktokCtrl.text.isNotEmpty) 'tiktok': socialTiktokCtrl.text.trim(),
                          if (socialFbCtrl.text.isNotEmpty) 'facebook': socialFbCtrl.text.trim(),
                          if (socialWACtrl.text.isNotEmpty) 'whatsapp': socialWACtrl.text.trim(),
                          if (socialYtCtrl.text.isNotEmpty) 'youtube': socialYtCtrl.text.trim(),
                        },
                        'settings': {
                          ...settings,
                          'delivery_mode': deliveryMode,
                          'delivery_fee': deliveryMode == 'fixed' ? (double.tryParse(deliveryFeeCtrl.text) ?? 500) : 0,
                          'delivery_free': deliveryMode == 'free',
                          'cta_button': ctaCtrl.text.trim().isNotEmpty ? ctaCtrl.text.trim() : 'Commander',
                          'primary_color': primaryColor,
                          'show_reviews': showReviews,
                          'show_followers': showFollowers,
                          'show_popular': showPopular,
                          'show_stories': showStories,
                        },
                      };
                      setState(() {
                        _storeData['name'] = nameCtrl.text.trim();
                        _storeData['description'] = descCtrl.text.trim();
                        _storeData['phone'] = phoneCtrl.text.trim();
                        _storeData['email'] = emailCtrl.text.trim();
                        _storeData['address'] = addressCtrl.text.trim();
                        _storeData['city'] = cityCtrl.text.trim();
                        _storeData['website'] = websiteCtrl.text.trim();
                        _storeData['maps_url'] = mapsUrlCtrl.text.trim();
                        _storeData['category'] = selectedCategory;
                        _storeData['country'] = countryCtrl.text.trim();
                        _storeData['state'] = stateCtrl.text.trim();
                        if (logoUrl != null) _storeData['logo_url'] = logoUrl;
                        if (coverUrl != null) _storeData['cover_url'] = coverUrl;
                        _storeData['social_links'] = jsonEncode(body['social_links']);
                        _storeData['settings'] = jsonEncode(body['settings']);
                      });
                      final res = await _api.put('/api/stores/$id', body: body);
                      debugPrint('Store PUT: ${res.statusCode} ${res.error} data=${res.data}');
                      _showToast(res.isSuccess ? 'Boutique mise à jour !' : 'Erreur: ${res.error ?? "status ${res.statusCode}"}', isError: !res.isSuccess);
                    },
                    child: const Text('Enregistrer tout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF5267FF), borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      ],
    );
  }

  Widget _toggleRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5267FF),
          ),
        ],
      ),
    );
  }

  Widget _neuTextField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5267FF), size: 20),
        filled: true, fillColor: const Color(0xFFF8F9FC),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: clayBorder(context))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5267FF), width: 1.5)),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
    );
  }

  Widget _deliveryChip(String label, IconData icon, String mode, String current, Function(String) onTap) {
    final isSelected = current == mode;
    final color = mode == 'free' ? const Color(0xFF10B981) : mode == 'fixed' ? const Color(0xFF5267FF) : const Color(0xFFF59E0B);
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(14),
            border: isSelected ? Border.all(color: color, width: 1.5) : Border.all(color: clayBorder(context)),
          ),
          child: Column(children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? color : Colors.grey)),
          ]),
        ),
      ),
    );
  }

  // ─── BANNER MODAL ──────────────────────────────

  Future<void> _openAnnouncementBannerModal() async {
    final bannerCtrl = TextEditingController(text: _announcementBanner);
    bool isActive = _bannerActive;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMState) => Container(
          height: MediaQuery.sizeOf(context).height * 0.6,
          decoration: BoxDecoration(
            color: clayScaffoldBg(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 20),
              const Text('Bannière Publicitaire', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Texte défilant en haut de votre boutique', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              TextField(controller: bannerCtrl, maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ex: 🔥 Offre Spéciale: -20% avec le code VIP2026 !',
                  filled: true, fillColor: const Color(0xFFF8F9FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: clayBorder(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: clayBorder(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('Activer', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(
                  value: isActive,
                  onChanged: (v) => setMState(() => isActive = v),
                  activeColor: const Color(0xFF10B981),
                ),
              ]),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () async {
                    final text = bannerCtrl.text.trim();
                    Navigator.pop(context);
                    setState(() { _announcementBanner = text; _bannerActive = isActive; });
                    final id = _storeData['id']?.toString();
                    if (id != null) {
                      final currentSettings = _parseJson(_storeData['settings']);
                      currentSettings['announcement'] = text;
                      currentSettings['banner_active'] = isActive;
                      await _api.put('/api/stores/$id', body: {'settings': currentSettings});
                    }
                    _showToast('Pub enregistrée !');
                  },
                  child: const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── STORY MODAL ──────────────────────────────

  Future<void> _openAddStoryModal() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final upload = await _api.upload('/api/upload', bytes, 'story_${DateTime.now().millisecondsSinceEpoch}.jpg', folder: 'stories');
    if (upload.isSuccess && upload.data?['url'] != null) {
      final res = await _api.post('/api/stories', body: {'image_url': upload.data!['url'].toString(), 'store_id': _storeData['id']});
      if (res.isSuccess) {
        _showToast('Story publiée !');
        _loadStories();
      } else {
        _showToast('Erreur publication', isError: true);
      }
    }
  }

  // ─── ADD PRODUCT ──────────────────────────────

  void _openAddProduct() {
    final id = _storeData['id']?.toString();
    if (id != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CatalogAddProductScreen(storeId: id, onProductAdded: () {
          _loadProducts();
          _loadDashboard();
        }),
      ));
    }
  }

  Future<void> _openEditProduct(Map<String, dynamic> product) async {
    final id = _storeData['id']?.toString();
    if (id == null) return;
    final productId = product['id']?.toString();
    if (productId == null) return;

    List<Map<String, dynamic>> existingVariants = [];
    try {
      final vRes = await _api.get('/api/products/$productId/variants');
      if (vRes.isSuccess && vRes.data != null) {
        final vList = vRes.data?['variants'] ?? [];
        if (vList is List) {
          existingVariants = vList.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {}

    if (!mounted) return;
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddProductScreen(
        storeId: id,
        product: product,
        existingVariants: existingVariants,
      ),
    ));
    if (result == true) {
      _loadProducts();
      _loadDashboard();
    }
  }

  // ─── DELETE PRODUCT ──────────────────────────────

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le produit'),
        content: const Text('Êtes-vous sûr ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await _api.delete('/api/products/$productId');
    if (res.isSuccess) {
      _showToast('Produit supprimé');
      _loadProducts();
    }
  }

  // ─── MAIN BUILD ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    final storeName = _storeData['name']?.toString() ?? 'Boutique';
    final coverUrl = _storeData['cover_url']?.toString() ?? '';
    final logoUrl = _storeData['logo_url']?.toString() ?? '';
    final description = _storeData['description']?.toString() ?? 'Boutique en ligne';
    final city = _storeData['city']?.toString() ?? '';
    final summary = _dashboard?['summary'] as Map<String, dynamic>?;
    final totalFollowers = _storeData['total_followers'] ?? 0;
    final rating = (_storeData['rating'] ?? 4.9).toDouble();

    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      body: CustomScrollView(
        slivers: [
          // ─── COVER HEADER ──────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    image: coverUrl.isNotEmpty ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover) : null,
                  ),
                  child: coverUrl.isEmpty
                      ? const Center(child: Icon(Icons.storefront, size: 60, color: Colors.grey))
                      : null,
                ),
                // Gradient overlay
                Positioned(
                  top: 0, left: 0, right: 0, height: 180,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                      ),
                    ),
                  ),
                ),
                // Top bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16, right: 16,
                  child: Row(
                    children: [
                      _circleButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                      const Spacer(),
                      _circleButton(Icons.visibility_outlined, () {
                        final slug = _storeData['slug']?.toString();
                        if (slug != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StoreLandingScreen(slug: slug)));
                        }
                      }),
                      const SizedBox(width: 8),
                      _circleButton(Icons.more_vert_rounded, _showMenuOptions),
                    ],
                  ),
                ),
                // Logo
                Positioned(
                  bottom: -35,
                  left: 24,
                  child: Container(
                    width: 75, height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: logoUrl.isNotEmpty
                          ? Image.network(logoUrl, fit: BoxFit.cover)
                          : Center(child: Text(storeName[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5267FF)))),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── STORE INFO ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 45, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(storeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Color(0xFF5267FF), size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    children: [
                      _infoChip(Icons.star_rounded, '$rating', Colors.amber),
                      const SizedBox(width: 12),
                      if (city.isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(city, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('$totalFollowers abonnés', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5267FF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _openAddProduct,
                          icon: const Icon(Icons.add, color: Colors.white, size: 20),
                          label: const Text('Nouveau Produit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: Color(0xFF5267FF)),
                          ),
                          onPressed: _openEditStoreModal,
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF5267FF), size: 20),
                          label: const Text('Modifier', style: TextStyle(color: Color(0xFF5267FF), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Social Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialIcon(Icons.camera_alt_outlined, const Color(0xFFE4405F)), // Instagram
                      const SizedBox(width: 16),
                      _socialIcon(Icons.music_note_outlined, Colors.black), // TikTok
                      const SizedBox(width: 16),
                      _socialIcon(Icons.facebook, const Color(0xFF1877F2)), // Facebook
                      const SizedBox(width: 16),
                      _socialIcon(Icons.phone, const Color(0xFF25D366)), // WhatsApp
                      const SizedBox(width: 16),
                      _socialIcon(Icons.language, const Color(0xFF5267FF)), // Website
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── TABS ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: BoxDecoration(
                color: clayCard(context),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: clayBorder(context), width: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF5267FF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF5267FF),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Accueil'),
                  Tab(text: 'Produits'),
                  Tab(text: 'Collections'),
                  Tab(text: 'Avis'),
                  Tab(text: 'À propos'),
                ],
              ),
            ),
          ),

          // ─── TAB CONTENT ──────────────────────────────
          if (_currentTab == 0) ...[
            // Accueil Tab
            SliverToBoxAdapter(child: _buildAnnouncementBanner()),
            SliverToBoxAdapter(child: _buildDashboardStats()),
            SliverToBoxAdapter(child: _buildStoriesSection()),
            SliverToBoxAdapter(child: _buildCategoriesSection()),
            SliverToBoxAdapter(child: _buildPopularProductsHeader()),
            SliverToBoxAdapter(child: _buildProductsGrid()),
          ] else if (_currentTab == 1) ...[
            // Produits Tab
            SliverToBoxAdapter(child: _buildStoriesSection()),
            SliverToBoxAdapter(child: _buildCategoriesSection()),
            SliverToBoxAdapter(child: _buildProductsGrid()),
          ] else if (_currentTab == 2) ...[
            // Collections Tab
            SliverToBoxAdapter(child: _buildCollectionsSection()),
          ] else if (_currentTab == 3) ...[
            // Avis Tab
            SliverToBoxAdapter(child: _buildReviewsSection()),
          ] else ...[
            // À propos Tab
            SliverToBoxAdapter(child: _buildAboutSection()),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ──────────────────────────────

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: clayCard(context),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ─── ANNOUNCEMENT BANNER ──────────────────────────────

  Widget _buildAnnouncementBanner() {
    if (!_bannerActive || _announcementBanner.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5267FF), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.amberAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_announcementBanner, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ─── DASHBOARD STATS ──────────────────────────────

  Widget _buildDashboardStats() {
    final summary = _dashboard?['summary'] as Map<String, dynamic>?;
    if (summary == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _statCard('${summary['revenue'] ?? 0} DA', 'Revenu', Icons.payments_outlined, const Color(0xFF5267FF)),
          const SizedBox(width: 12),
          _statCard('${summary['orders'] ?? 0}', 'Commandes', Icons.receipt_long_outlined, const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _statCard('${summary['delivered'] ?? 0}', 'Livrées', Icons.local_shipping_outlined, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  // ─── CATEGORIES SECTION ──────────────────────────────

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Catégories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (v) {
                  if (v == 'edit') setState(() => _isEditingCategories = !_isEditingCategories);
                  if (v == 'add') _addCategory();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Row(
                    children: [
                      Icon(_isEditingCategories ? Icons.check : Icons.edit_outlined, size: 18, color: const Color(0xFF5267FF)),
                      const SizedBox(width: 10),
                      Text(_isEditingCategories ? 'Terminer' : 'Modifier les catégories'),
                    ],
                  )),
                  const PopupMenuItem(value: 'add', child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: Color(0xFF5267FF)),
                      SizedBox(width: 10),
                      Text('Ajouter une catégorie'),
                    ],
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable category chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = 'Tous'),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedCategory == 'Tous' ? const Color(0xFF5267FF) : const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _selectedCategory == 'Tous' ? const Color(0xFF5267FF) : clayBorder(context)),
                    ),
                    child: Text('Tous', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _selectedCategory == 'Tous' ? Colors.white : Colors.black87)),
                  ),
                ),
                ..._categories.map((cat) {
                  final catColor = Color(cat['color_val'] ?? 0xFF5267FF);
                  final style = cat['frame_style'] ?? 'filled';
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['name']?.toString() ?? 'Tous'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: _categoryChipDecoration(catColor, style, isSelected),
                      child: Text(
                        cat['name']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: (style == 'outline' && !isSelected) || style == 'ghost' ? catColor : Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          if (_isEditingCategories) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: clayCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: clayBorder(context)),
              ),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                onReorder: _reorderCategories,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final catColor = Color(cat['color_val'] ?? 0xFF5267FF);
                  final style = cat['frame_style'] ?? 'filled';
                  return Container(
                    key: ValueKey(cat['id']),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: _categoryChipDecoration(catColor, style, false),
                          child: Text(
                            cat['name']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: style == 'outline' || style == 'ghost' ? catColor : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(cat['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                        GestureDetector(
                          onTap: () => _editCategory(i),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFF5267FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF5267FF)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _confirmDeleteCategory(i),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ReorderableDragStartListener(
                          index: i,
                          child: Icon(Icons.drag_handle, color: Colors.grey.shade400, size: 20),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _categoryChipDecoration(Color color, String style, bool isSelected) {
    switch (style) {
      case 'outline':
        return BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 2),
        );
      case 'pill':
        return BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(50),
        );
      case 'rounded':
        return BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        );
      case 'filled':
      default:
        return BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
        );
    }
  }

  void _confirmDeleteCategory(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la catégorie'),
        content: Text('Supprimer "${_categories[index]['name']}" ? Les produits ne seront pas supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () { Navigator.pop(ctx); _deleteCategory(index); }, child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // ─── POPULAR PRODUCTS HEADER ──────────────────────────────

  Widget _buildPopularProductsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Produits populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          Text('Voir tout', style: TextStyle(color: const Color(0xFF5267FF), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── STORIES SECTION ──────────────────────────────

  Widget _buildStoriesSection() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        itemCount: _stories.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return GestureDetector(
              onTap: _openAddStoryModal,
              child: Container(
                width: 68, margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF5267FF), width: 2, strokeAlign: BorderSide.strokeAlignOutside),
                        color: const Color(0xFF5267FF).withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF5267FF), size: 28),
                    ),
                    const SizedBox(height: 4),
                    const Text('Story', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }
          final story = _stories[i - 1];
          final imgUrl = story['media_url']?.toString() ?? story['img']?.toString() ?? '';
          return Container(
            width: 68, margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF5267FF), Color(0xFFEC4899), Color(0xFFF59E0B)]),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
                      child: imgUrl.isEmpty ? const Icon(Icons.auto_awesome, size: 18) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(story['caption']?.toString() ?? 'Story', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── PRODUCTS GRID ──────────────────────────────

  Widget _buildProductsGrid() {
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF5267FF))),
      );
    }
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Aucun produit', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5267FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68,
        ),
        itemCount: _products.length,
        itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produit';
    final basePrice = (product['base_price'] ?? 0).toDouble();
    final discountPrice = product['discount_price'] != null ? (product['discount_price']).toDouble() : null;
    final currentPrice = discountPrice ?? basePrice;
    final hasDiscount = discountPrice != null && discountPrice < basePrice;
    final images = _extractImages(product);
    final rating = (product['avg_rating'] ?? 4.8).toDouble();
    final reviews = product['reviews_count'] ?? 0;

    final rawVariants = product['variants'];
    List<dynamic> variants = [];
    if (rawVariants is List) {
      variants = rawVariants;
    } else if (rawVariants is String && rawVariants.isNotEmpty) {
      try { variants = json.decode(rawVariants); } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: images.isNotEmpty ? DecorationImage(image: NetworkImage(images[0]), fit: BoxFit.cover) : null,
                  ),
                  child: images.isEmpty ? const Center(child: Icon(Icons.inventory_2_outlined, size: 32, color: Colors.grey)) : null,
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('-${(((basePrice - discountPrice) / basePrice) * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product['category']?.toString().isNotEmpty == true ? product['category'].toString() : (_storeData['name']?.toString() ?? ''), style: TextStyle(fontSize: 11, color: product['category']?.toString().isNotEmpty == true ? const Color(0xFF5267FF) : Colors.grey.shade500, fontWeight: product['category']?.toString().isNotEmpty == true ? FontWeight.w600 : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text('$rating', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text('($reviews)', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
                if (variants.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: variants.take(3).map<Widget>((v) {
                      final vName = v['name']?.toString() ?? '';
                      final extra = (v['price_extra'] ?? v['price_modifier'] ?? 0).toDouble();
                      final label = vName.isNotEmpty ? vName : '?';
                      final extraStr = extra > 0 ? ' +${extra.toInt()}' : extra < 0 ? ' ${extra.toInt()}' : '';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: v['type'] == 'color' ? _parseColorForCard(v['color_hex']?.toString() ?? v['hex']?.toString())?.withValues(alpha: 0.15) : const Color(0xFF5267FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$label$extraStr', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: v['type'] == 'color' ? _parseColorForCard(v['color_hex']?.toString() ?? v['hex']?.toString()) : const Color(0xFF5267FF))),
                      );
                    }).toList()
                      ..addAll(variants.length > 3 ? [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text('+${variants.length - 3}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                        )
                      ] : []),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${currentPrice.toInt()} DA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5267FF))),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _openEditProduct(product),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF22C55E)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _deleteProduct(product['id']?.toString() ?? ''),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseColorForCard(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'), radix: 16)); } catch (_) { return null; }
  }

  // ─── COLLECTIONS SECTION ──────────────────────────────

  Widget _buildCollectionsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.collections_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Aucune collection', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Créez des collections pour organiser vos produits', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── REVIEWS SECTION ──────────────────────────────

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.reviews_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Aucun avis pour le moment', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── ABOUT SECTION ──────────────────────────────

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _aboutRow(Icons.store_rounded, 'Nom', _storeData['name']?.toString() ?? ''),
          _aboutRow(Icons.description_outlined, 'Description', _storeData['description']?.toString() ?? ''),
          _aboutRow(Icons.phone_rounded, 'Téléphone', _storeData['phone']?.toString() ?? ''),
          _aboutRow(Icons.location_on_outlined, 'Adresse', _storeData['address']?.toString() ?? ''),
          _aboutRow(Icons.location_city_rounded, 'Ville', _storeData['city']?.toString() ?? ''),
          _aboutRow(Icons.calendar_today, 'Créé le', _storeData['created_at']?.toString() ?? ''),
        ],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF5267FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF5267FF), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : 'Non renseigné', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
