import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiBaseUrl = 'https://linky-api.bensebalounes2.workers.dev';
const String adminToken = 'ADMIN_SECRET_TOKEN';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linky Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _codes = [];
  List<dynamic> _users = [];
  List<dynamic> _stores = [];
  List<dynamic> _products = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $adminToken',
  };

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/admin/stats'), headers: _headers),
        http.get(Uri.parse('$apiBaseUrl/api/admin/codes'), headers: _headers),
        http.get(Uri.parse('$apiBaseUrl/api/admin/users'), headers: _headers),
        http.get(Uri.parse('$apiBaseUrl/api/admin/stores'), headers: _headers),
        http.get(Uri.parse('$apiBaseUrl/api/admin/products'), headers: _headers),
      ]);

      if (results[0].statusCode == 200) _stats = json.decode(results[0].body);
      if (results[1].statusCode == 200) _codes = (json.decode(results[1].body)['codes']) ?? [];
      if (results[2].statusCode == 200) _users = (json.decode(results[2].body)['users']) ?? [];
      if (results[3].statusCode == 200) _stores = (json.decode(results[3].body)['stores']) ?? [];
      if (results[4].statusCode == 200) _products = (json.decode(results[4].body)['products']) ?? [];
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _generateCodes(int count, int daysValid) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/admin/codes/generate'),
        headers: _headers,
        body: json.encode({'count': count, 'days_valid': daysValid}),
      );
      if (res.statusCode == 201) {
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count codes générés!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCode(String id) async {
    await http.delete(Uri.parse('$apiBaseUrl/api/admin/codes/$id'), headers: _headers);
    _loadData();
  }

  Future<void> _banUser(String id) async {
    await http.put(Uri.parse('$apiBaseUrl/api/admin/users/$id/ban'), headers: _headers);
    _loadData();
  }

  Future<void> _toggleStore(String id) async {
    await http.put(Uri.parse('$apiBaseUrl/api/admin/stores/$id/toggle'), headers: _headers);
    _loadData();
  }

  Future<void> _verifyStore(String id) async {
    await http.put(Uri.parse('$apiBaseUrl/api/admin/stores/$id/verify'), headers: _headers);
    _loadData();
  }

  void _showGenerateDialog() {
    final countController = TextEditingController(text: '10');
    final daysController = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Générer des codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: countController, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nombre de codes', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: daysController, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jours de validité', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () {
            Navigator.pop(ctx);
            _generateCodes(int.tryParse(countController.text) ?? 10, int.tryParse(daysController.text) ?? 30);
          }, child: const Text('Générer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Linky Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildNavItem(0, Icons.dashboard, 'Dashboard'),
          _buildNavItem(1, Icons.vpn_key, 'Codes'),
          _buildNavItem(2, Icons.people, 'Utilisateurs'),
          _buildNavItem(3, Icons.store, 'Boutiques'),
          _buildNavItem(4, Icons.inventory_2, 'Produits'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text('v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
      title: Text(label, style: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () => setState(() { _selectedTab = index; _searchQuery = ''; }),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0: return _buildDashboard();
      case 1: return _buildCodesTab();
      case 2: return _buildUsersTab();
      case 3: return _buildStoresTab();
      case 4: return _buildProductsTab();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Vue d\'ensemble de la plateforme', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Codes Total', '${_stats['total_codes'] ?? 0}', Icons.key, Colors.blue),
              _buildStatCard('Codes Actifs', '${_stats['active_codes'] ?? 0}', Icons.check_circle, Colors.green),
              _buildStatCard('Utilisés', '${_stats['used_codes'] ?? 0}', Icons.check_circle_outline, Colors.orange),
              _buildStatCard('Expirés', '${_stats['expired_codes'] ?? 0}', Icons.timer_off, Colors.red),
              _buildStatCard('Utilisateurs', '${_stats['total_users'] ?? 0}', Icons.people, Colors.purple),
              _buildStatCard('Boutiques', '${_stats['total_stores'] ?? 0}', Icons.store, Colors.teal),
              _buildStatCard('Produits', '${_stats['total_products'] ?? 0}', Icons.inventory_2, Colors.indigo),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Derniers codes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              FilledButton.icon(onPressed: _showGenerateDialog, icon: const Icon(Icons.add), label: const Text('Générer')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildCodesTable()),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildCodesTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Codes d\'invitation', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              FilledButton.icon(onPressed: _showGenerateDialog, icon: const Icon(Icons.add), label: const Text('Générer')),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildCodesTable()),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final filtered = _searchQuery.isEmpty
        ? _users
        : _users.where((u) => (u['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (u['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Utilisateurs', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: filtered.isEmpty
                  ? const Center(child: Text('Aucun utilisateur'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final u = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: u['avatar_url'] != null && u['avatar_url'].toString().isNotEmpty
                                ? NetworkImage(u['avatar_url']) : null,
                            child: u['avatar_url'] == null || u['avatar_url'].toString().isEmpty
                                ? Text((u['name'] ?? '?')[0].toUpperCase()) : null,
                          ),
                          title: Text(u['name'] ?? 'Sans nom'),
                          subtitle: Text(u['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(u['is_active'] == 1 ? Icons.block : Icons.check_circle,
                                  color: u['is_active'] == 1 ? Colors.red : Colors.green),
                                onPressed: () => _banUser(u['id']),
                                tooltip: u['is_active'] == 1 ? 'Bannir' : 'Activer',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresTab() {
    final filtered = _searchQuery.isEmpty
        ? _stores
        : _stores.where((s) => (s['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Boutiques', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: filtered.isEmpty
                  ? const Center(child: Text('Aucune boutique'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final s = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: s['logo_url'] != null && s['logo_url'].toString().isNotEmpty
                                ? NetworkImage(s['logo_url']) : null,
                            child: s['logo_url'] == null || s['logo_url'].toString().isEmpty
                                ? const Icon(Icons.store) : null,
                          ),
                          title: Row(
                            children: [
                              Text(s['name'] ?? ''),
                              if (s['is_verified'] == 1)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified, color: Colors.blue, size: 16),
                                ),
                            ],
                          ),
                          subtitle: Text('${s['owner_name'] ?? ''} • ${s['total_products'] ?? 0} produits'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(s['is_active'] == 1 ? Icons.visibility_off : Icons.visibility,
                                  color: s['is_active'] == 1 ? Colors.orange : Colors.green),
                                onPressed: () => _toggleStore(s['id']),
                                tooltip: s['is_active'] == 1 ? 'Désactiver' : 'Activer',
                              ),
                              IconButton(
                                icon: Icon(s['is_verified'] == 1 ? Icons.verified : Icons.verified_outlined,
                                  color: s['is_verified'] == 1 ? Colors.blue : Colors.grey),
                                onPressed: () => _verifyStore(s['id']),
                                tooltip: s['is_verified'] == 1 ? 'Retirer vérification' : 'Vérifier',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final filtered = _searchQuery.isEmpty
        ? _products
        : _products.where((p) => (p['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Produits', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: filtered.isEmpty
                  ? const Center(child: Text('Aucun produit'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        final images = json.decode(p['images'] ?? '[]');
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: images.isNotEmpty
                                ? Image.network(images[0], width: 48, height: 48, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image))
                                : Container(width: 48, height: 48, color: Colors.grey[200],
                                    child: const Icon(Icons.image)),
                          ),
                          title: Text(p['name'] ?? ''),
                          subtitle: Text('${p['store_name'] ?? ''} • ${p['base_price'] ?? 0} DA'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p['is_featured'] == 1)
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text('${p['total_sold'] ?? 0} vendus',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: _codes.isEmpty
          ? const Center(child: Text('Aucun code', style: TextStyle(color: Colors.grey)))
          : SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Créé le')),
                  DataColumn(label: Text('Expire le')),
                  DataColumn(label: Text('Utilisé par')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _codes.map((code) {
                  final isUsed = code['is_used'] == 1;
                  final isExpired = DateTime.tryParse(code['expires_at'] ?? '')?.isBefore(DateTime.now()) ?? false;
                  return DataRow(cells: [
                    DataCell(Text(code['code'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUsed ? Colors.orange.withAlpha(30) : isExpired ? Colors.red.withAlpha(30) : Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isUsed ? 'Utilisé' : isExpired ? 'Expiré' : 'Actif',
                        style: TextStyle(color: isUsed ? Colors.orange : isExpired ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )),
                    DataCell(Text(_formatDate(code['created_at']))),
                    DataCell(Text(_formatDate(code['expires_at']))),
                    DataCell(Text(code['created_by_name'] ?? code['used_by'] ?? '-')),
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _deleteCode(code['id']),
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
