import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/constants/app_constants.dart';
import '../core/catalog/product_taxonomy.dart';
import '../core/localization/app_localizations.dart';

class AddProductScreen extends StatefulWidget {
  final String storeId;
  final Map<String, dynamic>? product;
  final List<Map<String, dynamic>>? existingVariants;
  const AddProductScreen({super.key, required this.storeId, this.product, this.existingVariants});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _tagsController = TextEditingController();
  final _newVariantController = TextEditingController();

  String _selectedCategory = '';
  String _selectedSubCategory = '';
  bool _hasVariants = false;
  bool _isCreating = false;
  List<XFile> _images = [];
  final List<String> _existingImageUrls = [];

  String _descriptionDisplayType = 'text';
  String _descriptionAlignment = 'left';

  final Set<String> _selectedColors = {};
  final Map<String, double> _colorPriceModifiers = {};
  final List<Map<String, dynamic>> _customSizes = [];

  final _api = ApiService();
  final _imagePicker = ImagePicker();

  bool get _isEditing => widget.product != null;

  static const _presetColors = [
    {'name': 'Noir', 'hex': '#000000'},
    {'name': 'Blanc', 'hex': '#FFFFFF'},
    {'name': 'Rouge', 'hex': '#EF4444'},
    {'name': 'Bleu', 'hex': '#3B82F6'},
    {'name': 'Vert', 'hex': '#22C55E'},
    {'name': 'Jaune', 'hex': '#EAB308'},
    {'name': 'Orange', 'hex': '#F97316'},
    {'name': 'Rose', 'hex': '#EC4899'},
    {'name': 'Violet', 'hex': '#8B5CF6'},
    {'name': 'Gris', 'hex': '#6B7280'},
    {'name': 'Marron', 'hex': '#92400E'},
    {'name': 'Beige', 'hex': '#D4A574'},
    {'name': 'Turquoise', 'hex': '#06B6D4'},
    {'name': 'Mauve', 'hex': '#C084FC'},
    {'name': 'Corail', 'hex': '#FB7185'},
  ];

