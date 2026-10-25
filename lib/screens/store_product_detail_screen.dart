import 'package:flutter/material.dart';
import '../core/shared_ui.dart';

class StoreProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const StoreProductDetailScreen({super.key, required this.product});

  @override
  State<StoreProductDetailScreen> createState() => _StoreProductDetailScreenState();
}

class _StoreProductDetailScreenState extends State<StoreProductDetailScreen> {
  int _quantity = 1;
  String _selectedSize = '50ml'; // Default
  final List<String> _sizes = ['30ml', '50ml', '100ml'];

  @override
  Widget build(BuildContext context) {
    final title = widget.product['name']?.toString() ?? widget.product['title']?.toString() ?? 'Produit Inconnu';
    final brand = widget.product['brand']?.toString() ?? 'Marque Inconnue';
    final basePrice = double.tryParse(widget.product['base_price']?.toString() ?? widget.product['price']?.toString() ?? '0') ?? 0;
    final oldPrice = double.tryParse(widget.product['compare_at_price']?.toString() ?? '31000') ?? 0; 
    final discount = oldPrice > basePrice ? (((oldPrice - basePrice) / oldPrice) * 100).round() : 0;
    
    final desc = widget.product['description']?.toString() ?? 'Un produit élégant et intemporel pour toutes les occasions.';
    
    // Attempt to parse images safely
    List<String> images = [];
    if (widget.product['images'] is List) {
      images = List<String>.from(widget.product['images']);
    } else if (widget.product['image_url'] != null) {
      images = [widget.product['image_url'].toString()];
    } else {
      images = ['https://images.unsplash.com/photo-1541643600914-78b084683601?w=600'];
    }
    
    final heroImage = images.isNotEmpty ? images.first : 'https://images.unsplash.com/photo-1541643600914-78b084683601?w=600';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120), // Space for bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Container (Inset effect)
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.45,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FC),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Image.network(
                              heroImage,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Top App Bar Icons
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _cleanBtn(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              Row(
                                children: [
                                  _cleanBtn(
                                    icon: Icons.share_outlined,
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 8),
                                  _cleanBtn(
                                    icon: Icons.more_horiz_rounded,
                                    onTap: () {},
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Details Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Brand
                      Text(
                        title,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.2, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        brand,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),

                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '4.9 (310)', // Mocked rating matching image
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Pricing
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${basePrice.toInt()} DA',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0066FF), letterSpacing: -0.3),
                          ),
                          const SizedBox(width: 12),
                          if (oldPrice > basePrice) ...[
                            Text(
                              '${oldPrice.toInt()} DA',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '-$discount%',
                                style: const TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        desc,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Size Selector (Taille)
                      const Text('Taille', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: -0.3)),
                      const SizedBox(height: 12),
                      Row(
                        children: _sizes.map((size) {
                          final isSelected = size == _selectedSize;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSize = size),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFF8F9FC),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                size,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Quantity Selector (Quantité)
                      const Text('Quantité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: -0.3)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () {
                                    if (_quantity > 1) setState(() => _quantity--);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () {
                                    setState(() => _quantity++);
                                  },
                                ),
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

          // Bottom Bar (Sticky)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FC),
              ),
              child: Row(
                children: [
                  _cleanBtn(
                    icon: Icons.favorite_border_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajouté au panier !'), backgroundColor: Colors.green)
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Ajouter au panier', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cleanBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: Colors.black87, size: 18),
      ),
    );
  }
}
