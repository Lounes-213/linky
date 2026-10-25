import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linky/core/api/api_service.dart';
import 'package:linky/core/theme.dart';
import '../core/shared_ui.dart';
import 'product_detail_screen.dart';
import 'store_cart_screen.dart';

class StoreLandingScreen extends StatefulWidget {
  final String slug;
  final Map<String, dynamic>? initialData;

  const StoreLandingScreen({super.key, required this.slug, this.initialData});

  @override
  State<StoreLandingScreen> createState() => _StoreLandingScreenState();
}

class _StoreLandingScreenState extends State<StoreLandingScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _store;
  List<dynamic> _products = [];
  List<dynamic> _stories = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tous';
  String _searchQuery = '';

  // Cart State
  final List<Map<String, dynamic>> _cartItems = [];
  String _promoCode = '';
  double _discountPercent = 0.0;

  // Marquee Pub Announcement State
  String _announcementText = '';
  bool _showBanner = false;

  List<String> _categories = ['Tous'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _store = widget.initialData;
      _products = _store!['products'] ?? [];
      _isLoading = false;
    }
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      final responses = await Future.wait([
        _api.get('/api/stores/${widget.slug}'),
        _api.get('/api/stories'),
      ]);

      if (mounted) {
        setState(() {
          if (responses[0].isSuccess && responses[0].data != null) {
            _store = responses[0].data;
            _products = responses[0].data?['products'] ?? [];

            final settings = _parseJson(_store!['settings']);
            if (settings['announcement'] != null && settings['announcement'].toString().isNotEmpty) {
              _announcementText = settings['announcement'].toString();
              _showBanner = true;
            }
            if (settings['banner_active'] != null) {
              _showBanner = settings['banner_active'] == true;
            }

            final cats = <String>{'Tous'};
            final savedCats = settings['categories'];
            if (savedCats != null && savedCats is List && savedCats.isNotEmpty) {
              for (final c in savedCats) {
                final catName = c is Map ? c['name']?.toString() : null;
                if (catName != null && catName.isNotEmpty) cats.add(catName);
              }
            } else {
              for (final p in _products) {
                final cat = p['category']?.toString();
                if (cat != null && cat.isNotEmpty) cats.add(cat);
              }
            }
            _categories = cats.toList();
          }
          if (responses[1].isSuccess) {
            _stories = responses[1].data?['stories'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _parseJson(dynamic val) {
    if (val == null) return {};
    if (val is Map) return Map<String, dynamic>.from(val);
    if (val is String && val.isNotEmpty) {
      try {
        final decoded = json.decode(val);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  void _addToCart(Map<String, dynamic> product, {String size = '50ml', int quantity = 1}) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item['id'] == product['id'] && item['selected_size'] == size);
      if (index != -1) {
        _cartItems[index]['quantity'] += quantity;
      } else {
        _cartItems.add({
          ...product,
          'selected_size': size,
          'quantity': quantity,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ajouté au panier !', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5267FF),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Voir Panier',
          textColor: Colors.white,
          onPressed: _openCartModal,
        ),
      ),
    );
  }

  double get _cartSubtotal {
    return _cartItems.fold(0.0, (sum, item) {
      final price = (item['discount_price'] ?? item['base_price'] ?? 0).toDouble();
      final qty = (item['quantity'] ?? 1) as int;
      return sum + (price * qty);
    });
  }

  double get _deliveryFee {
    final settings = _parseJson(_store?['settings']);
    if (settings['delivery_free'] == true) return 0;
    return (settings['delivery_fee'] ?? 500).toDouble();
  }

  double get _cartTotal => (_cartSubtotal * (1 - _discountPercent)) + (_cartItems.isEmpty ? 0 : _deliveryFee);

  // ─── MARQUEE PUB BANNER ──────────────────────────────

  Widget _buildMarqueeBanner() {
    if (!_showBanner || _announcementText.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      color: const Color(0xFF5267FF),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                _announcementText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showBanner = false),
            child: const Icon(Icons.close, color: Colors.white70, size: 16),
          ),
        ],
      ),
    );
  }

  // ─── STORE HEADER (COVER + LOGO) ──────────────────────────────

  Widget _buildStoreHeader() {
    final coverUrl = _store?['cover_url']?.toString() ?? '';
    final logoUrl = _store?['logo_url']?.toString() ?? '';
    final storeName = _store?['name']?.toString() ?? 'Boutique';
    final storeDesc = _store?['description']?.toString() ?? '';
    final totalProducts = _store?['total_products'] ?? _products.length;
    final totalFollowers = _store?['total_followers'] ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: clayCard(context),
        border: Border(bottom: BorderSide(color: linkyBorder, width: 0.5)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: LinkyColors.surfaceVariant,
                  image: coverUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: coverUrl.isEmpty
                    ? const Center(child: Icon(Icons.storefront, size: 60, color: Colors.grey))
                    : null,
              ),
              Positioned(
                bottom: -30,
                left: 20,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: logoUrl.isNotEmpty
                        ? Image.network(logoUrl, fit: BoxFit.cover)
                        : Center(
                            child: Text(storeName[0].toUpperCase(), style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700, color: clayPrimary(context), letterSpacing: -0.3,
                            )),
                          ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storeName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: clayText(context), letterSpacing: -0.3)),
                if (storeDesc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(storeDesc, style: TextStyle(fontSize: 13, color: clayTextSecondary(context)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _headerStat(Icons.inventory_2_outlined, '$totalProducts', 'Produits'),
                    const SizedBox(width: 20),
                    _headerStat(Icons.people_outline, '$totalFollowers', 'Abonnés'),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: linkyPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.notifications_outlined, size: 18, color: clayPrimary(context)),
                        onPressed: () {},
                      ),
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

  Widget _headerStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: clayPrimary(context)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: clayText(context))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: clayTextMuted(context))),
      ],
    );
  }

  // ─── STORIES RING BAR ──────────────────────────────

  Widget _buildStoriesBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: clayCard(context),
        border: Border(bottom: BorderSide(color: linkyBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 96,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _stories.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return GestureDetector(
                onTap: _createStory,
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF5267FF), Color(0xFF8B5CF6)]),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFEEF2F8),
                            child: Icon(Icons.add, color: clayPrimary(context), size: 24),
                          ),
                        ),
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
            return GestureDetector(
              onTap: () => _openStoryViewer(story),
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF5267FF), Color(0xFFEC4899), Color(0xFFF59E0B)]),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
                          child: imgUrl.isEmpty ? const Icon(Icons.auto_awesome, size: 20) : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story['caption']?.toString() ?? story['name']?.toString() ?? 'Story',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createStory() async {
    try {
      final picker = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picker == null) return;

      final caption = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Story'),
            content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Légende...'), autofocus: true),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Publier')),
            ],
          );
        },
      );
      if (caption == null) return;

      final fileBytes = await picker.readAsBytes();
      final storeId = _store?['id']?.toString();
      if (storeId == null) return;

      final response = await _api.upload(
        '/api/stories',
        fileBytes,
        picker.name,
      );

      if (response.isSuccess) {
        await _loadStoreData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story publiée !'), backgroundColor: LinkyColors.primary),
          );
        }
      }
    } catch (_) {}
  }

  void _openStoryViewer(Map<String, dynamic> story) {
    final imgUrl = story['media_url']?.toString() ?? story['img']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: imgUrl.isNotEmpty
                  ? Image.network(imgUrl, fit: BoxFit.contain)
                  : const Icon(Icons.image, size: 80, color: Colors.white54),
            ),
            Positioned(
              top: 40, left: 16, right: 16,
              child: Row(
                children: [
                  const CircleAvatar(radius: 18, backgroundColor: Color(0xFF5267FF), child: Icon(Icons.store, color: Colors.white, size: 18)),
                  const SizedBox(width: 10),
                  Text(_store?['name']?.toString() ?? 'Story', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MAIN BUILD ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF5267FF))));
    }

    final filteredProducts = _products.where((p) {
      final nameMatches = p['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? true;
      final categoryMatches = _selectedCategory == 'Tous' || (p['category']?.toString() == _selectedCategory);
      return nameMatches && categoryMatches;
    }).toList();

    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      appBar: ClayAppBar(
        title: _store?['name'] ?? 'Boutique',
        actions: [
          SharedIconButton(
            icon: Icons.search,
            onTap: _openSearchModal,
          ),
          const SizedBox(width: 4),
          Stack(
            children: [
              SharedIconButton(
                icon: Icons.shopping_bag_outlined,
                color: LinkyColors.primary,
                onTap: _openCartModal,
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  top: 2, right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${_cartItems.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildMarqueeBanner(),
                _buildStoreHeader(),
                _buildStoriesBar(),

                // Category Chips Row
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: clayCard(context),
                    border: Border(bottom: BorderSide(color: linkyBorder, width: 0.5)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (ctx, i) {
                        final cat = _categories[i];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? clayPrimary(context) : clayCard(context),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected ? null : Border.all(color: linkyBorder),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isSelected ? Colors.white : clayTextSecondary(context),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Product Grid
                if (filteredProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Aucun produit dans cette catégorie', style: TextStyle(color: Colors.grey))),
                  )
                else
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (ctx, i) => _buildProductCard(Map<String, dynamic>.from(filteredProducts[i])),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Floating Cart Button (bottom-right)
          Positioned(
            bottom: 24,
            right: 20,
            child: GestureDetector(
              onTap: _openCartModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: clayPrimary(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: clayPrimary(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      _cartItems.isEmpty ? 'Panier' : '${_cartItems.fold<int>(0, (s, i) => s + (i['quantity'] as int))}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PRODUCT CARD ──────────────────────────────

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produit';
    final storeName = _store?['name']?.toString() ?? '';
    final basePrice = (product['base_price'] ?? 0).toDouble();
    final discountPrice = product['discount_price'] != null ? (product['discount_price']).toDouble() : null;
    final currentPrice = discountPrice ?? basePrice;
    final hasDiscount = discountPrice != null && discountPrice < basePrice;
    final discountPercent = hasDiscount ? (((basePrice - discountPrice) / basePrice) * 100).round() : 0;
    final rating = (product['avg_rating'] ?? 4.8).toDouble();
    final reviews = product['reviews_count'] ?? 0;
    final deliveryFree = _parseJson(_store?['settings'])['delivery_free'] == true;
    final storeSettings = _parseJson(_store?['settings']);
    final deliveryMode = storeSettings['delivery_mode'] ?? 'fixed';
    final deliveryFee = deliveryFree ? 0.0 : ((storeSettings['delivery_fee'] ?? 500) as num).toDouble();
    final isOutOfStock = product['stock'] != null && (product['stock'] as int) <= 0;

    String? imageUrl;
    try {
      final rawImages = product['images'];
      if (rawImages is List && rawImages.isNotEmpty) imageUrl = rawImages.first.toString();
      if (rawImages is String && rawImages.isNotEmpty) {
        final decoded = json.decode(rawImages);
        if (decoded is List && decoded.isNotEmpty) imageUrl = decoded.first.toString();
      }
    } catch (_) {}

    final heroTag = 'store_landing_product_${product['id']}';

    return GestureDetector(
      onTap: isOutOfStock ? null : () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ProductDetailScreen(
              productId: product['id']?.toString() ?? '',
              heroTag: heroTag,
            ),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) {
              final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Opacity(
        opacity: isOutOfStock ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: clayCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: linkyBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Hero(
                      tag: heroTag,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          color: const Color(0xFFF8F9FC),
                          image: imageUrl != null && imageUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: imageUrl == null || imageUrl.isEmpty
                            ? const Center(child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey))
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: clayCard(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: linkyBorder.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
                      ),
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
                          child: Text('-$discountPercent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                    if (deliveryFree)
                      Positioned(
                        top: hasDiscount ? 30 : 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 10, color: Color(0xFF059669)),
                              SizedBox(width: 3),
                              Text('Gratuite', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    if (isOutOfStock)
                      Positioned(
                        bottom: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Rupture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    if (storeName.isNotEmpty)
                      Text(storeName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${currentPrice.toInt()} DA', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF5267FF), letterSpacing: -0.3)),
                        GestureDetector(
                          onTap: () => _addToCart(product),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5267FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (deliveryFree)
                      const Text('Livraison incluse', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600))
                    else if (deliveryMode == 'wilaya')
                      const Text('+ livraison selon wilaya', style: TextStyle(fontSize: 10, color: Colors.grey))
                    else
                      Text('+ ${deliveryFee.toInt()} DA livraison', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PRODUCT DETAIL MODAL ──────────────────────────────

  void _openProductDetailModal(Map<String, dynamic> product) {
    String selectedSize = '50ml';
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMState) {
          final name = product['name']?.toString() ?? 'Produit';
          final basePrice = (product['base_price'] ?? 0).toDouble();
          final discountPrice = product['discount_price'] != null ? (product['discount_price']).toDouble() : null;
          final currentPrice = discountPrice ?? basePrice;
          final hasDiscount = discountPrice != null && discountPrice < basePrice;
          final discountPercent = hasDiscount ? (((basePrice - discountPrice) / basePrice) * 100).round() : 0;

          return Container(
            height: MediaQuery.sizeOf(context).height * 0.85,
            decoration: BoxDecoration(
              color: clayCard(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: linkyBorder, width: 0.5)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Header
                        Container(
                          height: 280,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                            color: Color(0xFFF8F9FC),
                          ),
                          child: Stack(
                            children: [
                              Center(child: Image.network(product['images']?[0] ?? 'https://images.unsplash.com/photo-1541643600914-78b084683601?w=600', fit: BoxFit.cover)),
                              Positioned(
                                top: 16, right: 16,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: clayCard(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: linkyBorder.withValues(alpha: 0.5)),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.black87, size: 18),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: clayText(context), letterSpacing: -0.3)),
                              const SizedBox(height: 6),
                              Row(
                                children: const [
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  SizedBox(width: 4),
                                  Text('4.9 (310 avis)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Text('${currentPrice.toInt()} DA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: clayPrimary(context), letterSpacing: -0.3)),
                                  const SizedBox(width: 10),
                                  if (hasDiscount) ...[
                                    Text('${basePrice.toInt()} DA', style: const TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: clayPrimary(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text('-$discountPercent%', style: TextStyle(color: clayPrimary(context), fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),

                              Text(product['description']?.toString() ?? 'Un produit de qualité supérieure sélectionné pour vous.', style: TextStyle(color: clayTextSecondary(context), height: 1.4)),
                              const SizedBox(height: 20),

                              // Size selector chips
                              const Text('Taille', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.3)),
                              const SizedBox(height: 10),
                              Row(
                                children: ['30ml', '50ml', '100ml'].map((sz) {
                                  final isSel = selectedSize == sz;
                                  return GestureDetector(
                                    onTap: () => setMState(() => selectedSize = sz),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSel ? clayPrimary(context) : clayCard(context),
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSel ? null : Border.all(color: linkyBorder),
                                      ),
                                      child: Text(sz, style: TextStyle(fontWeight: FontWeight.w700, color: isSel ? Colors.white : Colors.black87)),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),

                              // Quantity Selector
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Quantité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.3)),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: linkyBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => setMState(() { if (quantity > 1) quantity--; })),
                                        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => setMState(() => quantity++)),
                                      ],
                                    ),
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

                // Bottom Add to cart action button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: clayCard(context),
                    border: Border(top: BorderSide(color: linkyBorder, width: 0.5)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clayPrimary(context),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addToCart(product, size: selectedSize, quantity: quantity);
                      },
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Ajouter au panier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── CART MODAL ──────────────────────────────

  void _openCartModal() {
    final promoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMState) {
          return Container(
            height: MediaQuery.sizeOf(context).height * 0.85,
            decoration: BoxDecoration(
              color: clayCard(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: linkyBorder, width: 0.5)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Panier (${_cartItems.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: clayText(context), letterSpacing: -0.3)),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: linkyBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: _cartItems.isEmpty
                      ? Center(child: Text('Votre panier est vide', style: TextStyle(color: clayTextMuted(context))))
                      : ListView.builder(
                          itemCount: _cartItems.length,
                          itemBuilder: (context, i) {
                            final item = _cartItems[i];
                            final price = (item['discount_price'] ?? item['base_price'] ?? 0).toDouble();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: clayCard(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: linkyBorder.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60, height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFF8F9FC),
                                      image: item['images'] != null && item['images'].isNotEmpty
                                          ? DecorationImage(image: NetworkImage(item['images'][0]), fit: BoxFit.cover)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: clayText(context), letterSpacing: -0.3)),
                                        Text('Taille: ${item['selected_size'] ?? 'Standard'}', style: TextStyle(fontSize: 11, color: clayTextMuted(context))),
                                        const SizedBox(height: 4),
                                        Text('${price.toInt()} DA', style: TextStyle(fontWeight: FontWeight.w700, color: clayPrimary(context), letterSpacing: -0.3)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: () => setMState(() {
                                          if (item['quantity'] > 1) {
                                            item['quantity']--;
                                          } else {
                                            _cartItems.removeAt(i);
                                          }
                                        }),
                                      ),
                                      Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: () => setMState(() => item['quantity']++),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                if (_cartItems.isNotEmpty) ...[
                  // Promo Code Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: promoCtrl,
                          decoration: InputDecoration(
                            hintText: 'Code promo (Ex: VIP2026)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: linkyBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: linkyBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: linkyPrimary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: clayPrimary(context),
                        ),
                        onPressed: () {
                          setMState(() {
                            _discountPercent = 0.20;
                            _promoCode = promoCtrl.text.trim();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remise de 20% appliquée !'), backgroundColor: Colors.green));
                        },
                        child: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pricing Summary
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Sous-total', style: TextStyle(color: clayTextMuted(context))),
                    Text('${_cartSubtotal.toInt()} DA', style: TextStyle(fontWeight: FontWeight.w700, color: clayText(context))),
                  ]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Livraison', style: TextStyle(color: clayTextMuted(context))),
                    Text(_deliveryFee == 0 ? 'Gratuite' : '${_deliveryFee.toInt()} DA',
                        style: TextStyle(fontWeight: FontWeight.w700, color: _deliveryFee == 0 ? Colors.green : null)),
                  ]),
                  const Divider(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    Text('${_cartTotal.toInt()} DA', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LinkyColors.primary, letterSpacing: -0.3)),
                  ]),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LinkyColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openCheckoutModal();
                      },
                      child: const Text('Passer la commande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── CHECKOUT MODAL ──────────────────────────────

  void _openCheckoutModal() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StoreCartScreen(
        storeId: _store?['id'] ?? '',
        storeName: _store?['name'] ?? '',
        storeSlug: widget.slug,
        storePhone: _store?['phone'] ?? '',
        cartItems: List<Map<String, dynamic>>.from(_cartItems),
        onOrderPlaced: () {
          setState(() => _cartItems.clear());
        },
      ),
    ));
  }

  void _openSearchModal() {
    showSearch(context: context, delegate: StoreProductSearchDelegate(products: _products, onAddToCart: _addToCart));
  }
}

class StoreProductSearchDelegate extends SearchDelegate {
  final List<dynamic> products;
  final Function(Map<String, dynamic>) onAddToCart;

  StoreProductSearchDelegate({required this.products, required this.onAddToCart});

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final matches = products.where((p) => p['name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? true).toList();
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (ctx, i) {
        final p = matches[i];
        return ListTile(
          title: Text(p['name'] ?? ''),
          subtitle: Text('${p['base_price']} DA'),
          onTap: () {
            close(context, null);
            onAddToCart(Map<String, dynamic>.from(p));
          },
        );
      },
    );
  }
}
