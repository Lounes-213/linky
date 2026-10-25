import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/api_service.dart';
import '../core/catalog/product_taxonomy.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/localization/app_localizations.dart';

class AliExpressImportScreen extends StatefulWidget {
  const AliExpressImportScreen({super.key, required this.storeId});
  final String storeId;

  @override
  State<AliExpressImportScreen> createState() => _AliExpressImportScreenState();
}

class _AliExpressImportScreenState extends State<AliExpressImportScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _urlController = TextEditingController();
  final _priceController = TextEditingController();
  final _marginController = TextEditingController(text: '30');
  final _pageController = PageController();
  final _focusNode = FocusNode();

  Map<String, dynamic>? _preview;
  bool _loading = false;
  bool _publishing = false;
  String? _categoryId;
  String? _subcategoryId;
  final Set<int> _selectedVariants = {};
  int _currentImageIndex = 0;
  bool _showAllImages = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _priceController.dispose();
    _marginController.dispose();
    _pageController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _extractProductId(String url) {
    final match = RegExp(r'/item/(\d+)').firstMatch(url);
    return match?.group(1) ?? '';
  }

  String _cleanSourcePrice() {
    final raw = _preview?['source_price'];
    if (raw == null) return '';
    if (raw is num) return raw.toInt().toString();
    return raw.toString();
  }

  double _parseDouble(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  void _recalcSellingPrice() {
    final source = _parseDouble(_cleanSourcePrice());
    final margin = _parseDouble(_marginController.text);
    if (source > 0) {
      final da = source * (1 + margin / 100);
      _priceController.text = da.toInt().toString();
    }
  }

  Future<void> _previewProduct() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final productId = _extractProductId(url);
    if (productId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien invalide. Collez un lien AliExpress produit.'),
          backgroundColor: LinkyColors.discount,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final response = await _api.post(
      '/api/imports/aliexpress/preview',
      body: {'url': url},
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _preview = response.isSuccess ? response.data : null;
    });

    if (response.isSuccess) {
      _recalcSellingPrice();
      _animController.forward(from: 0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Import impossible'),
          backgroundColor: LinkyColors.discount,
        ),
      );
    }
  }

  Future<void> _publish() async {
    if (_preview == null) return;
    if (_categoryId == null || _subcategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez une catégorie et une sous-catégorie'),
          backgroundColor: LinkyColors.star,
        ),
      );
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Définissez un prix de vente'),
          backgroundColor: LinkyColors.star,
        ),
      );
      return;
    }

    final prices = List<dynamic>.from(
      (_preview?['variants'] as Map?)?['prices'] ?? const [],
    );
    final options = List<dynamic>.from(
      (_preview?['variants'] as Map?)?['options'] ?? const [],
    );

    final selected = _selectedVariants.map((i) {
      final item = Map<String, dynamic>.from(prices[i]);
      final parts = <String>[];
      final propIds = (item['optionValueIds'] ?? '').toString().split(';');
      for (final propId in propIds) {
        final kv = propId.split(':');
        if (kv.length == 2) {
          final optId = kv[0];
          final valId = kv[1];
          for (final opt in options) {
            final optMap = Map<String, dynamic>.from(opt);
            if (optMap['id'].toString() == optId) {
              for (final val in (optMap['values'] as List? ?? [])) {
                final valMap = Map<String, dynamic>.from(val);
                if (valMap['id'].toString() == valId) {
                  parts.add('${optMap['name']}: ${valMap['displayName'] ?? valMap['name']}');
                }
              }
            }
          }
        }
      }
      return {
        'name': parts.isNotEmpty ? parts.join(' / ') : 'SKU ${item['skuId']}',
        'sku': '${item['skuId']}',
        'stock': item['availableQuantity'],
        'price': _priceController.text.trim(),
      };
    }).toList();

    setState(() => _publishing = true);
    final response = await _api.post(
      '/api/imports/aliexpress/publish',
      body: {
        'store_id': widget.storeId,
        'title': _preview!['title'],
        'description': _preview!['description'],
        'images': _preview!['images'],
        'category_id': _categoryId,
        'subcategory_id': _subcategoryId,
        'selling_price': _priceController.text.trim(),
        'stock': 0,
        'selected_variants': selected,
      },
    );
    if (!mounted) return;
    setState(() => _publishing = false);
    if (response.isSuccess) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit importé avec succès !'),
          backgroundColor: LinkyColors.neonGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Publication impossible'),
          backgroundColor: LinkyColors.discount,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final prices = List<dynamic>.from(
      (_preview?['variants'] as Map?)?['prices'] ?? const [],
    );
    final options = List<dynamic>.from(
      (_preview?['variants'] as Map?)?['options'] ?? const [],
    );
    final images = List<String>.from(_preview?['images'] ?? const []);
    final sourcePrice = _parseDouble(_cleanSourcePrice());
    final sellingPrice = _parseDouble(_priceController.text);
    final margin = _parseDouble(_marginController.text);
    final profit = sourcePrice > 0 ? sellingPrice - sourcePrice : 0.0;

    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(loc),
            Expanded(
              child: _preview == null && !_loading
                  ? _buildUrlInput(loc)
                  : _loading
                      ? _buildLoadingState()
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildPreview(loc, images, prices, options, sourcePrice, margin, profit),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Neumorphism.circle(
              context: context,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            loc.importAliExpress,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_preview != null)
            GestureDetector(
              onTap: () => setState(() {
                _preview = null;
                _selectedVariants.clear();
                _currentImageIndex = 0;
                _animController.reset();
              }),
              child: Neumorphism.circle(
                context: context,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.refresh,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrlInput(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Neumorphism.light(
            context: context,
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LinkyColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: LinkyColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.importFromAliExpress,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.importSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Neumorphism.light(
                  context: context,
                  borderRadius: 14,
                  child: TextField(
                    controller: _urlController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.url,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'https://www.aliexpress.com/item/100500...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      prefixIcon: const Icon(Icons.link, color: LinkyColors.primary),
                      suffixIcon: _urlController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _urlController.clear();
                                setState(() {});
                              },
                              child: const Icon(Icons.close, color: LinkyColors.textTertiary),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _previewProduct(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Neumorphism.button(
                    borderRadius: 14,
                    child: GestureDetector(
                      onTap: _loading ? null : _previewProduct,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.download_for_offline_outlined, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    loc.importAndPreview,
                                    style: const TextStyle(
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
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Neumorphism.circle(
              context: context,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: LinkyColors.primary, strokeWidth: 2.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Récupération du produit...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyse de la page AliExpress',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(
    AppLocalizations loc,
    List<String> images,
    List<dynamic> prices,
    List<dynamic> options,
    double sourcePrice,
    double margin,
    double profit,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildImageCarousel(images),
        const SizedBox(height: 16),
        _buildProductInfo(),
        const SizedBox(height: 20),
        _buildCategoryPicker(loc),
        const SizedBox(height: 20),
        _buildPriceSection(sourcePrice, margin, profit),
        if (prices.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildVariantsSection(prices, options),
        ],
        const SizedBox(height: 24),
        _buildPublishButton(loc),
      ],
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Neumorphism.light(
            context: context,
            borderRadius: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, e) => Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: const Icon(Icons.broken_image, size: 40),
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
                          images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentImageIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentImageIndex
                                  ? LinkyColors.primary
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (images.length > 6) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showAllImages = !_showAllImages),
            child: Text(
              _showAllImages ? 'Voir moins' : 'Voir toutes les images (${images.length})',
              style: const TextStyle(color: LinkyColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        if (!_showAllImages && images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: i == _currentImageIndex ? LinkyColors.primary : Colors.transparent,
                      width: 2,
                    ),
                    image: DecorationImage(image: NetworkImage(images[i]), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductInfo() {
    final title = _preview?['title']?.toString() ?? '';
    final rating = _preview?['rating']?.toString() ?? '0';
    final orders = _preview?['orders']?.toString() ?? '0';
    final sourcePrice = _cleanSourcePrice();
    final sourceCurrency = _preview?['source_currency']?.toString() ?? '';

    return Neumorphism.light(
      context: context,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.star_rounded, rating, LinkyColors.star),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.shopping_bag_outlined, '$orders cmd', LinkyColors.primary),
              if (sourcePrice.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildInfoChip(Icons.attach_money, '$sourcePrice $sourceCurrency', LinkyColors.accent),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker(AppLocalizations loc) {
    final categories = productTaxonomy;
    final subcategories = categories
        .where((c) => c.id == _categoryId)
        .expand((c) => c.subcategories)
        .toList();

    return Neumorphism.light(
      context: context,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, color: LinkyColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                loc.category,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Neumorphism.light(
            context: context,
            borderRadius: 12,
            child: DropdownButtonFormField<String>(
              initialValue: _categoryId,
              hint: Text(loc.selectCategory),
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() {
                _categoryId = v;
                _subcategoryId = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          Neumorphism.light(
            context: context,
            borderRadius: 12,
            child: DropdownButtonFormField<String>(
              initialValue: _subcategoryId,
              hint: Text(loc.selectSubcategory),
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: subcategories
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: _categoryId == null
                  ? null
                  : (v) => setState(() => _subcategoryId = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double sourcePrice, double margin, double profit) {
    return Neumorphism.light(
      context: context,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sell_outlined, color: LinkyColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Prix & Marge',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sourcePrice > 0) ...[
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Prix source : ${sourcePrice.toInt()} DA',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marge (%)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Neumorphism.light(
                      context: context,
                      borderRadius: 10,
                      child: TextField(
                        controller: _marginController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          suffixText: '%',
                          suffixStyle: const TextStyle(color: LinkyColors.primary, fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => _recalcSellingPrice(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prix de vente (DA)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Neumorphism.light(
                      context: context,
                      borderRadius: 10,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: LinkyColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          suffixText: 'DA',
                          suffixStyle: TextStyle(
                            color: LinkyColors.primary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sourcePrice > 0 && profit != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (profit > 0 ? LinkyColors.neonGreen : LinkyColors.discount).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    profit > 0 ? Icons.trending_up : Icons.trending_down,
                    color: profit > 0 ? LinkyColors.neonGreen : LinkyColors.discount,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bénéfice : ${profit > 0 ? '+' : ''}${profit.toInt()} DA par unité',
                    style: TextStyle(
                      color: profit > 0 ? LinkyColors.neonGreen : LinkyColors.discount,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantsSection(List<dynamic> prices, List<dynamic> options) {
    return Neumorphism.light(
      context: context,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style_outlined, color: LinkyColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Variantes (${prices.length})',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (prices.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedVariants.length == prices.length) {
                        _selectedVariants.clear();
                      } else {
                        _selectedVariants.addAll(List.generate(prices.length, (i) => i));
                      }
                    });
                  },
                  child: Text(
                    _selectedVariants.length == prices.length ? 'Tout désélectionner' : 'Tout sélectionner',
                    style: const TextStyle(color: LinkyColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(prices.length, (i) {
            final sku = Map<String, dynamic>.from(prices[i]);
            final isSelected = _selectedVariants.contains(i);
            final propIds = (sku['optionValueIds'] ?? '').toString().split(';');
            final labels = <String>[];
            for (final propId in propIds) {
              final kv = propId.split(':');
              if (kv.length == 2) {
                for (final opt in options) {
                  final optMap = Map<String, dynamic>.from(opt);
                  if (optMap['id'].toString() == kv[0]) {
                    for (final val in (optMap['values'] as List? ?? [])) {
                      final valMap = Map<String, dynamic>.from(val);
                      if (valMap['id'].toString() == kv[1]) {
                        labels.add(valMap['displayName'] ?? valMap['name'] ?? '');
                      }
                    }
                  }
                }
              }
            }
            final displayName = labels.isNotEmpty ? labels.join(' / ') : 'SKU ${sku['skuId']}';
            final stock = sku['availableQuantity'] ?? 0;
            final salePrice = sku['salePrice'];
            final variantPrice = salePrice is Map ? (salePrice['value'] ?? 0) : 0;

            return GestureDetector(
              onTap: () => setState(() {
                isSelected ? _selectedVariants.remove(i) : _selectedVariants.add(i);
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? LinkyColors.primary.withValues(alpha: 0.08)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? LinkyColors.primary : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? LinkyColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? LinkyColors.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stock source : $stock',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (variantPrice is num && variantPrice > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: LinkyColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${variantPrice.toInt()} DA',
                          style: const TextStyle(
                            color: LinkyColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPublishButton(AppLocalizations loc) {
    final hasVariantPrices = (_preview?['variants'] as Map?)?['prices'] != null;
    return SizedBox(
      width: double.infinity,
      child: Neumorphism.button(
        borderRadius: 16,
        child: GestureDetector(
          onTap: _publishing ? null : _publish,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            alignment: Alignment.center,
            child: _publishing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.publish_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        hasVariantPrices ? 'Publier dans ma boutique' : loc.publish,
                        style: const TextStyle(
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
}
