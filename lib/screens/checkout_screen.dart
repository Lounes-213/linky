import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/localization/app_localizations.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'cash_on_delivery';

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      appBar: ClayAppBar(
        title: loc.checkout,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(loc.shippingAddress),
            const SizedBox(height: 12),
            _buildAddressCard(),
            const SizedBox(height: 30),
            _buildSectionTitle(loc.paymentMethod),
            const SizedBox(height: 12),
            _buildPaymentMethods(),
            const SizedBox(height: 30),
            _buildSectionTitle(loc.orderSummary),
            const SizedBox(height: 12),
            _buildOrderSummary(cart),
            const SizedBox(height: 40),
            _buildConfirmButton(cart),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: clayText(context),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: clayPrimary(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: clayPrimary(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home Address',
                  style: TextStyle(
                    color: clayText(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '123 Main St, Hydra, Alger',
                  style: TextStyle(
                    color: clayTextSecondary(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_outlined,
            color: clayTextSecondary(context),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        _buildPaymentItem(
          'gold_card',
          'Carte CIB / Edahabia',
          Icons.credit_card_outlined,
          brandColor: const Color(0xFFE9A300),
        ),
        const SizedBox(height: 12),
        _buildPaymentItem(
          'cash_on_delivery',
          loc.cashOnDelivery,
          Icons.payments_outlined,
          brandColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildPaymentItem(
          'ooredoo',
          'Ooredoo Money',
          Icons.account_balance_wallet_outlined,
          brandColor: const Color(0xFFE52629),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(
    String method,
    String label,
    IconData icon, {
    Color? brandColor,
  }) {
    final isSelected = _selectedPayment == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (brandColor ?? clayPrimary(context)).withValues(alpha: 0.05)
              : clayCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (brandColor ?? clayPrimary(context)).withValues(alpha: 0.3)
                : clayBorder(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (brandColor ?? clayPrimary(context))
                  : clayTextSecondary(context),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? clayText(context)
                    : clayTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: brandColor ?? clayPrimary(context),
                size: 20,
              ),
          ],
        ),
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
          const SizedBox(height: 12),
          _buildSummaryRow(
            loc.shipping,
            loc.free,
            valueColor: LinkyColors.accent,
          ),
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

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal
                ? clayText(context)
                : clayTextSecondary(context),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ??
                (isTotal
                    ? clayPrimary(context)
                    : clayText(context)),
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(CartProvider cart) {
    final loc = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _showSuccessDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: clayPrimary(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          loc.placeOrder,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: clayCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: clayCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: clayBorder(context)),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: LinkyColors.accent,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.success,
              style: TextStyle(
                color: clayText(context),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.ordersAppearHere,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: clayTextSecondary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Provider.of<CartProvider>(context, listen: false).clear();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: clayPrimary(context),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  loc.home,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
