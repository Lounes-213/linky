import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';

class StoreTeamScreen extends StatefulWidget {
  const StoreTeamScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });
  final String storeId;
  final String storeName;
  @override
  State<StoreTeamScreen> createState() => _StoreTeamScreenState();
}

class _StoreTeamScreenState extends State<StoreTeamScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _canManage = false;
  List<Map<String, dynamic>> _members = [];
  static const _roles = {
    'manager': 'Manager',
    'partner': 'Partenaire',
    'editor': 'Éditeur',
    'viewer': 'Lecteur',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _api.get('/api/stores/${widget.storeId}/team');
    if (mounted) {
      setState(() {
        _members = List<Map<String, dynamic>>.from(
          r.data?['members'] ?? const [],
        );
        _canManage = r.data?['can_manage_team'] == true;
        _loading = false;
      });
    }
  }

  Future<void> _invite() async {
    final email = TextEditingController();
    String role = 'partner';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (_, update) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Inviter dans l’équipe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email du compte Linky',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: _roles.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (value) => update(() => role = value!),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Inviter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    final r = await _api.post(
      '/api/stores/${widget.storeId}/team',
      body: {'email': email.text.trim(), 'role': role},
    );
    if (r.isSuccess) {
      _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.error ?? 'Invitation impossible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ClayAppBar(
      title: 'Équipe · ${widget.storeName}',
    ),
    floatingActionButton: _canManage
        ? FloatingActionButton.extended(
            onPressed: _invite,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Inviter'),
          )
        : null,
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: clayCard(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Propriétaire : contrôle total\nManager : gère l’équipe et la boutique\nPartenaire : travaille sur la boutique\nÉditeur : modifie le contenu\nLecteur : consulte les statistiques',
                  style: TextStyle(height: 1.45),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${_members.length} membre(s)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ..._members.map(_member),
            ],
          ),
  );

  Widget _member(Map<String, dynamic> m) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundImage: (m['avatar_url']?.toString().isNotEmpty ?? false)
            ? NetworkImage(m['avatar_url'])
            : null,
        child: m['avatar_url']?.toString().isNotEmpty == true
            ? null
            : const Icon(Icons.person),
      ),
      title: Text(
        m['name']?.toString().isNotEmpty == true
            ? m['name']
            : m['email']?.toString() ?? 'Membre',
      ),
      subtitle: Text(
        m['role'] == 'owner'
            ? 'Propriétaire'
            : (_roles[m['role']] ?? m['role']?.toString() ?? ''),
      ),
      trailing: _canManage && m['role'] != 'owner'
          ? PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'remove') {
                  await _api.delete(
                    '/api/stores/${widget.storeId}/team/${m['id']}',
                  );
                } else {
                  await _api.put(
                    '/api/stores/${widget.storeId}/team/${m['id']}',
                    body: {'role': v},
                  );
                }
                _load();
              },
              itemBuilder: (_) => [
                ..._roles.entries.map(
                  (e) => PopupMenuItem(
                    value: e.key,
                    child: Text('Rôle : ${e.value}'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Retirer',
                    style: TextStyle(color: LinkyColors.discount),
                  ),
                ),
              ],
            )
          : null,
    ),
  );
}