  InputDecoration _neuInputDecoration(String hint, {Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: clayBorder(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: clayBorder(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: clayPrimary(context), width: 1.5),
      ),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  List<ProductSubcategory> get _subcategories => productTaxonomy
      .where((category) => category.id == _selectedCategory)
      .expand((category) => category.subcategories)
      .toList();

  @override
  void initState() {
    super.initState();
    if (_isEditing) _prefillFromProduct();
  }

  void _prefillFromProduct() {
    final p = widget.product!;
    _nameController.text = p['name']?.toString() ?? '';
    _descController.text = p['description']?.toString() ?? '';
    _priceController.text = (p['base_price'] ?? p['price'] ?? '').toString();
    _discountController.text = (p['discount_price'] ?? '').toString();
    _stockController.text = (p['stock'] ?? '1').toString();
    _selectedCategory = p['category_id']?.toString() ?? p['category']?.toString() ?? '';
    _selectedSubCategory = p['subcategory_id']?.toString() ?? '';

    final images = p['images'];
    if (images is List) {
      for (final img in images) {
        final url = img.toString();
        if (url.isNotEmpty) _existingImageUrls.add(url);
      }
    } else if (images is String && images.isNotEmpty) {
      try {
        final decoded = json.decode(images);
        if (decoded is List) {
          for (final img in decoded) {
            final url = img.toString();
            if (url.isNotEmpty) _existingImageUrls.add(url);
          }
        }
      } catch (_) {}
    }

    if (widget.existingVariants != null && widget.existingVariants!.isNotEmpty) {
      _hasVariants = true;
      for (final v in widget.existingVariants!) {
        final type = v['type']?.toString();
        if (type == 'color') {
          final hex = v['color_hex']?.toString() ?? v['hex']?.toString();
          if (hex != null) {
            _selectedColors.add(hex);
            _colorPriceModifiers[hex] = (v['price_extra'] ?? v['price_modifier'] ?? 0).toDouble();
          }
        } else if (type == 'size') {
          _customSizes.add({
            'name': v['name']?.toString() ?? v['size']?.toString() ?? '',
            'price_modifier': (v['price_extra'] ?? v['price_modifier'] ?? 0).toDouble(),
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    _newVariantController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _imagePicker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    setState(() => _images.addAll(files));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  String _buildDescriptionJson() {
    return _descController.text;
  }

  List<Map<String, dynamic>> _buildVariantsPayload() {
    final variants = <Map<String, dynamic>>[];

    for (final hex in _selectedColors) {
      final name = _presetColors.firstWhere((p) => p['hex'] == hex)['name'];
      variants.add({
        'type': 'color',
        'name': name,
        'hex': hex,
        'price_modifier': _colorPriceModifiers[hex] ?? 0,
      });
    }

    for (final size in _customSizes) {
      if (size['name'].toString().trim().isNotEmpty) {
        variants.add({
          'type': 'size',
          'name': size['name'].toString().trim(),
          'price_modifier': size['price_modifier'] ?? 0,
        });
      }
    }

    return variants;
  }

  void _addCustomSize() {
    final name = _newVariantController.text.trim();
    if (name.isEmpty) return;
    if (_customSizes.any((s) => s['name'].toString().toLowerCase() == name.toLowerCase())) return;
    setState(() {
      _customSizes.add({'name': name, 'price_modifier': 0.0});
      _newVariantController.clear();
    });
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (final xfile in _images) {
      try {
        final bytes = await xfile.readAsBytes();
        final filename =
            'product_${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg';

        final response = await _api.upload(
          '/api/upload',
          bytes,
          filename,
          folder: 'products',
        );
        final url = response.data?['url']?.toString();
        if (response.isSuccess && url != null) urls.add(url);
      } catch (_) {}
    }
    return urls;
  }

  Future<void> _submitProduct() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);

    try {
      final newImageUrls = await _uploadImages();
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];

      final body = {
        'store_id': widget.storeId,
        'name': _nameController.text,
        'description': _buildDescriptionJson(),
        'base_price': double.tryParse(_priceController.text) ?? 0,
        'discount_price': double.tryParse(_discountController.text) ?? 0,
        'stock': int.tryParse(_stockController.text) ?? 1,
        'category_id': _selectedCategory,
        'subcategory_id': _selectedSubCategory,
        'tags': _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'has_variants': _selectedColors.isNotEmpty || _customSizes.isNotEmpty,
        'variants': _buildVariantsPayload(),
        'images': allImageUrls,
      };

      final response = _isEditing
          ? await _api.put('/api/products/${widget.product!['id']}', body: body)
          : await _api.post(AppConstants.productsEndpoint, body: body);

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Produit modifié !' : loc.productCreated),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? loc.creationError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le produit' : loc.addProduct),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: clayCard(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: clayBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library, color: clayPrimary(context), size: 24),
                        const SizedBox(width: 12),
                        Text(loc.productPhotos, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._existingImageUrls.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(e.value, width: 120, height: 120, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(width: 120, height: 120, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4, right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeExistingImage(e.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ..._images.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _XFileImage(xfile: e.value, width: 120, height: 120),
                                  ),
                                  Positioned(
                                    top: 4, right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(e.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_existingImageUrls.length + _images.length < 5)
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  color: clayScaffoldBg(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: clayPrimary(context).withValues(alpha: 0.3), width: 2),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: clayPrimary(context), size: 32),
                                    const SizedBox(height: 8),
                                    Text('${_existingImageUrls.length + _images.length}/5', style: TextStyle(color: clayPrimary(context), fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: clayCard(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: clayBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.information, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v!.isEmpty ? loc.nameRequired : null,
                      decoration: _neuInputDecoration(loc.productName, prefixIcon: const Icon(Icons.inventory_2, size: 20)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: _neuInputDecoration(loc.description, prefixIcon: const Icon(Icons.description, size: 20)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory.isEmpty ? null : _selectedCategory,
                      hint: Text(loc.category, style: const TextStyle(color: Colors.grey)),
                      decoration: _neuInputDecoration('', prefixIcon: const Icon(Icons.category, size: 20)),
                      validator: (value) => value == null || value.isEmpty ? loc.selectCategory : null,
                      items: productTaxonomy.map((category) => DropdownMenuItem(value: category.id, child: Text(category.name))).toList(),
                      onChanged: (value) => setState(() { _selectedCategory = value ?? ''; _selectedSubCategory = ''; }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSubCategory.isEmpty ? null : _selectedSubCategory,
                      hint: Text(loc.selectSubcategory, style: const TextStyle(color: Colors.grey)),
                      decoration: _neuInputDecoration('', prefixIcon: const Icon(Icons.account_tree_outlined, size: 20)),
                      validator: (value) => value == null || value.isEmpty ? loc.selectSubcategory : null,
                      items: _subcategories.map((subcategory) => DropdownMenuItem(value: subcategory.id, child: Text(subcategory.name))).toList(),
                      onChanged: _selectedCategory.isEmpty ? null : (value) => setState(() => _selectedSubCategory = value ?? ''),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: clayCard(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: clayBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.priceStock, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? loc.priceRequired : null,
                            decoration: _neuInputDecoration(loc.priceLabel, prefixIcon: const Icon(Icons.attach_money, size: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: _neuInputDecoration(loc.promoPrice, prefixIcon: const Icon(Icons.local_offer, size: 20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: _neuInputDecoration(loc.stockLabel, prefixIcon: const Icon(Icons.inventory, size: 20)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: clayCard(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: clayBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loc.variants, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                        Switch(
                          value: _hasVariants || _selectedColors.isNotEmpty || _customSizes.isNotEmpty,
                          activeThumbColor: clayPrimary(context),
                          onChanged: (v) => setState(() {
                            _hasVariants = v;
                            if (!v) {
                              _selectedColors.clear();
                              _colorPriceModifiers.clear();
                              _customSizes.clear();
                            }
                          }),
                        ),
                      ],
                    ),
                    if (_hasVariants || _selectedColors.isNotEmpty || _customSizes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.palette, color: clayPrimary(context), size: 20),
                          const SizedBox(width: 8),
                          Text(loc.colors, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _presetColors.map((preset) {
                          final isSelected = _selectedColors.contains(preset['hex']);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedColors.remove(preset['hex']);
                                  _colorPriceModifiers.remove(preset['hex']);
                                } else {
                                  _selectedColors.add(preset['hex']!);
                                  _colorPriceModifiers[preset['hex']!] = 0;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _parseColor(preset['hex']),
                                shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? clayPrimary(context) : LinkyColors.border,
                                  width: isSelected ? 3 : 2,
                                ),
                              ),
                              child: preset['hex'] == '#FFFFFF'
                                  ? const Icon(Icons.circle, size: 10, color: Colors.grey)
                                  : isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedColors.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._selectedColors.map((hex) {
                          final name = _presetColors.firstWhere((p) => p['hex'] == hex)['name'] ?? '';
                          final priceMod = _colorPriceModifiers[hex] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(width: 18, height: 18, decoration: BoxDecoration(color: _parseColor(hex), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
                                const SizedBox(width: 8),
                                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                                _buildPriceModifierButton(priceMod, (newVal) {
                                  setState(() => _colorPriceModifiers[hex] = newVal);
                                }),
                              ],
                            ),
                          );
                        }),
                      ],

                      const Divider(height: 32),

                      Row(
                        children: [
                          Icon(Icons.straighten, color: clayPrimary(context), size: 20),
                          const SizedBox(width: 8),
                          Text('Variantes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Ex: 500ml, 1L, Grande, Petite...', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newVariantController,
                              onSubmitted: (_) => _addCustomSize(),
                              decoration: InputDecoration(
                                hintText: 'Nom de la variante',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: linkyPrimary, width: 1.5),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _addCustomSize,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: clayPrimary(context), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      if (_customSizes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._customSizes.asMap().entries.map((e) {
                          final idx = e.key;
                          final size = e.value;
                          final priceMod = (size['price_modifier'] ?? 0).toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.label_outline, size: 18, color: Colors.grey.shade500),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    size['name'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ),
                                _buildPriceModifierButton(priceMod, (newVal) {
                                  setState(() => _customSizes[idx]['price_modifier'] = newVal);
                                }),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _customSizes.removeAt(idx)),
                                  child: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: clayCard(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: clayBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.tags, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagsController,
                      decoration: _neuInputDecoration('tag1, tag2, tag3', prefixIcon: const Icon(Icons.tag, size: 20)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: clayPrimary(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text(
                          _isEditing ? 'Enregistrer les modifications' : loc.createProduct,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceModifierButton(double currentVal, ValueChanged<double> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onChanged(currentVal - 50),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.remove, size: 14, color: Colors.red),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            width: 60,
            child: Text(
              '${currentVal >= 0 ? '+' : ''}${currentVal.toInt()} DA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: currentVal > 0 ? Colors.green : currentVal < 0 ? Colors.red : Colors.grey,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(currentVal + 50),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add, size: 14, color: Colors.green),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF'), radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }
}

class _XFileImage extends StatefulWidget {
  final XFile xfile;
  final double? width;
  final double? height;
  const _XFileImage({required this.xfile, this.width, this.height});

  @override
  State<_XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<_XFileImage> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.xfile.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (_, snap) {
        if (snap.hasData) {
          return Image.memory(snap.data!, width: widget.width, height: widget.height, fit: BoxFit.cover);
        }
        return Container(
          width: widget.width, height: widget.height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
