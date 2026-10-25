import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:linky/core/theme.dart';
import 'package:linky/core/api/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/shared_ui.dart';

class StoreCartScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String storeSlug;
  final String storePhone;
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback onOrderPlaced;

  const StoreCartScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.storeSlug,
    required this.storePhone,
    required this.cartItems,
    required this.onOrderPlaced,
  });

  @override
  State<StoreCartScreen> createState() => _StoreCartScreenState();
}

class _StoreCartScreenState extends State<StoreCartScreen> {
  String? _selectedWilaya;
  String? _selectedCommune;
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  List<dynamic> _wilayas = [];
  List<dynamic> _communes = [];
  bool _isLoadingWilayas = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadWilayas();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWilayas() async {
    try {
      final res = await ApiService().get('https://raw.githubusercontent.com/aminebennouna/algeria-wilayas-communes/master/data/wilayas.json');
      if (res.isSuccess && res.data != null) {
        final data = res.data!['data'] ?? res.data!['wilayas'] ?? [];
        setState(() {
          _wilayas = data is List ? data : [];
          _isLoadingWilayas = false;
        });
      } else {
        setState(() {
          _wilayas = List.generate(58, (i) => {'code': '${(i + 1).toString().padLeft(2, '0')}', 'name': _wilayaName(i + 1)});
          _isLoadingWilayas = false;
        });
      }
    } catch (_) {
      setState(() {
        _wilayas = List.generate(58, (i) => {'code': '${(i + 1).toString().padLeft(2, '0')}', 'name': _wilayaName(i + 1)});
        _isLoadingWilayas = false;
      });
    }
  }

  String _wilayaName(int code) {
    const names = {
      1: 'Adrar', 2: 'Chlef', 3: 'Laghouat', 4: 'Oum El Bouaghi', 5: 'Batna',
      6: 'Béjaïa', 7: 'Biskra', 8: 'Béchar', 9: 'Blida', 10: 'Bouira',
      11: 'Tamanrasset', 12: 'Tébessa', 13: 'Tlemcen', 14: 'Tiaret', 15: 'Tizi Ouzou',
      16: 'Alger', 17: 'Djelfa', 18: 'Jijel', 19: 'Sétif', 20: 'Saïda',
      21: 'Skikda', 22: 'Sidi Bel Abbès', 23: 'Annaba', 24: 'Guelma', 25: 'Constantine',
      26: 'Médéa', 27: 'Mostaganem', 28: "M'Sila", 29: 'Mascara', 30: 'Ouargla',
      31: 'Oran', 32: 'El Bayadh', 33: 'Illizi', 34: 'Bordj Bou Arréridj', 35: 'Boumerdès',
      36: 'El Tarf', 37: 'Tindouf', 38: 'Tissemsilt', 39: 'El Oued', 40: 'Khenchela',
      41: 'Souk Ahras', 42: 'Tipaza', 43: 'Mila', 44: 'Aïn Defla', 45: 'Naâma',
      46: 'Aïn Témouchent', 47: 'Ghardaïa', 48: 'Relizane', 49: "El M'Ghair", 50: 'El Meniaa',
      51: 'Ouled Djellal', 52: 'Bordj Badji Mokhtar', 53: 'Béni Abbès', 54: 'Timimoun',
      55: 'Touggourt', 56: 'Djanet', 57: 'In Salah', 58: 'In Guezzam',
    };
    return names[code] ?? 'Wilaya $code';
  }

