import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/constants/app_constants.dart';

class CreateStoreScreen extends StatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  bool _isCreating = false;

  final _codeController = TextEditingController();
  bool _codeValidated = false;
  bool _isValidating = false;
  String? _codeError;

  final _nameController = TextEditingController();
  String _selectedCategory = '';
  String _selectedSubCategory = '';

  final _api = ApiService();

  final _categories = [
    'Beauty', 'Fashion', 'Electronics', 'Home', 'Sports',
    'Food', 'Automotive', 'Health', 'Kids', 'Other'
  ];

  final _subCategories = {
    'Beauty': ['Perfumes', 'Cosmetics', 'Skincare', 'Makeup'],
    'Fashion': ['Clothing', 'Shoes', 'Accessories', 'Jewelry'],
    'Electronics': ['Phones', 'Computers', 'Audio', 'Gaming'],
    'Home': ['Decor', 'Kitchen', 'Textile', 'Furniture'],
    'Sports': ['Fitness', 'Outdoor', 'Team Sports', 'Cycling'],
  };

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _codeError = 'Code requis');
      return;
    }
    setState(() { _isValidating = true; _codeError = null; });
    try {
      final res = await _api.get('${AppConstants.storesEndpoint}/validate-code?code=${_codeController.text.trim()}');
      if (res.isSuccess) {
        setState(() { _codeValidated = true; _codeError = null; });
      } else {
        setState(() => _codeError = res.error ?? 'Invalid code');
      }
    } catch (e) {
      setState(() => _codeError = 'Connection error');
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _createStore() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isCreating = true);
    try {
      final res = await _api.post(AppConstants.storesEndpoint, body: {
        'name': _nameController.text.trim(),
        'invite_code': _codeController.text.trim(),
        if (_selectedCategory.isNotEmpty) 'category': _selectedCategory,
        if (_selectedSubCategory.isNotEmpty) 'subcategory': _selectedSubCategory,
      });

      if (res.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        final msg = res.data?['detail']?.toString() ?? res.data?['error']?.toString() ?? res.error ?? 'Error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      appBar: ClayAppBar(
        title: 'Create Store',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Invitation Code', 'Enter the code you received'),
            const SizedBox(height: 8),
            _buildCodeCard(isDark),
            if (_codeValidated) ...[
              const SizedBox(height: 28),
              _buildTitle('Store Info', 'Choose a name and category'),
              const SizedBox(height: 8),
              _buildStoreCard(isDark),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: _buildButton(context),
    );
  }

  Widget _buildTitle(String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3,
          color: clayText(context))),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14,
          color: clayTextSecondary(context))),
      ],
    );
  }

  Widget _buildCodeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: clayCard(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: clayBorder(context)),
            ),
            child: TextField(
              controller: _codeController,
              enabled: !_codeValidated,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: clayText(context)),
              decoration: InputDecoration(
                labelText: 'Invitation code',
                hintText: 'LINKY-XXXXXXXXXX',
                labelStyle: TextStyle(color: clayTextSecondary(context)),
                hintStyle: TextStyle(color: clayTextMuted(context)),
                prefixIcon: Icon(Icons.vpn_key, size: 20, color: clayPrimary(context)),
                suffixIcon: _codeValidated
                    ? const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.check_circle, color: Colors.green, size: 20))
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: clayBorder(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: clayBorder(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: clayPrimary(context), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          if (_codeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Text(_codeError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ]),
            ),
          if (_codeValidated)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text('Valid code!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: clayBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: clayCard(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: clayBorder(context)),
            ),
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: clayText(context)),
              decoration: InputDecoration(
                labelText: 'Store name',
                hintText: 'My Store',
                labelStyle: TextStyle(color: clayTextSecondary(context)),
                hintStyle: TextStyle(color: clayTextMuted(context)),
                prefixIcon: Icon(Icons.store, size: 20, color: clayPrimary(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: linkyPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
            color: clayText(context))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final isSelected = _selectedCategory == c;
              return GestureDetector(
                onTap: () => setState(() { _selectedCategory = c; _selectedSubCategory = ''; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? clayPrimary(context).withValues(alpha: 0.1) : clayCard(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? clayPrimary(context) : clayBorder(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(c, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                    color: isSelected ? clayPrimary(context) : clayTextSecondary(context))),
                ),
              );
            }).toList(),
          ),
          if (_subCategories.containsKey(_selectedCategory)) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: clayCard(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: clayBorder(context)),
              ),
              child: DropdownButton<String>(
                value: _selectedSubCategory.isEmpty ? null : _selectedSubCategory,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: isDark ? LinkyColors.darkSurface : LinkyColors.surface,
                style: TextStyle(color: clayText(context)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                hint: Text('Sub-category (optional)', style: TextStyle(
                  color: clayTextSecondary(context))),
                items: _subCategories[_selectedCategory]!
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedSubCategory = v ?? ''),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: clayScaffoldBg(context),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isCreating
                ? null
                : _codeValidated
                    ? _createStore
                    : (_codeController.text.trim().isEmpty ? null : _validateCode),
            style: ElevatedButton.styleFrom(
              backgroundColor: clayPrimary(context),
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isCreating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _codeValidated ? 'Create my store' : 'Verify code',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
