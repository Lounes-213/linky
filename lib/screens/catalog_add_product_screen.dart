import 'package:flutter/material.dart';
import 'package:linky/core/api/api_service.dart';
import '../core/widgets/neumorphic_ui.dart';
import '../core/shared_ui.dart';
import 'add_product_screen.dart' as linky_add;

class CatalogAddProductScreen extends StatefulWidget {
  final String storeId;
  final VoidCallback onProductAdded;

  const CatalogAddProductScreen({
    super.key,
    required this.storeId,
    required this.onProductAdded,
  });

  @override
  State<CatalogAddProductScreen> createState() => _CatalogAddProductScreenState();
}

class _CatalogAddProductScreenState extends State<CatalogAddProductScreen> {
  final ApiService _api = ApiService();
  bool _isCatalogTab = true;
  String _selectedCategory = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Tous',
    'Électronique',
    'Mode',
    'Maison',
    'Beauté',
    'Sport',
    'Automobile',
    'Autres'
  ];

  bool _isLoading = false;
  List<Map<String, dynamic>> _catalogProducts = [];

  @override
  void initState() {
    super.initState();
    _loadCatalogProducts();
  }

  Future<void> _loadCatalogProducts() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/products');
      if (mounted && res.isSuccess && res.data != null) {
        final list = (res.data!['products'] as List? ?? []);
        setState(() {
          _catalogProducts = list.map((p) => {
            'id': p['id'],
            'title': p['name'] ?? '',
            'brand': p['brand'] ?? p['store_name'] ?? 'Boutique',
            'rating': (p['avg_rating'] as num?)?.toDouble() ?? 5.0,
            'reviews': (p['total_reviews'] as num?)?.toInt() ?? 0,
            'price': (p['base_price'] as num?)?.toDouble() ?? 0.0,
            'image_url': (p['images'] is List && (p['images'] as List).isNotEmpty)
                ? p['images'][0]
                : (p['image_url'] ?? 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400'),
            'category': p['category_id'] ?? 'Autres',
          }).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAddProduct(Map<String, dynamic> product) async {
    try {
      final body = {
        'store_id': widget.storeId,
        'title': product['title'],
        'description': 'Description du catalogue pour ${product['title']}',
        'price': product['price'],
        'images': [product['image_url']],
        'status': 'active',
      };
      
      final res = await _api.post('/api/stores/${widget.storeId}/products', body: body);
      
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['title']} ajouté avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
        widget.onProductAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Erreur lors de l\'ajout'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredProducts = _catalogProducts.where((p) {
      if (_selectedCategory != 'Tous' && p['category'] != _selectedCategory) return false;
      if (_searchController.text.isNotEmpty) {
        return p['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3), // Neumorphic background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0F3),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NeumorphicButton(
            padding: EdgeInsets.zero,
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          ),
        ),
        title: const Text(
          'Ajouter un produit',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Neumorphic Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: NeumorphicContainer(
              padding: const EdgeInsets.all(4),
              borderRadius: 30,
              depth: 3,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCatalogTab = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isCatalogTab ? Colors.white.withValues(alpha: 0.8) : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: _isCatalogTab ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                        ),
                        child: Text(
                          'Depuis le catalogue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isCatalogTab ? const Color(0xFF0066FF) : Colors.grey.shade600,
                            fontWeight: _isCatalogTab ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => linky_add.AddProductScreen(storeId: widget.storeId),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isCatalogTab ? Colors.white.withValues(alpha: 0.8) : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: !_isCatalogTab ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                        ),
                        child: Text(
                          'Manuellement',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isCatalogTab ? const Color(0xFF0066FF) : Colors.grey.shade600,
                            fontWeight: !_isCatalogTab ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isCatalogTab) ...[
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 16,
                      depth: 2,
                      // isInnerShadow: true, // Should ideally be inner shadow for textfields in neumorphism, but flat is ok
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit...',
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeumorphicButton(
                    onTap: () {},
                    borderRadius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.tune_rounded, color: Colors.grey.shade700, size: 20),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Main Content (Sidebar + List)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar Categories
                  Container(
                    width: 110,
                    color: Colors.transparent,
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF0F0F3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected ? [
                                const BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                BoxShadow(color: Colors.grey.shade300, offset: const Offset(3, 3), blurRadius: 6),
                              ] : [],
                            ),
                            child: Text(
                              cat,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF0066FF) : Colors.grey.shade600,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Product List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredProducts.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: NeumorphicContainer(
                                    padding: const EdgeInsets.all(24),
                                    borderRadius: 20,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Aucun produit du catalogue',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade700),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Utilisez l\'onglet "Manuellement" pour créer votre premier produit.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(right: 16, bottom: 20, top: 4),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final p = filteredProducts[index];
                                  return _buildCatalogProductCard(p);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Manual Add Form Placeholder
            Expanded(
              child: Center(
                child: NeumorphicContainer(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Ajout manuel',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Le formulaire manuel s'affichera ici.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCatalogProductCard(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        depth: 4,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with inset effect
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 4),
                  BoxShadow(color: Colors.black12, offset: Offset(-2, -2), blurRadius: 4),
                ]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  p['image_url'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['brand'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${p['rating']} (${p['reviews']})',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${p['price']} DA',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      NeumorphicButton(
                        onTap: () => _handleAddProduct(p),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        borderRadius: 8,
                        child: const Text(
                          'Ajouter',
                          style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 12),
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
    );
  }
}
