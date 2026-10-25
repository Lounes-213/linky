import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/localization/app_localizations.dart';
import 'product_detail_screen.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _fallbackProducts = [
    {'id': 'promo-1', 'name': 'Casque audio Pro', 'store_name': 'TechZone', 'base_price': 8900, 'discount_price': 4450, 'avg_rating': 4.6, 'images': ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400']},
    {'id': 'promo-2', 'name': 'Montre connectée V2', 'store_name': 'SmartLife', 'base_price': 6200, 'discount_price': 3100, 'avg_rating': 4.7, 'images': ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400']},
    {'id': 'promo-3', 'name': 'Baskets Air Max', 'store_name': 'SportAddict', 'base_price': 12500, 'discount_price': 6250, 'avg_rating': 4.9, 'images': ['https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400']},
    {'id': 'promo-4', 'name': 'Sac à dos Nomad', 'store_name': 'Aventure', 'base_price': 4800, 'discount_price': 2400, 'avg_rating': 4.5, 'images': ['https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400']},
  ];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final res = await ApiService().get('/api/products', queryParams: {'discounted': 'true', 'limit': '20'});
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
      appBar: ClayAppBar(
        title: loc.promos,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: clayPrimary(context)))
          : _buildContent(context, loc, onSurface),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations loc, Color onSurface) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: LinkyColors.neonGreen.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, color: LinkyColors.neonGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                '${loc.promos} — lienki.dz/linky',
                style: const TextStyle(color: LinkyColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? Center(child: Text(loc.noPromos, style: TextStyle(color: onSurface.withValues(alpha: 0.5))))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    final images = p['images'] is List ? List<String>.from(p['images'] as List) : <String>[];
                    final basePrice = (p['base_price'] as num?)?.toDouble() ?? 0;
                    final discPrice = (p['discount_price'] as num?)?.toDouble();
                    final hasDiscount = discPrice != null && discPrice > 0;
                    final pct = hasDiscount && basePrice > 0 ? ((basePrice - discPrice) / basePrice * 100).round() : 50;
                    final heroTag = 'promo_product_${index}';
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: onSurface.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: LinkyColors.neonGreen.withValues(alpha: 0.2)),
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
                                  if (hasDiscount)
                                    Positioned(
                                      top: 10, left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: LinkyColors.neonGreen, borderRadius: BorderRadius.circular(8)),
                                        child: Text('-$pct%', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['name'] ?? '', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Row(
                                    children: [
                                      Icon(Icons.storefront, color: onSurface.withValues(alpha: 0.38), size: 12),
                                      const SizedBox(width: 4),
                                      Text(p['store_name'] ?? '', style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_formatPrice(discPrice ?? basePrice), style: const TextStyle(color: LinkyColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (hasDiscount) ...[
                                        const SizedBox(width: 6),
                                        Text(_formatPrice(basePrice), style: TextStyle(color: onSurface.withValues(alpha: 0.24), fontSize: 11, decoration: TextDecoration.lineThrough)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
