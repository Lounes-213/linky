import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/localization/app_localizations.dart';
import 'product_detail_screen.dart';

class ShopProfileScreen extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ShopProfileScreen({super.key, required this.shop});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  List<String> _categories = [];
  String _selectedCat = 'Tout';
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _fallbackProducts = [
    {'id': 'sp-1', 'name': 'Parfum Rose Royale', 'store_name': 'Glow Beauty', 'base_price': 2800, 'avg_rating': 4.8, 'total_sold': 420, 'images': ['https://images.unsplash.com/photo-1541643600914-78b084683601?w=400']},
    {'id': 'sp-2', 'name': 'Sérum Éclat Vitamine C', 'store_name': 'Glow Beauty', 'base_price': 1950, 'avg_rating': 4.9, 'total_sold': 690, 'images': ['https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400']},
    {'id': 'sp-3', 'name': 'Masque Argile Bio', 'store_name': 'Glow Beauty', 'base_price': 1200, 'avg_rating': 4.7, 'total_sold': 180, 'images': ['https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400']},
    {'id': 'sp-4', 'name': 'Huile Argan Pure', 'store_name': 'Glow Beauty', 'base_price': 3200, 'avg_rating': 4.9, 'total_sold': 310, 'images': ['https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?w=400']},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCat = 'Tout';
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final storeId = widget.shop['id']?.toString();
      final storeSlug = widget.shop['slug']?.toString();
      final params = <String, String>{'limit': '20'};
      if (storeId != null && storeId.isNotEmpty) params['store_id'] = storeId;
      final res = await ApiService().get('/api/products', queryParams: params);
      if (mounted) {
        setState(() {
          final data = res.data;
          if (data != null && data['products'] is List) {
            _products = List<Map<String, dynamic>>.from(data['products'] as List);
          } else if (data != null && data['data'] is List) {
            _products = List<Map<String, dynamic>>.from(data['data'] as List);
          }
          if (_products.isEmpty) _products = List<Map<String, dynamic>>.from(_fallbackProducts);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(_fallbackProducts);
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context);
    final newCategories = [loc.all, loc.newArrivals, loc.promos, loc.bestSellers];
    if (!_categories.contains(loc.all) || newCategories.toString() != _categories.toString()) {
      _categories = newCategories;
      if (!_categories.contains(_selectedCat)) _selectedCat = loc.all;
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0 DA';
    final n = (price as num).toDouble();
    return '${n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} DA';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
      backgroundColor: clayScaffoldBg(context),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: onSurface, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.shop['coverImg'] ?? 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.6), Theme.of(context).scaffoldBackgroundColor],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 70, height: 70,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: LinkyColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: onSurface.withValues(alpha: 0.1), width: 2),
                          ),
                          child: Icon(Icons.store, color: LinkyColors.primary, size: 30),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(widget.shop['name'] ?? '', style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: LinkyColors.neonGreen, size: 16),
                                ],
                              ),
                              Text(widget.shop['cat'] ?? '', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: LinkyColors.neonGreen, borderRadius: BorderRadius.circular(20)),
                          child: Text(loc.follow, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Neumorphism.flat(
                context: context,
                padding: const EdgeInsets.symmetric(vertical: 20),
                borderRadius: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(context, '${_products.length}', loc.orders),
                    _divider(context),
                    _statItem(context, '${widget.shop['rating'] ?? '4.8'}', '⭐ ${loc.reviews}'),
                    _divider(context),
                    _statItem(context, '${widget.shop['followers'] ?? '1.5k'}', loc.followers),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCat == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCat = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? LinkyColors.neonGreen : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isSelected ? Colors.transparent : Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(cat, style: TextStyle(
                          color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        )),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          if (_isLoading)
            const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final p = _products[index];
                  final images = p['images'] is List ? List<String>.from(p['images'] as List) : <String>[];
                  final heroTag = 'shop_product_${p['id'] ?? index}';
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(PageRouteBuilder(
                        pageBuilder: (_, __, _) => ProductDetailScreen(
                          productId: p['id']?.toString() ?? '',
                          heroTag: heroTag,
                        ),
                        transitionsBuilder: (_, animation, __, child) {
                          return SlideTransition(
                            position: Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                                .chain(CurveTween(curve: Curves.easeOutCubic))
                                .animate(animation),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ));
                    },
                    child: Neumorphism.flat(
                      context: context,
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Hero(
                              tag: heroTag,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  image: images.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(images.first), fit: BoxFit.cover)
                                      : null,
                                  color: images.isEmpty ? onSurface.withValues(alpha: 0.05) : null,
                                ),
                                child: images.isEmpty
                                    ? Center(child: Icon(Icons.image_outlined, size: 40, color: onSurface.withValues(alpha: 0.2)))
                                    : null,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'] ?? '', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatPrice(p['base_price'] ?? 0), style: const TextStyle(color: LinkyColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: LinkyColors.neonAmber, size: 12),
                                        Text(
                                          '${p['avg_rating'] ?? 'New'} · ${p['total_sold'] != null ? '${p['total_sold']} ventes' : 'Nouveau'}',
                                          style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 11),
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
                    ),
                  );
                }, childCount: _products.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Text(value, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12)),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1, height: 30,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }
}
