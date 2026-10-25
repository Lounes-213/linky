import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/localization/app_localizations.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _stats = {};
  List<dynamic> _codes = [];
  int _codesTotal = 0;
  List<dynamic> _users = [];
  int _usersTotal = 0;
  List<dynamic> _stores = [];
  int _storesTotal = 0;
  List<dynamic> _products = [];
  int _productsTotal = 0;

  final _searchController = TextEditingController();
  String _codesFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.get('/api/admin/stats'),
        api.get('/api/admin/codes'),
        api.get('/api/admin/users'),
        api.get('/api/admin/stores'),
        api.get('/api/admin/products'),
      ]);
      if (results[0].isSuccess) _stats = results[0].data!;
      if (results[1].isSuccess) { _codes = results[1].data!['codes'] ?? []; _codesTotal = results[1].data!['total'] ?? 0; }
      if (results[2].isSuccess) { _users = results[2].data!['users'] ?? []; _usersTotal = results[2].data!['total'] ?? 0; }
      if (results[3].isSuccess) { _stores = results[3].data!['stores'] ?? []; _storesTotal = results[3].data!['total'] ?? 0; }
      if (results[4].isSuccess) { _products = results[4].data!['products'] ?? []; _productsTotal = results[4].data!['total'] ?? 0; }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _search(String type, String query) async {
    final api = ApiService();
    if (type == 'users') {
      final res = await api.get('/api/admin/users', queryParams: {'search': query});
      if (res.isSuccess) setState(() { _users = res.data!['users'] ?? []; _usersTotal = res.data!['total'] ?? 0; });
    } else if (type == 'stores') {
      final res = await api.get('/api/admin/stores', queryParams: {'search': query});
      if (res.isSuccess) setState(() { _stores = res.data!['stores'] ?? []; _storesTotal = res.data!['total'] ?? 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ClayAppBar(
        title: loc.adminPanel,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: clayPrimary(context)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildBody(isDark),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: loc.dashboard),
          NavigationDestination(icon: Icon(Icons.vpn_key_outlined), selectedIcon: Icon(Icons.vpn_key), label: loc.codesTab),
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: loc.usersTab),
          NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: loc.storesTab),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: loc.productsTab),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_selectedIndex) {
      case 0: return _buildDashboard(isDark);
      case 1: return _buildCodes(isDark);
      case 2: return _buildUsers(isDark);
      case 3: return _buildStores(isDark);
      case 4: return _buildProducts(isDark);
      default: return const SizedBox();
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Neumorphism.light(
      context: context,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: clayText(context))),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: clayTextSecondary(context))),
        ],
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    final loc = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.overview, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: clayText(context))),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 500 ? 2 : 2;
                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard(loc.usersTab, '${_stats['total_users'] ?? 0}', Icons.people, LinkyColors.primary, isDark),
                    _buildStatCard(loc.shops, '${_stats['total_stores'] ?? 0}', Icons.store, Colors.teal, isDark),
                    _buildStatCard(loc.products, '${_stats['total_products'] ?? 0}', Icons.inventory_2, Colors.orange, isDark),
                    _buildStatCard(loc.activeCodes, '${_stats['active_codes'] ?? 0}', Icons.vpn_key, Colors.green, isDark),
                    _buildStatCard(loc.usedCodes, '${_stats['used_codes'] ?? 0}', Icons.check_circle, Colors.purple, isDark),
                    _buildStatCard(loc.expiredCodes, '${_stats['expired_codes'] ?? 0}', Icons.timer_off, Colors.red, isDark),
                    _buildStatCard(loc.totalCodes, '${_stats['total_codes'] ?? 0}', Icons.key, LinkyColors.accent, isDark),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodes(bool isDark) {
    final loc = AppLocalizations.of(context);
    final filtered = _codesFilter == 'all' ? _codes
        : _codesFilter == 'used' ? _codes.where((c) => c['is_used'] == 1).toList()
        : _codesFilter == 'unused' ? _codes.where((c) => c['is_used'] == 0 && DateTime.tryParse(c['expires_at'] ?? '')?.isAfter(DateTime.now()) == true).toList()
        : _codes.where((c) => DateTime.tryParse(c['expires_at'] ?? '')?.isBefore(DateTime.now()) == true).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'all', label: Text(loc.filterAll)),
                    ButtonSegment(value: 'used', label: Text(loc.filterUsed)),
                    ButtonSegment(value: 'unused', label: Text(loc.filterActive)),
                    ButtonSegment(value: 'expired', label: Text(loc.filterExpired)),
                  ],
                  selected: {_codesFilter},
                  onSelectionChanged: (s) => setState(() => _codesFilter = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showGenerateDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(loc.generate),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(loc.codesTotal.replaceFirst('{count}', '$_codesTotal'), style: TextStyle(color: clayTextSecondary(context), fontSize: 12)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(loc.noCodes))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildCodeCard(filtered[i], isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> code, bool isDark) {
    final loc = AppLocalizations.of(context);
    final isUsed = code['is_used'] == 1;
    final expiresAt = DateTime.tryParse(code['expires_at'] ?? '');
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final statusColor = isUsed ? Colors.orange : (isExpired ? Colors.red : Colors.green);
    final statusText = isUsed ? loc.usedLabel : (isExpired ? loc.expiredLabel : loc.activeLabel);

    return Neumorphism.light(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.vpn_key, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code['code'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace', color: clayText(context))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    if (expiresAt != null)
                      Text(loc.expiresAt.replaceFirst('{date}', '${DateFormat('dd/MM/yyyy').format(expiresAt)}'), style: TextStyle(fontSize: 12, color: clayTextSecondary(context))),
                  ],
                ),
                if (code['created_by_name'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${loc.createdBy}: ${code['created_by_name']}', style: TextStyle(fontSize: 11, color: clayTextMuted(context))),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: clayTextSecondary(context)),
            tooltip: loc.copyCode,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code['code'] ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.codeCopied.replaceFirst('{code}', '${code['code']}')), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDeleteCode(code),
          ),
        ],
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final countCtrl = TextEditingController(text: '10');
    final daysCtrl = TextEditingController(text: '30');
    DateTime expiresAt = DateTime.now().add(const Duration(days: 30));
    bool generating = false;

    void syncFromDays() {
      final d = int.tryParse(daysCtrl.text) ?? 30;
      expiresAt = DateTime.now().add(Duration(days: d.clamp(1, 3650)));
    }

    void syncFromExpiry() {
      final d = expiresAt.difference(DateTime.now()).inDays.clamp(1, 3650);
      daysCtrl.text = '$d';
    }

    String daysUntil(DateTime date) {
      final diff = date.difference(DateTime.now()).inDays;
      return '$diff jour${diff > 1 ? 's' : ''}';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LinkyColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.vpn_key, color: LinkyColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(loc.generateCodes, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.numberOfCodes,
                  hintText: '1 à 50',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.durationDays,
                  hintText: '30',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                  suffixText: loc.days,
                ),
                onChanged: (v) {
                  setDialogState(() => syncFromDays());
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: expiresAt,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    helpText: loc.expirationDate.toUpperCase(),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      expiresAt = picked;
                      syncFromExpiry();
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: loc.orChooseDate,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      hintText: 'jj/mm/aaaa',
                      disabledBorder: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(expiresAt)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(loc.summary, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('• ${countCtrl.text} code${(int.tryParse(countCtrl.text) ?? 0) > 1 ? 's' : ''}', style: const TextStyle(fontSize: 13)),
                    Text('• Valide ${daysUntil(expiresAt)}', style: const TextStyle(fontSize: 13)),
                    Text('• Expire le ${DateFormat('dd/MM/yyyy').format(expiresAt)}', style: const TextStyle(fontSize: 13)),
                    Text('• Format: LINKY-XXXXXXXXXX (10 caractères aléatoires)', style: const TextStyle(fontSize: 13)),
                    Text('• Si expire → boutique bloquée', style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
            FilledButton.icon(
              onPressed: generating ? null : () async {
                setDialogState(() => generating = true);
                final daysValid = expiresAt.difference(DateTime.now()).inDays;
                if (daysValid < 1) {
                  setDialogState(() => generating = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.dateMustBeFuture), backgroundColor: Colors.orange),
                  );
                  return;
                }
                final api = ApiService();
                final res = await api.post('/api/admin/codes/generate', body: {
                  'count': int.tryParse(countCtrl.text) ?? 10,
                  'days_valid': daysValid,
                });
                Navigator.pop(ctx);
                if (res.isSuccess && mounted) {
                  final codes = res.data?['codes'] as List<dynamic>? ?? [];
                  _showGeneratedResult(context, codes, daysUntil(expiresAt));
                  _loadAll();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${res.error}'), backgroundColor: Colors.red),
                  );
                }
              },
              icon: generating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.generating_tokens, size: 18),
              label: Text(generating ? loc.generating : loc.generate),
            ),
          ],
        ),
      ),
    );
  }

  void _showGeneratedResult(BuildContext context, List<dynamic> codes, String durationLabel) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.codesGenerated.replaceFirst('{count}', '${codes.length}'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(loc.validFor.replaceFirst('{duration}', durationLabel), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final allCodes = codes.map((c) => c['code'].toString()).join('\n');
                        Clipboard.setData(ClipboardData(text: allCodes));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.allCodesCopied), backgroundColor: Colors.green),
                        );
                      },
                      icon: const Icon(Icons.copy_all, size: 16),
                      label: Text(loc.copyAll),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: codes.length,
                  itemBuilder: (_, i) {
                    final code = codes[i];
                    final expiresAt = DateTime.tryParse(code['expires_at'] ?? '');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(code['code'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14)),
                                if (expiresAt != null)
                                  Text(loc.expiresAt.replaceFirst('{date}', '${DateFormat('dd/MM/yyyy').format(expiresAt)}'), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: loc.copy,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code['code'] ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.codeCopied.replaceFirst('{code}', '${code['code']}')), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.close)),
        ],
      ),
    );
  }

  void _confirmDeleteCode(Map<String, dynamic> code) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteCode),
        content: Text(loc.deleteConfirm.replaceFirst('{code}', '${code['code']}')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ApiService();
              final res = await api.delete('/api/admin/codes/${code['id']}');
              if (res.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.codeDeleted), backgroundColor: Colors.green));
                _loadAll();
              }
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildUsers(bool isDark) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: loc.searchUser,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => _search('users', v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(loc.usersCount.replaceFirst('{count}', '$_usersTotal'), style: TextStyle(color: clayTextSecondary(context), fontSize: 12)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _users.isEmpty
              ? Center(child: Text(loc.noUsers))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) => _buildUserCard(_users[i], isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isDark) {
    final loc = AppLocalizations.of(context);
    final isActive = user['is_active'] == 1;
    return Neumorphism.light(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: LinkyColors.primary.withValues(alpha: 0.1),
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null ? Text((user['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: LinkyColors.primary, fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? loc.noName, style: TextStyle(fontWeight: FontWeight.bold, color: clayText(context))),
                const SizedBox(height: 2),
                Text(user['email'] ?? '', style: TextStyle(fontSize: 12, color: clayTextSecondary(context))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(isActive ? loc.activeLabel : loc.blocked, style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    if (user['store_count'] != null && user['store_count'] > 0)
                      Text(loc.storesCount.replaceFirst('{count}', '${user['store_count']}'), style: TextStyle(fontSize: 11, color: clayTextMuted(context))),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeColor: Colors.green,
            inactiveTrackColor: Colors.red.withValues(alpha: 0.5),
            onChanged: (v) => _toggleBan(user),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBan(Map<String, dynamic> user) async {
    final api = ApiService();
    final res = await api.put('/api/admin/users/${user['firebase_uid']}/ban');
    if (res.isSuccess) {
      final newStatus = res.data?['is_active'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.data?['message'] ?? ''), backgroundColor: newStatus == 1 ? Colors.green : Colors.orange),
      );
      _loadAll();
    }
  }

  Widget _buildStores(bool isDark) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: loc.searchStore,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => _search('stores', v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(loc.storesCount.replaceFirst('{count}', '$_storesTotal'), style: TextStyle(color: clayTextSecondary(context), fontSize: 12)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _stores.isEmpty
              ? Center(child: Text(loc.noStores))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _stores.length,
                  itemBuilder: (ctx, i) => _buildStoreCard(_stores[i], isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store, bool isDark) {
    final loc = AppLocalizations.of(context);
    final isActive = store['is_active'] == 1;
    final isVerified = store['is_verified'] == 1;
    final expiresAt = DateTime.tryParse(store['code_expires_at'] ?? '');
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

    return Neumorphism.light(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: LinkyColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: store['logo_url'] != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(store['logo_url'], fit: BoxFit.cover))
                    : const Icon(Icons.store, color: LinkyColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: clayText(context))),
                    const SizedBox(height: 2),
                    Text(store['owner_name'] ?? '', style: TextStyle(fontSize: 12, color: clayTextSecondary(context))),
                    if (expiresAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: isExpired ? Colors.red : Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              isExpired ? loc.expiresAt.replaceFirst('{date}', '${DateFormat('dd/MM/yyyy').format(expiresAt)}') : loc.expiresOn.replaceFirst('{date}', '${DateFormat('dd/MM/yyyy').format(expiresAt)}'),
                              style: TextStyle(fontSize: 11, color: isExpired ? Colors.red : Colors.orange, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusChip(isActive ? loc.activeLabel : loc.inactive, isActive ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              _statusChip(isVerified ? loc.verified : loc.notVerified, isVerified ? Colors.blue : Colors.grey),
              if (isExpired) ...[
                const SizedBox(width: 8),
                _statusChip(loc.expiredLabel, Colors.red),
              ],
              const Spacer(),
              if (isExpired || !isActive)
                IconButton(
                  icon: const Icon(Icons.autorenew, color: Colors.green, size: 20),
                  onPressed: () => _showRenewDialog(store),
                  tooltip: loc.renew,
                ),
              IconButton(
                icon: Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.red : Colors.green, size: 20),
                onPressed: () => _toggleStore(store),
                tooltip: isActive ? loc.disable : loc.enable,
              ),
              IconButton(
                icon: Icon(isVerified ? Icons.verified_outlined : Icons.verified, color: isVerified ? Colors.grey : Colors.blue, size: 20),
                onPressed: () => _verifyStore(store),
                tooltip: isVerified ? loc.removeVerification : loc.verifyStore,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _toggleStore(Map<String, dynamic> store) async {
    final api = ApiService();
    final res = await api.put('/api/admin/stores/${store['id']}/toggle');
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data?['message'] ?? ''), backgroundColor: Colors.green));
      _loadAll();
    }
  }

  Future<void> _verifyStore(Map<String, dynamic> store) async {
    final api = ApiService();
    final res = await api.put('/api/admin/stores/${store['id']}/verify');
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data?['message'] ?? ''), backgroundColor: Colors.blue));
      _loadAll();
    }
  }

  void _showRenewDialog(Map<String, dynamic> store) {
    final loc = AppLocalizations.of(context);
    final daysCtrl = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.autorenew, color: Colors.green, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(loc.renewStore.replaceFirst('{name}', '${store['name']}'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.activateStoreFor, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.numberOfDays,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer_outlined),
                suffixText: loc.days,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ApiService();
              final res = await api.post('/api/admin/stores/${store['id']}/renew', body: {
                'days_valid': int.tryParse(daysCtrl.text) ?? 30,
              });
              if (res.isSuccess && mounted) {
                final newCode = res.data?['new_code'];
                final expires = res.data?['code_expires_at'];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.renewedWithCode.replaceFirst('{code}', '$newCode')),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(label: loc.copy, textColor: Colors.white, onPressed: () {
                      Clipboard.setData(ClipboardData(text: newCode ?? ''));
                    }),
                  ),
                );
                _loadAll();
              }
            },
            icon: const Icon(Icons.autorenew, size: 18),
            label: Text(loc.renew),
          ),
        ],
      ),
    );
  }

  Widget _buildProducts(bool isDark) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(loc.productsCount.replaceFirst('{count}', '$_productsTotal'), style: TextStyle(color: clayTextSecondary(context), fontSize: 12)),
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? Center(child: Text(loc.noProducts))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _products.length,
                  itemBuilder: (ctx, i) => _buildProductCard(_products[i], isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isDark) {
    final loc = AppLocalizations.of(context);
    List<String> images = [];
    try { images = List<String>.from(jsonDecode(product['images'] ?? '[]')); } catch (_) {}
    final price = product['base_price'] != null ? '${product['base_price']} DA' : '';

    return Neumorphism.light(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: images.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(images.first, fit: BoxFit.cover))
                : const Icon(Icons.inventory_2, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: clayText(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product['store_name'] ?? '', style: TextStyle(fontSize: 12, color: clayTextSecondary(context))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: LinkyColors.primary)),
              const SizedBox(height: 2),
              Text(loc.soldCount.replaceFirst('{count}', '${product['total_sold'] ?? 0}'), style: TextStyle(fontSize: 11, color: clayTextMuted(context))),
            ],
          ),
        ],
      ),
    );
  }
}
