import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';

class DonationsScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const DonationsScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isDonating = false;
  bool _showSuccess = false;

  Map<String, dynamic>? _settings;
  int _totalDonors = 0;
  String _description = '';

  int? _selectedAmount;
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedPaymentMethod = 'bordimob';

  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;

  final List<int> _presetAmounts = [100, 200, 500, 1000];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'bordimob', 'name': 'BordiMob', 'icon': Icons.phone_android},
    {'id': 'ccp', 'name': 'CCP', 'icon': Icons.credit_card},
    {'id': 'redotpay', 'name': 'RedotPay', 'icon': Icons.account_balance_wallet},
    {'id': 'paypay', 'name': 'PayPay', 'icon': Icons.payment},
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOutBack,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _customAmountController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final api = ApiService();
    final res = await api.get('/api/donations/settings/${widget.recipientId}');

    if (res.isSuccess && res.data != null) {
      setState(() {
        _settings = res.data!;
        _totalDonors = res.data!['total_donors'] ?? 120;
        _description = res.data!['description'] ??
            'Soutenez ce créateur dans son parcours. Chaque don compte et l\'aide à continuer à créer du contenu de qualité.';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _description = 'Soutenez ce créateur dans son parcours. Chaque don compte et l\'aide à continuer à créer du contenu de qualité.';
        _totalDonors = 120;
      });
    }
  }

  int get _donationAmount {
    if (_selectedAmount != null) return _selectedAmount!;
    final custom = int.tryParse(_customAmountController.text);
    return custom ?? 0;
  }

  Future<void> _donate() async {
    final amount = _donationAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    setState(() => _isDonating = true);

    final api = ApiService();
    final res = await api.post('/api/donations', body: {
      'recipient_id': widget.recipientId,
      'amount': amount,
      'donor_name': _nameController.text.isNotEmpty ? _nameController.text : null,
      'donor_message': _messageController.text.isNotEmpty ? _messageController.text : null,
      'payment_method': _selectedPaymentMethod,
    });

    setState(() => _isDonating = false);

    if (res.isSuccess) {
      setState(() {
        _showSuccess = true;
        _totalDonors += 1;
      });
      _confettiController.forward();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Erreur lors du don')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: _showSuccess ? _buildSuccessState() : _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: clayPrimary(context)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 24),
                      _buildPresetAmounts(),
                      const SizedBox(height: 16),
                      _buildCustomAmountField(),
                      const SizedBox(height: 24),
                      _buildDonorInfoFields(),
                      const SizedBox(height: 24),
                      _buildPaymentMethods(),
                      const SizedBox(height: 24),
                      _buildDonateButton(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Neumorphism.circle(
            context: context,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Donation',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Neumorphism.light(
      context: context,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Neumorphism.circle(
            context: context,
            size: 72,
            color: LinkyColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.favorite, color: LinkyColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Soutenez ce créateur',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.recipientName,
            style: const TextStyle(
              color: LinkyColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Neumorphism.light(
            context: context,
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: LinkyColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '+$_totalDonors donateurs',
                  style: const TextStyle(
                    color: LinkyColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant du don',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _presetAmounts.map((amount) {
            final isSelected = _selectedAmount == amount;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = amount;
                    _customAmountController.clear();
                  });
                },
                child: Neumorphism.light(
                  context: context,
                  borderRadius: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: isSelected ? LinkyColors.primary : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Text(
                          '$amount',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DA',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant personnalisé',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Neumorphism.light(
          context: context,
          borderRadius: 16,
          child: TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            onTap: () => setState(() => _selectedAmount = null),
            decoration: InputDecoration(
              hintText: 'Entrez le montant',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              suffixIcon: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: LinkyColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DA',
                  style: TextStyle(
                    color: LinkyColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildDonorInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos informations',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Neumorphism.light(
          context: context,
          borderRadius: 16,
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Votre nom (optionnel)',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: 12),
        Neumorphism.light(
          context: context,
          borderRadius: 16,
          child: TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Message (optionnel)',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(Icons.message_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moyen de paiement',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),
      ],
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method['id']),
      child: Neumorphism.light(
        context: context,
        borderRadius: 12,
        margin: const EdgeInsets.only(bottom: 8),
        color: isSelected ? LinkyColors.primary.withValues(alpha: 0.05) : null,
        border: isSelected
            ? Border.all(color: LinkyColors.primary, width: 1.5)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Neumorphism.circle(
                context: context,
                size: 40,
                color: isSelected ? LinkyColors.primary : null,
                child: Icon(
                  method['icon'] as IconData,
                  color: isSelected ? Colors.white : LinkyColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  method['name'] as String,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: LinkyColors.primary, size: 22)
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonateButton() {
    return Neumorphism.button(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDonating ? null : _donate,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: _isDonating
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
                        const Icon(Icons.favorite, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Faire un don${_donationAmount > 0 ? ' - ${_donationAmount} DA' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            ...List.generate(30, (i) {
              final random = (i * 137) % 360;
              final radians = (random * 3.14159) / 180;
              final distance = 50.0 + (i * 17.0) * _confettiAnimation.value;
              final top = MediaQuery.of(context).size.height * 0.35 + (radians * distance * 0.3);
              final left = MediaQuery.of(context).size.width * 0.5 + (radians * distance * 0.8) - 5;
              final colors = [
                LinkyColors.primary,
                LinkyColors.accent,
                LinkyColors.star,
                LinkyColors.neonGreen,
                LinkyColors.neonPurple,
              ];
              return Positioned(
                top: top,
                left: left,
                child: Opacity(
                  opacity: (1 - _confettiAnimation.value).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: _confettiAnimation.value * 10 + i,
                    child: Container(
                      width: 8 + (i % 4).toDouble() * 2,
                      height: 8 + (i % 3).toDouble() * 2,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _confettiAnimation.value,
                    child: Neumorphism.circle(
                      context: context,
                      size: 100,
                      color: LinkyColors.neonGreen,
                      child: const Icon(Icons.check, color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Merci !',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Votre don de $_donationAmount DA a été envoyé',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'à ${widget.recipientName}',
                    style: const TextStyle(
                      color: LinkyColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Neumorphism.button(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          child: Text(
                            'Retour',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
