import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/localization/app_localizations.dart';
import '../providers/wishlist_provider.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(loc),
            Expanded(
              child: Consumer<WishlistProvider>(
                builder: (context, wishlist, child) {
                  if (wishlist.isLoading) {
                    return Center(child: CircularProgressIndicator(color: clayPrimary(context)));
                  }
                  if (wishlist.productIds.isEmpty) {
                    return _buildEmptyState(loc);
                  }
                  return _buildGrid(wishlist);
                },
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
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: clayCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: clayBorder(context)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
          ),
          const Spacer(),
          Text(
            loc.wishlist,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildGrid(WishlistProvider wishlist) {
    return RefreshIndicator(
      onRefresh: () => wishlist.loadWishlist(),
      color: LinkyColors.primary,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: wishlist.products.length,
        itemBuilder: (context, index) {
          final product = wishlist.products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['product_id'].toString();
    final name = product['product_name'] ?? 'Produit';
    final price = product['product_price'] ?? 0;
    final image = product['product_image'];
    final storeName = product['store_name'] ?? 'Boutique';

    return Dismissible(
      key: ValueKey(productId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: LinkyColors.discount,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        context.read<WishlistProvider>().toggle(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).deleted)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: clayBorder(context)),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  productId: productId,
                  heroTag: 'wishlist_$productId',
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        image: DecorationImage(
                          image: NetworkImage(image ?? 'https://via.placeholder.com/400'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => context.read<WishlistProvider>().toggle(productId),
                          child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: clayCard(context),
                            shape: BoxShape.circle,
                            border: Border.all(color: clayBorder(context)),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.favorite, size: 18, color: LinkyColors.discount),
                          ),
                        ),
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
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      storeName,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${price.toInt()} DA',
                      style: TextStyle(
                        color: clayPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: clayCard(context),
              shape: BoxShape.circle,
              border: Border.all(color: clayBorder(context)),
            ),
            child: Icon(Icons.favorite_border, size: 60, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            loc.emptyCart,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.continueShopping,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