  Future<void> _loadCommunes(String wilayaCode) async {
    try {
      final res = await ApiService().get('https://raw.githubusercontent.com/aminebennouna/algeria-wilayas-communes/master/data/communes.json');
      if (res.isSuccess && res.data != null) {
        final rawData = res.data!['data'] ?? res.data!['communes'] ?? [];
        final allCommunes = rawData is List ? rawData : <dynamic>[];
        setState(() {
          _communes = allCommunes.where((c) {
            if (c is Map) return c['wilaya_code']?.toString() == wilayaCode;
            return false;
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = isDark ? LinkyColors.neuDarkText : LinkyColors.neuLightText;
    final txtMuted = isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted;

    final subtotal = widget.cartItems.fold<double>(0, (sum, item) {
      final price = (item['discount_price'] ?? item['base_price'] ?? 0).toDouble();
      return sum + price * (item['quantity'] ?? 1);
    });
    const delivery = 500;
    final total = subtotal + delivery;

    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      appBar: AppBar(
        backgroundColor: clayScaffoldBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: txt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Panier — ${widget.storeName}',
            style: TextStyle(color: txt, fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.3)),
        actions: [
          if (widget.storePhone.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
                  child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: clayCard(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: clayBorder(context)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  onPressed: _showPhoneWarning,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCartItems(txt, txtMuted),
                const SizedBox(height: 20),
                _buildAddressSection(txt, txtMuted),
                const SizedBox(height: 20),
                _buildOrderSummary(subtotal, delivery, total, txt, txtMuted),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildBottomBar(total, txt),
        ],
      ),
    );
  }

  Widget _buildCartItems(Color txt, Color txtMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Articles (${widget.cartItems.length})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        ...widget.cartItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final price = (item['discount_price'] ?? item['base_price'] ?? 0).toDouble();
          final images = item['images'];
          String imgUrl = '';
          if (images is List && images.isNotEmpty) imgUrl = images[0].toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: clayCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: clayBorder(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: LinkyColors.surfaceVariant,
                    image: imgUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: txt, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (item['selected_size'] != null)
                        Text('Taille: ${item['selected_size']}', style: TextStyle(fontSize: 11, color: txtMuted)),
                      const SizedBox(height: 4),
                      Text('${price.toInt()} DA', style: TextStyle(fontWeight: FontWeight.w700, color: clayPrimary(context))),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _qtyBtn(Icons.remove, () {
                      setState(() {
                        if (item['quantity'] > 1) {
                          item['quantity']--;
                        } else {
                          widget.cartItems.removeAt(i);
                        }
                      });
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${item['quantity']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: txt)),
                    ),
                    _qtyBtn(Icons.add, () => setState(() => item['quantity']++)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: clayCard(context),
          shape: BoxShape.circle,
          border: Border.all(color: clayBorder(context)),
        ),
        child: Icon(icon, size: 16, color: clayPrimary(context)),
      ),
    );
  }

  Widget _buildAddressSection(Color txt, Color txtMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Adresse de livraison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
        const SizedBox(height: 12),

        _buildField('Nom complet', _nameCtrl, Icons.person_outline, txt, txtMuted),
        const SizedBox(height: 10),
        _buildField('Téléphone', _phoneCtrl, Icons.phone_outlined, txt, txtMuted, keyboardType: TextInputType.phone),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: clayCard(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: clayBorder(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedWilaya,
              hint: Text('Wilaya', style: TextStyle(color: txtMuted)),
              icon: Icon(Icons.keyboard_arrow_down, color: txtMuted),
              items: _wilayas.map<DropdownMenuItem<String>>((w) {
                final code = w['code']?.toString() ?? '';
                final name = w['name']?.toString() ?? code;
                return DropdownMenuItem(value: code, child: Text('$code — $name', style: TextStyle(color: txt)));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedWilaya = v;
                  _selectedCommune = null;
                  _communes = [];
                });
                if (v != null) _loadCommunes(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (_communes.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: clayCard(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: clayBorder(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCommune,
                hint: Text('Commune', style: TextStyle(color: txtMuted)),
                icon: Icon(Icons.keyboard_arrow_down, color: txtMuted),
                items: _communes.map<DropdownMenuItem<String>>((c) {
                  final name = c['name']?.toString() ?? '';
                  return DropdownMenuItem(value: name, child: Text(name, style: TextStyle(color: txt)));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCommune = v),
              ),
            ),
          ),
        if (_communes.isNotEmpty) const SizedBox(height: 10),

        _buildField('Adresse détaillée', _addressCtrl, Icons.home_outlined, txt, txtMuted),
        const SizedBox(height: 10),

        _buildField('Notes (optionnel)', _notesCtrl, Icons.note_outlined, txt, txtMuted),
      ],
    );
  }

  Widget _buildField(String hint, TextEditingController ctrl, IconData icon, Color txt, Color txtMuted, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: clayBorder(context)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(color: txt, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(icon, size: 18, color: clayPrimary(context)),
          hintText: hint,
          hintStyle: TextStyle(color: txtMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, int delivery, double total, Color txt, Color txtMuted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Récapitulatif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          ...widget.cartItems.map((item) {
            final price = (item['discount_price'] ?? item['base_price'] ?? 0).toDouble();
            final qty = item['quantity'] ?? 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item['name'] ?? ''} x$qty', style: TextStyle(fontSize: 13, color: txtMuted), overflow: TextOverflow.ellipsis)),
                  Text('${(price * qty).toInt()} DA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Sous-total', style: TextStyle(color: txtMuted)),
            Text('${subtotal.toInt()} DA', style: TextStyle(fontWeight: FontWeight.w700, color: txt)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Livraison', style: TextStyle(color: txtMuted)),
            Text('$delivery DA', style: TextStyle(fontWeight: FontWeight.w700, color: txt)),
          ]),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
            Text('${total.toInt()} DA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: clayPrimary(context))),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double total, Color txt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: clayScaffoldBg(context),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
                    backgroundColor: clayPrimary(context),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _placeOrder,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Confirmer — ${total.toInt()} DA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  void _showPhoneWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Numéro de téléphone requis'),
        content: const Text(
          'Le vendeur n\'a pas configuré de numéro de téléphone. '
          'La commande ne pourra pas être passée. Veuillez contacter le vendeur directement.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (widget.storePhone.isEmpty) {
      _showPhoneWarning();
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre nom'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre numéro de téléphone'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedWilaya == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre wilaya'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedCommune == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre commune'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre adresse'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final subtotal = widget.cartItems.fold<double>(0, (sum, item) {
      final price = (item['discount_price'] ?? item['base_price'] ?? 0).toDouble();
      return sum + price * (item['quantity'] ?? 1);
    });

    final orderSummary = {
      'store_id': widget.storeId,
      'store_name': widget.storeName,
      'customer_name': _nameCtrl.text.trim(),
      'customer_phone': _phoneCtrl.text.trim(),
      'wilaya': _selectedWilaya,
      'wilaya_name': _selectedWilaya,
      'commune': _selectedCommune,
      'address': _addressCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'items': widget.cartItems.map((item) => {
        'product_id': item['id'] ?? '',
        'name': item['name'],
        'price': item['discount_price'] ?? item['base_price'],
        'quantity': item['quantity'],
        'selected_size': item['selected_size'],
      }).toList(),
      'subtotal': subtotal.toInt(),
      'delivery': 500,
      'total': (subtotal + 500).toInt(),
    };

    try {
      final res = await ApiService().post('/api/orders/public', body: orderSummary);
      if (mounted) {
        setState(() => _isSubmitting = false);
        _openSmsToStore(orderSummary);
        _showOrderConfirmation(orderSummary);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _openSmsToStore(orderSummary);
        _showOrderConfirmation(orderSummary);
      }
    }
  }

  void _openSmsToStore(Map<String, dynamic> order) {
    final storePhone = widget.storePhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (storePhone.isEmpty) return;
    final phoneIntl = storePhone.startsWith('+') ? storePhone
        : (storePhone.startsWith('0') ? '+213${storePhone.replaceFirst('0', '')}' : '');
    if (phoneIntl.isEmpty) return;
    final items = (order['items'] as List?) ?? [];
    final itemsTxt = items.map((i) => '• ${i['name']} x${i['quantity']} = ${i['price']} DA').join('\n');
    final body = '📦 NOUVELLE COMMANDE\n'
        'Boutique: ${order['store_name']}\n'
        '\n'
        '👤 Client: ${order['customer_name']}\n'
        '📞 Tél: ${order['customer_phone']}\n'
        '📍 ${order['address']}, ${order['commune']}, ${order['wilaya'] ?? ''}\n'
        '${(order['notes'] ?? '').isNotEmpty ? '📝 Notes: ${order['notes']}\n' : ''}'
        '\n'
        '--- Articles ---\n'
        '$itemsTxt\n'
        '\n'
        'Livraison: 500 DA\n'
        '💰 TOTAL: ${order['total']} DA';
    final uri = Uri.parse('sms:$phoneIntl?body=${Uri.encodeComponent(body)}');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showOrderConfirmation(Map<String, dynamic> order) {
    final items = order['items'] as List;
    final total = order['total'];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                child: Icon(Icons.check, color: clayPrimary(context), size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Commande envoyée !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              const SizedBox(height: 8),
              Text('Votre commande a été envoyée au vendeur.\n${widget.storeName} vous contactera au ${order['customer_phone']}',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: clayCard(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: clayBorder(context)),
                ),
                child: Column(
                  children: [
                    _summaryRow('Client', order['customer_name']),
                    _summaryRow('Téléphone', order['customer_phone']),
                    _summaryRow('Wilaya', '${order['wilaya']} — ${order['commune']}'),
                    _summaryRow('Adresse', order['address']),
                    const Divider(height: 16),
                    ...items.map((item) => _summaryRow(
                      '${item['name']} x${item['quantity']}',
                      '${item['price']} DA',
                    )),
                    const Divider(height: 16),
                    _summaryRow('Livraison', '500 DA'),
                    _summaryRow('Total', '$total DA', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
            backgroundColor: clayPrimary(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onOrderPlaced();
                    Navigator.pop(context);
                  },
                  child: const Text('Terminé', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: isBold ? FontWeight.w700 : FontWeight.normal))),
          Flexible(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
