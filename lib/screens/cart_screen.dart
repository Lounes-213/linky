import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/localization/app_localizations.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
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
            _buildHeader(),
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.items.isEmpty) {
                    return _buildEmptyState();
                  }
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildFreeShippingBanner(),
                        const SizedBox(height: 20),
                        _buildCartItems(cart),
                        const SizedBox(height: 20),
                        _buildPromoCode(),
                        const SizedBox(height: 20),
                        _buildOrderSummary(cart),
                        const SizedBox(height: 20),
                        _buildCheckoutButton(cart),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final loc = AppLocalizations.of(context);
    return ClayAppBar(
      title: loc.myCart,
      actions: [
        SharedIconButton(
          icon: Icons.delete_outline,
          onTap: () {
            final cart = context.read<CartProvider>();
            if (cart.items.isNotEmpty) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.confirm),
                  content: Text(loc.confirm),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.no)),
                    TextButton(
                      onPressed: () {
                        cart.clear();
                        Navigator.pop(ctx);
                      },
                      child: Text(loc.yes, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildFreeShippingBanner() {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.freeShippingBanner,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartProvider cart) {
    final items = cart.items.values.toList();
    return Column(
      children: items.map((item) => _buildCartItem(item, cart)).toList(),
    );
  }

  Widget _buildCartItem(dynamic item, CartProvider cart) {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: TextStyle(
                    color: clayText(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.product.shopName,
                  style: TextStyle(
                    color: clayTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${loc.quantity} : ${item.quantity}',
                  style: TextStyle(
                    color: clayTextMuted(context),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.product.price.toInt()} DA',
                      style: TextStyle(
                        color: clayPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (item.quantity == 1) {
                              cart.removeItem(item.product.id);
                            } else {
                              cart.removeSingleItem(item.product.id);
                            }
                          },
                        ),
                        SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                color: clayText(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          isPrimary: true,
                          onTap: () => cart.addItem(item.product),
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
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap, bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? clayPrimary(context) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: isPrimary ? null : Border.all(color: clayBorder(context)),
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : clayTextSecondary(context),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildPromoCode() {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.confirmation_number_outlined, color: clayTextMuted(context), size: 22),
          ),
          Expanded(
            child: TextField(
              controller: _promoController,
              style: TextStyle(color: clayText(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: loc.promoCode,
                hintStyle: TextStyle(color: clayTextMuted(context)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_promoController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Code promo "${_promoController.text}" appliqué'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                loc.applyPromo,
                style: TextStyle(
                  color: clayTextSecondary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(loc.subtotal, '${cart.totalAmount.toInt()} DA'),
          const SizedBox(height: 14),
          _buildSummaryRow(loc.shipping, 'Gratuite', valueColor: LinkyColors.accent),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Theme.of(context).dividerColor, height: 1),
          ),
          _buildSummaryRow(
            loc.total,
            '${cart.totalAmount.toInt()} DA',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? clayText(context) : clayTextSecondary(context),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (isTotal ? clayPrimary(context) : clayText(context)),
            fontSize: isTotal ? 22 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(CartProvider cart) {
    final loc = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        if (cart.items.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: clayPrimary(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.placeOrder,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_outline, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final loc = AppLocalizations.of(context);
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
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: clayTextMuted(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.emptyCartMessage,
            style: TextStyle(
              color: clayText(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.continueShopping,
            style: TextStyle(
              color: clayTextSecondary(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
