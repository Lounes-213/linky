import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/localization/app_localizations.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../core/api/api_service.dart';
import 'store_landing_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String heroTag;

  const ProductDetailScreen({super.key, required this.productId, required this.heroTag});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;
  int _selectedColorIndex = -1;
  int _selectedSizeIndex = -1;
  int _selectedOptionIndex = -1;
  int _quantity = 1;
  Map<String, dynamic>? _storeSettings;
  late AnimationController _contentAnimCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade = CurvedAnimation(parent: _contentAnimCtrl, curve: Curves.easeOut);
    _contentSlide = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentAnimCtrl, curve: Curves.easeOutCubic),
    );
    _loadProduct();
  }

  @override
  void dispose() {
    _contentAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final response = await ApiService().get('/api/products/${widget.productId}');
      if (mounted) {
        setState(() {
          _product = response.data;
          _isLoading = false;
        });
        _contentAnimCtrl.forward();
        _loadStoreSettings();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStoreSettings() async {
    final p = _product;
    if (p == null) return;
    final storeSlug = p['store_slug'] ?? '';
    if (storeSlug.isEmpty) return;
    try {
      final res = await ApiService().get('/api/stores/$storeSlug');
      final storeData = res.data;
      if (mounted && storeData != null) {
        final settings = storeData['settings'];
        setState(() {
          _storeSettings = settings is Map<String, dynamic> ? settings : {};
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = const Color(0xFFF8F9FC);
    final txt = isDark ? LinkyColors.neuDarkText : LinkyColors.neuLightText;
    final txtMuted = isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(color: LinkyColors.primary)),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: Text(loc.error)),
        body: Center(child: Text(_error ?? loc.error, style: TextStyle(color: txt))),
      );
    }

    final p = _product!;
    final images = List<String>.from(p['images'] ?? []);
    final variants = List<Map<String, dynamic>>.from(p['variants'] ?? []);
    final reviews = List<Map<String, dynamic>>.from(p['reviews'] ?? []);
    final hasDiscount = p['discount_price'] != null && (p['discount_price'] as num) > 0;
    final basePrice = (p['base_price'] as num).toInt();
    final discountPrice = hasDiscount ? (p['discount_price'] as num).toInt() : null;
    final storeName = p['store_name'] ?? '';
    final storeSlug = p['store_slug'] ?? '';
    final storeId = p['store_id']?.toString() ?? '';
    final rating = (p['avg_rating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = p['total_reviews'] ?? 0;
    final stock = p['stock'] as int?;
    final inStock = stock == null || stock > 0;
    final storeSettings = _storeSettings ?? {};
    final deliveryMode = storeSettings['delivery_mode'] ?? 'fixed';
    final deliveryFree = storeSettings['delivery_free'] == true;
    final deliveryFee = deliveryFree ? 0 : ((storeSettings['delivery_fee'] as num?)?.toInt() ?? 500);
    final deliveryPrices = List<Map<String, dynamic>>.from(storeSettings['delivery_prices'] ?? []);

    final colorVariants = variants.where((v) => v['type'] == 'color').toList();
    final sizeVariants = variants.where((v) => v['type'] == 'size').toList();
    final optionVariants = variants.where((v) => v['type'] == 'option').toList();

    int variantPriceExtra = 0;
    if (_selectedColorIndex >= 0 && _selectedColorIndex < colorVariants.length) {
      variantPriceExtra += (colorVariants[_selectedColorIndex]['price_extra'] as num?)?.toInt() ?? 0;
    }
    if (_selectedSizeIndex >= 0 && _selectedSizeIndex < sizeVariants.length) {
      variantPriceExtra += (sizeVariants[_selectedSizeIndex]['price_extra'] as num?)?.toInt() ?? 0;
    }
    if (_selectedOptionIndex >= 0 && _selectedOptionIndex < optionVariants.length) {
      variantPriceExtra += (optionVariants[_selectedOptionIndex]['price_extra'] as num?)?.toInt() ?? 0;
    }
    final effectiveBase = basePrice + variantPriceExtra;
    final effectivePrice = hasDiscount ? ((discountPrice ?? basePrice) + variantPriceExtra) : effectiveBase;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Hero(
                      tag: widget.heroTag,
                      child: Container(
                        height: 360,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: bg,
                          image: images.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(images.first),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: images.isEmpty
                            ? Center(
                                child: Icon(Icons.image_outlined, size: 80, color: txtMuted.withValues(alpha: 0.3)),
                              )
                            : null,
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 100,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: LinkyColors.discount,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '-${(((basePrice - discountPrice!) / basePrice) * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    if (!inStock)
                      Positioned(
                        top: 100,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Rupture',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            _topBtn(Icons.arrow_back_ios_new, () => Navigator.of(context).pop(), txt),
                            const Spacer(),
                            _topBtn(Icons.share_outlined, () {}, txt),
                            const SizedBox(width: 10),
                            _topBtn(Icons.more_horiz, () {}, txt),
                          ],
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length > 5 ? 5 : images.length,
                            (i) => Container(
                              width: i == 0 ? 20 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: i == 0 ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductInfo(p, storeName, storeSlug, storeId, rating, totalReviews, effectiveBase, hasDiscount ? effectivePrice : null, deliveryMode, deliveryFree, deliveryFee, inStock, loc, txt, txtMuted),
                            if (inStock) ...[
                              const SizedBox(height: 12),
                              _buildOrderSummary(effectivePrice, _quantity, deliveryMode, deliveryFree, deliveryFee, loc, txt, txtMuted),
                            ],
                            const SizedBox(height: 20),
                            if (colorVariants.isNotEmpty) _buildColorSelector(colorVariants, txt, txtMuted),
                            if (colorVariants.isNotEmpty) const SizedBox(height: 20),
                            if (sizeVariants.isNotEmpty) _buildSizeSelector(sizeVariants, txt, txtMuted),
                            if (sizeVariants.isNotEmpty) const SizedBox(height: 20),
                            if (optionVariants.isNotEmpty) _buildOptionSelector(optionVariants, txt, txtMuted),
                            if (optionVariants.isNotEmpty) const SizedBox(height: 20),
                            _buildDescription(p, loc, txt, txtMuted),
                            const SizedBox(height: 20),
                            if (reviews.isNotEmpty) _buildReviews(reviews, loc, txt, txtMuted),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: inStock ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                          child: Icon(Icons.remove, color: txtMuted, size: 20),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_quantity',
                            style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _quantity++),
                          child: const Icon(Icons.add, color: LinkyColors.primary, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _addToCart(p, storeName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: LinkyColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              loc.addToCart,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ) : Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Produit indisponible',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(Map<String, dynamic> p, String storeName, String storeSlug,
      String storeId, double rating, int totalReviews, int basePrice, int? discountPrice,
      String deliveryMode, bool deliveryFree, int deliveryFee, bool inStock,
      AppLocalizations loc, Color txt, Color txtMuted) {
    final hasDiscount = discountPrice != null;
    final displayPrice = hasDiscount ? discountPrice : basePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
              p['name'] ?? '',
              style: TextStyle(color: txt, fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3),
              ),
            ),
            if (hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: LinkyColors.discount.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${(((basePrice - displayPrice) / basePrice) * 100).round()}%',
                  style: const TextStyle(color: LinkyColors.discount, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '$displayPrice DA',
              style: const TextStyle(color: LinkyColors.primary, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 12),
              Text(
                '$basePrice DA',
                style: TextStyle(
                  color: txtMuted,
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ...List.generate(5, (i) => Icon(
                  i < rating.round() ? Icons.star : Icons.star_border,
                  color: LinkyColors.star,
                  size: 18,
                )),
            const SizedBox(width: 6),
            Text('${rating > 0 ? rating.toStringAsFixed(1) : '—'}', style: TextStyle(color: txt, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 4),
            Text('($totalReviews ${loc.reviews})', style: TextStyle(color: txtMuted, fontSize: 12)),
            const Spacer(),
            if (storeName.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreLandingScreen(slug: storeSlug),
                  ),
                ),
                child: Row(
                  children: [
                    Text(storeName, style: TextStyle(color: txtMuted, fontSize: 13)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: txtMuted),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (deliveryFree)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF059669)),
                SizedBox(width: 6),
                Text('Livraison gratuite', style: TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
              ],
            ),
          )
        else
          Row(
            children: [
              _infoPill(Icons.local_shipping_outlined, deliveryMode == 'wilaya' ? 'Selon wilaya' : 'Livraison ${deliveryFee}DA'),
            ],
          ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LinkyColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LinkyColors.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: LinkyColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(int unitPrice, int quantity, String deliveryMode, bool deliveryFree, int deliveryFee, AppLocalizations loc, Color txt, Color txtMuted) {
    final subtotal = unitPrice * quantity;
    final deliveryCost = deliveryFree ? 0 : deliveryFee;
    final total = subtotal + deliveryCost;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow('Sous-total ($quantity article${quantity > 1 ? 's' : ''})', '$subtotal DA', txt, txtMuted),
          const SizedBox(height: 6),
          _summaryRow('Livraison', deliveryFree ? 'Gratuite' : '$deliveryCost DA', txt, txtMuted, valueColor: deliveryFree ? const Color(0xFF059669) : null, valueWeight: deliveryFree ? FontWeight.w700 : null),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFD1D9E6)),
          ),
          _summaryRow('Total', '$total DA', txt, txtMuted, isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color txt, Color txtMuted, {Color? valueColor, FontWeight? valueWeight, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: txt,
          fontSize: isTotal ? 16 : 13,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
        )),
        Text(value, style: TextStyle(
          color: valueColor ?? (isTotal ? LinkyColors.primary : txt),
          fontSize: isTotal ? 18 : 13,
          fontWeight: valueWeight ?? (isTotal ? FontWeight.w800 : FontWeight.w700),
        )),
      ],
    );
  }

  Widget _buildColorSelector(List<dynamic> variants, Color txt, Color txtMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Couleur', style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List.generate(variants.length, (i) {
            final v = variants[i];
            final isSelected = _selectedColorIndex == i;
            final hex = v['color_hex']?.toString() ?? v['hex']?.toString() ?? '';
            final colorValue = hex.isNotEmpty
                ? (int.tryParse(hex.replaceFirst('#', '0xFF'), radix: 16) ?? 0xFF9E9E9E)
                : 0xFF9E9E9E;
            final name = v['name']?.toString() ?? '';
            final priceExtra = (v['price_extra'] as num?)?.toInt() ?? 0;
            return GestureDetector(
              onTap: () => setState(() => _selectedColorIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(colorValue).withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Color(colorValue) : txtMuted.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: txtMuted.withValues(alpha: 0.3), width: 1.5),
                      ),
                    ),
                    if (name.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(name, style: TextStyle(
                        color: isSelected ? Color(colorValue) : txt,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      )),
                    ],
                    if (priceExtra != 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        priceExtra > 0 ? '+${priceExtra}DA' : '${priceExtra}DA',
                        style: TextStyle(
                          color: priceExtra > 0 ? LinkyColors.primary : Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSizeSelector(List<dynamic> variants, Color txt, Color txtMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taille', style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List.generate(variants.length, (i) {
            final v = variants[i];
            final name = v['name'] as String? ?? v['size'] as String? ?? '';
            final isSelected = _selectedSizeIndex == i;
            final priceExtra = (v['price_extra'] as num?)?.toInt() ?? 0;
            return GestureDetector(
              onTap: () => setState(() => _selectedSizeIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? LinkyColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? LinkyColors.primary : txtMuted.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : txt,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    if (priceExtra != 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        priceExtra > 0 ? '+${priceExtra}DA' : '${priceExtra}DA',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : (priceExtra > 0 ? LinkyColors.primary : Colors.green),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOptionSelector(List<dynamic> variants, Color txt, Color txtMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Option', style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List.generate(variants.length, (i) {
            final v = variants[i];
            final name = v['name']?.toString() ?? '';
            final priceExtra = v['price_extra'] != null ? (v['price_extra'] as num).toInt() : 0;
            final isSelected = _selectedOptionIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedOptionIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? LinkyColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? LinkyColors.primary : txtMuted.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: TextStyle(
                      color: isSelected ? Colors.white : txt,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    )),
                    if (priceExtra != 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        priceExtra > 0 ? '+$priceExtra DA' : '$priceExtra DA',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : (priceExtra > 0 ? LinkyColors.primary : Colors.green),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDescription(Map<String, dynamic> p, AppLocalizations loc, Color txt, Color txtMuted) {
    String desc = '';
    if (p['description'] is String && p['description'].isNotEmpty) {
      try {
        final parsed = Map<String, dynamic>.from(p['description']);
        desc = parsed['text']?.toString() ?? p['description'].toString();
      } catch (_) {
        desc = p['description'].toString();
      }
    }
    if (desc.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.description, style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 10),
        Text(desc, style: TextStyle(color: txtMuted, fontSize: 14, height: 1.5)),
      ],
    );
  }

  Widget _buildReviews(List<dynamic> reviews, AppLocalizations loc, Color txt, Color txtMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(loc.reviews, style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(loc.seeAll, style: const TextStyle(color: LinkyColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...reviews.take(3).map((r) => _buildReviewItem(r, loc, txt, txtMuted)),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> r, AppLocalizations loc, Color txt, Color txtMuted) {
    final rating = (r['rating'] as num?)?.toInt() ?? 5;
    final userName = r['user_name'] ?? 'Utilisateur';
    final userAvatar = r['user_avatar'] as String? ?? '';
    final comment = r['comment']?.toString() ?? '';
    final createdAt = r['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
                ),
                child: userAvatar.isNotEmpty
                    ? ClipOval(child: Image.network(userAvatar, width: 36, height: 36, fit: BoxFit.cover))
                    : Center(child: Text(userName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: LinkyColors.star,
                        size: 12,
                      )),
                    ),
                  ],
                ),
              ),
              if (createdAt.isNotEmpty)
                Text(_formatDate(createdAt), style: TextStyle(color: txtMuted, fontSize: 11)),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: TextStyle(color: txtMuted, fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 30) return '${diff.inDays ~/ 30} mois';
      if (diff.inDays > 0) return '${diff.inDays} j';
      if (diff.inHours > 0) return '${diff.inHours} h';
      return '${diff.inMinutes} min';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _topBtn(IconData icon, VoidCallback onTap, Color txt) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: txt, size: 20),
      ),
    );
  }

  String _getSelectedVariantInfo(Map<String, dynamic> p) {
    final variants = List<Map<String, dynamic>>.from(p['variants'] ?? []);
    final colorVariants = variants.where((v) => v['type'] == 'color').toList();
    final sizeVariants = variants.where((v) => v['type'] == 'size').toList();
    final optionVariants = variants.where((v) => v['type'] == 'option').toList();

    final parts = <String>[];
    if (_selectedColorIndex >= 0 && _selectedColorIndex < colorVariants.length) {
      parts.add(colorVariants[_selectedColorIndex]['name']?.toString() ?? '');
    }
    if (_selectedSizeIndex >= 0 && _selectedSizeIndex < sizeVariants.length) {
      parts.add(sizeVariants[_selectedSizeIndex]['name']?.toString() ?? sizeVariants[_selectedSizeIndex]['size']?.toString() ?? '');
    }
    if (_selectedOptionIndex >= 0 && _selectedOptionIndex < optionVariants.length) {
      parts.add(optionVariants[_selectedOptionIndex]['name']?.toString() ?? '');
    }
    return parts.where((s) => s.isNotEmpty).join(', ');
  }

  Future<void> _addToCart(Map<String, dynamic> p, String storeName) async {
    final cart = context.read<CartProvider>();
    final loc = AppLocalizations.of(context);
    final variantInfo = _getSelectedVariantInfo(p);
    final variants = List<Map<String, dynamic>>.from(p['variants'] ?? []);
    final colorVariants = variants.where((v) => v['type'] == 'color').toList();
    final sizeVariants = variants.where((v) => v['type'] == 'size').toList();
    final optionVariants = variants.where((v) => v['type'] == 'option').toList();
    int variantPriceExtra = 0;
    if (_selectedColorIndex >= 0 && _selectedColorIndex < colorVariants.length) {
      variantPriceExtra += (colorVariants[_selectedColorIndex]['price_extra'] as num?)?.toInt() ?? 0;
    }
    if (_selectedSizeIndex >= 0 && _selectedSizeIndex < sizeVariants.length) {
      variantPriceExtra += (sizeVariants[_selectedSizeIndex]['price_extra'] as num?)?.toInt() ?? 0;
    }
    if (_selectedOptionIndex >= 0 && _selectedOptionIndex < optionVariants.length) {
      variantPriceExtra += (optionVariants[_selectedOptionIndex]['price_extra'] as num?)?.toInt() ?? 0;
    }
    final basePrice = (p['base_price'] ?? 0).toDouble() + variantPriceExtra;
    final finalPrice = (p['discount_price'] != null && (p['discount_price'] as num) > 0)
        ? (p['discount_price'] as num).toDouble() + variantPriceExtra
        : basePrice;
    final product = Product(
      id: p['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: p['name'] ?? '',
      description: variantInfo,
      price: finalPrice,
      imageUrl: (p['images'] as List? ?? []).isNotEmpty ? (p['images'] as List).first : '',
      shopName: storeName,
    );
    for (int i = 0; i < _quantity; i++) {
      cart.addItem(product);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p['name']}${variantInfo.isNotEmpty ? ' ($variantInfo)' : ''} — ${loc.addToCart} (x$_quantity)'),
          backgroundColor: LinkyColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: loc.seeAll,
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }
}
