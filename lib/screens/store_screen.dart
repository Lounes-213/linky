import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/localization/app_localizations.dart';
import '../providers/cart_provider.dart';
import '../core/api/api_service.dart';
import 'product_detail_screen.dart';
import 'store_landing_screen.dart';
import 'promotions_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  List<dynamic> _popularStores = [];
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.get('/api/stores?limit=10'),
        api.get('/api/products?limit=20&sort=popular'),
      ]);

      if (mounted) {
        setState(() {
          _popularStores = results[0].data?['stores'] ?? [];
          _products = results[1].data?['products'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loc = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: LinkyColors.primary)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, style: TextStyle(color: onSurface, fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadData, child: Text(loc.retry)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(context),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            _buildSearchBar(context),
            _buildCategories(context),
            _buildPromoBanner(context),
            _buildSectionHeader(context, loc.popularShops),
            _buildPopularShops(context, loc),
            _buildSectionHeader(context, loc.todayDeals),
            _buildProductGrid(context),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Row(
          children: [
            Neumorphism.button(
              borderRadius: 12,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Store',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            _buildCartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return GestureDetector(
          onTap: () => _showCartSheet(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Neumorphism.circle(
                context: context,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.shopping_cart_outlined, color: Theme.of(context).colorScheme.onSurface, size: 22),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: LinkyColors.primary, shape: BoxShape.circle),
                    child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: LinkyColors.primary),
                        const SizedBox(width: 10),
                        Text('Mon Panier', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: cart.items.isEmpty
                        ? Center(child: Text('Le panier est vide', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: cart.items.length,
                            itemBuilder: (context, index) {
                              final item = cart.items.values.toList()[index];
                              return Neumorphism.light(
                                borderRadius: 16,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                context: context,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60, height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(image: NetworkImage(item.product.imageUrl), fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.product.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text('${item.product.price.toInt()} DA', style: const TextStyle(color: LinkyColors.primary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (item.quantity == 1) {
                                              cart.removeItem(item.product.id);
                                            } else {
                                              cart.removeSingleItem(item.product.id);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                                            child: Icon(Icons.remove, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(item.quantity.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => cart.addItem(item.product),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: LinkyColors.primary, borderRadius: BorderRadius.circular(6)),
                                            child: const Icon(Icons.add, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Neumorphism.light(
          borderRadius: 16,
          context: context,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Chercher un produit...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14)),
                ),
                Icon(Icons.tune, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = [
      {'name': 'Mode', 'icon': Icons.checkroom},
      {'name': 'Beauté', 'icon': Icons.face_retouching_natural},
      {'name': 'Électro', 'icon': Icons.devices},
      {'name': 'Maison', 'icon': Icons.home_work_outlined},
      {'name': 'NFT', 'icon': Icons.token_outlined},
    ];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Neumorphism.light(
                  borderRadius: 18,
                  context: context,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(cat['icon'] as IconData, color: LinkyColors.primary, size: 24),
                  ),
                ),
                const SizedBox(height: 8),
                Text(cat['name'] as String, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PromotionsScreen())),
          child: Neumorphism.light(
            borderRadius: 25,
            context: context,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [LinkyColors.primary.withValues(alpha: 0.8), LinkyColors.primary.withValues(alpha: 0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                    child: const Text('OFFRES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Découvrez les meilleures\noffres du moment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text('Explorer', style: TextStyle(color: LinkyColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Voir tout', style: TextStyle(color: LinkyColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularShops(BuildContext context, AppLocalizations loc) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (_popularStores.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Neumorphism.light(
            borderRadius: 16,
            context: context,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Aucune boutique disponible', style: TextStyle(color: onSurface.withValues(alpha: 0.4)))),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _popularStores.length,
          itemBuilder: (context, index) {
            final shop = _popularStores[index] as Map<String, dynamic>;
            final coverUrl = shop['cover_url']?.toString() ?? '';
            final name = shop['name']?.toString() ?? '';
            final slug = shop['slug']?.toString() ?? '';
            final category = shop['category']?.toString() ?? '';
            final rating = (shop['rating'] ?? 0).toDouble();
            final isVerified = shop['is_verified'] == 1 || shop['badge_verified'] == 1;

            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreLandingScreen(slug: slug))),
              child: Neumorphism.light(
                borderRadius: 20,
                context: context,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            color: coverUrl.isEmpty ? onSurface.withValues(alpha: 0.05) : null,
                            image: coverUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: coverUrl.isEmpty
                              ? Center(child: Icon(Icons.storefront, size: 36, color: onSurface.withValues(alpha: 0.2)))
                              : null,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(name, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(category, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 10)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star, color: LinkyColors.star, size: 12),
                                  const SizedBox(width: 2),
                                  Text(rating.toStringAsFixed(1), style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)),
                                  if (isVerified) ...const [
                                    SizedBox(width: 2),
                                    Icon(Icons.verified, color: LinkyColors.neonGreen, size: 10),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    if (_products.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Neumorphism.light(
              borderRadius: 20,
              context: context,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined, size: 56, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text('Aucun produit disponible', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Les produits ajoutés par les vendeurs\napparaîtront ici.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final p = _products[index] as Map<String, dynamic>;
          final heroTag = 'store_product_${p['id']}';
          final name = p['name']?.toString() ?? '';
          final storeName = p['store_name']?.toString() ?? '';
          final basePrice = p['base_price'];
          final discPrice = p['discount_price'];
          final hasDiscount = discPrice != null && (discPrice is num ? discPrice > 0 : double.tryParse('$discPrice') != null);
          final priceLabel = hasDiscount ? '$discPrice DA' : '${basePrice ?? 0} DA';
          final rating = (p['avg_rating'] ?? 5.0).toDouble();
          final imgUrl = _getFirstImage(p['images']);

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => ProductDetailScreen(productId: p['id']?.toString() ?? '', heroTag: heroTag),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(Tween(begin: const Offset(0, 0.1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
            child: Neumorphism.light(
              borderRadius: 20,
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: heroTag,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
                        ),
                        child: hasDiscount
                            ? Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('PROMO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(storeName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(priceLabel, style: const TextStyle(color: LinkyColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                            Row(
                              children: [
                                const Icon(Icons.star, color: LinkyColors.star, size: 12),
                                Text(rating.toStringAsFixed(1), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
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
    );
  }

  String _getFirstImage(dynamic images) {
    if (images == null) return 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400';
    if (images is List && images.isNotEmpty) return images.first.toString();
    if (images is String && images.isNotEmpty) return images;
    return 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400';
  }
}
