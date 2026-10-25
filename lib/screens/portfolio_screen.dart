import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linky/core/api/api_service.dart';
import 'package:linky/core/theme.dart';
import 'package:linky/core/widgets/neu_button.dart';
import 'package:linky/core/widgets/neumorphic_ui.dart';
import 'package:linky/core/widgets/neu_scaffold.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/profile/portfolio');
      if (mounted && res.isSuccess && res.data != null) {
        final list = res.data!['projects'] ?? res.data!['portfolio'] ?? [];
        _projects = List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showToast(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _addProject() => _showProjectModal(null);
  Future<void> _editProject(Map<String, dynamic> project) => _showProjectModal(project);

  Future<void> _showProjectModal(Map<String, dynamic>? existing) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final categoryCtrl = TextEditingController(text: existing?['category']?.toString() ?? '');
    final urlCtrl = TextEditingController(text: existing?['project_url']?.toString() ?? existing?['url']?.toString() ?? '');
    final keywordsCtrl = TextEditingController(text: existing?['keywords']?.toString() ?? '');
    List<String> imageUrls = [];
    if (existing != null) {
      if (existing['images'] is List) {
        imageUrls = List<String>.from((existing['images'] as List).map((e) => e.toString()));
      } else if (existing['image_url'] != null && existing['image_url'].toString().isNotEmpty) {
        imageUrls = [existing['image_url'].toString()];
      }
    }
    String? existingId = existing?['id']?.toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMState) => Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
          decoration: BoxDecoration(
            color: NeuColors.bg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: NeuColors.shadowLight(context), offset: const Offset(0, -6), blurRadius: 12),
              BoxShadow(color: NeuColors.shadowDark(context).withValues(alpha: 0.2), offset: const Offset(0, -2), blurRadius: 6),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: NeuColors.textMuted(context).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    NeumorphicContainer(padding: const EdgeInsets.all(10), borderRadius: 14, depth: 4, child: Icon(isEdit ? Icons.edit_outlined : Icons.add_photo_alternate_outlined, color: LinkyColors.primary, size: 24)),
                    const SizedBox(width: 14),
                    Text(isEdit ? 'Modifier le Projet' : 'Nouveau Projet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: NeuColors.text(context))),
                  ],
                ),
                const SizedBox(height: 24),

                // Images grid
                Text('Images (${imageUrls.length}/5)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NeuColors.textMuted(context))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...imageUrls.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final url = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: NeuColors.iconBg(context), child: Icon(Icons.broken_image_outlined, color: NeuColors.textMuted(context))),
                                ),
                              ),
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => setMState(() => imageUrls.removeAt(idx)),
                                  child: Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: Icon(Icons.close, size: 14, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (imageUrls.length < 5)
                        GestureDetector(
                          onTap: () async {
                            final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              final upload = await _api.upload('/api/upload', bytes, 'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg', folder: 'portfolio');
                              if (upload.isSuccess && upload.data?['url'] != null) {
                                setMState(() => imageUrls.add(upload.data!['url'].toString()));
                              }
                            }
                          },
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: LinkyColors.primary.withValues(alpha: 0.08),
                              border: Border.all(color: LinkyColors.primary.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: LinkyColors.primary, size: 28),
                                const SizedBox(height: 4),
                                Text('Ajouter', style: TextStyle(color: LinkyColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildNeuField(context, titleCtrl, 'Titre du projet', Icons.label_outline),
                const SizedBox(height: 14),
                _buildNeuField(context, descCtrl, 'Description', Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 14),
                _buildNeuField(context, keywordsCtrl, 'Mots-clés (séparés par des virgules)', Icons.tag, maxLines: 2),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildNeuField(context, categoryCtrl, 'Catégorie', Icons.folder_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildNeuField(context, urlCtrl, 'Lien du projet', Icons.link_outlined)),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: NeumorphicButton(
                    onTap: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        _showToast('Le titre est requis', isError: true);
                        return;
                      }
                      Navigator.pop(context);
                      final body = {
                        'title': title,
                        'description': descCtrl.text.trim(),
                        'category': categoryCtrl.text.trim(),
                        'project_url': urlCtrl.text.trim(),
                        'keywords': keywordsCtrl.text.trim(),
                        'images': imageUrls,
                      };

                      if (isEdit && existingId != null) {
                        await _api.put('/api/profile/portfolio/$existingId', body: body);
                        _showToast('Projet mis à jour !');
                      } else {
                        await _api.post('/api/profile/portfolio', body: body);
                        _showToast('Projet ajouté !');
                      }
                      _loadProjects();
                    },
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6B7FFF), Color(0xFF5267FF)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isEdit ? 'Enregistrer' : 'Ajouter le Projet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NeuColors.shadowLight(context)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeuField(BuildContext context, TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return NeumorphicContainer(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 8 : 0),
      borderRadius: 14,
      depth: 2,
      isInnerShadow: true,
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: NeuColors.textMuted(context)),
          prefixIcon: Icon(icon, color: LinkyColors.primary, size: 20),
          border: InputBorder.none,
        ),
        style: TextStyle(color: NeuColors.text(context)),
      ),
    );
  }

  Future<void> _deleteProject(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le projet'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce projet ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await _api.delete('/api/profile/portfolio/$id');
    if (res.isSuccess) {
      _showToast('Projet supprimé');
      _loadProjects();
    } else {
      _showToast(res.error ?? 'Erreur', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeuScaffold(
      appBar: NeuAppBar(
        title: 'Mon Portfolio',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NeuIconButton(
              icon: Icons.add_rounded,
              onTap: _addProject,
              size: 38,
              iconColor: LinkyColors.neonGreen,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: LinkyColors.primary))
          : _projects.isEmpty
              ? _buildEmptyState()
              : _buildProjectGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(40),
        borderRadius: 24,
        depth: 4,
        margin: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline, size: 64, color: NeuColors.textMuted(context).withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text('Aucun projet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: NeuColors.text(context))),
            const SizedBox(height: 8),
            Text('Ajoutez vos premiers projets\npour construire votre portfolio', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: NeuColors.textMuted(context))),
            const SizedBox(height: 24),
            NeumorphicButton(
              onTap: _addProject,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: LinkyColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Ajouter un projet', style: TextStyle(fontWeight: FontWeight.bold, color: LinkyColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        final images = project['images'] is List ? List<String>.from((project['images'] as List).map((e) => e.toString())) : <String>[];
        final imageUrl = images.isNotEmpty ? images.first : (project['image_url']?.toString() ?? '');
        final title = project['title']?.toString() ?? 'Sans titre';
        final desc = project['description']?.toString() ?? '';
        final category = project['category']?.toString() ?? '';
        final url = project['project_url']?.toString() ?? '';
        final keywords = (project['keywords']?.toString() ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 22,
            depth: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: NeuColors.iconBg(context),
                        child: Icon(Icons.broken_image_outlined, color: NeuColors.textMuted(context)),
                      ),
                    ),
                  ),
                if (images.length > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length > 5 ? 5 : images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(images[i], width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: NeuColors.iconBg(context), child: Icon(Icons.broken_image_outlined, size: 16, color: NeuColors.textMuted(context))),
                        ),
                      ),
                    ),
                  ),
                ],
                if (imageUrl.isNotEmpty || images.length > 1) const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: NeuColors.text(context))),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        NeuIconButton(
                          icon: Icons.edit_outlined,
                          onTap: () => _editProject(project),
                          size: 34,
                          iconColor: LinkyColors.primary,
                        ),
                        const SizedBox(width: 4),
                        NeuIconButton(
                          icon: Icons.delete_outline,
                          onTap: () => _deleteProject(project['id']?.toString() ?? ''),
                          size: 34,
                          iconColor: LinkyColors.neonCrimson,
                        ),
                      ],
                    ),
                  ],
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: LinkyColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LinkyColors.primary)),
                  ),
                ],
                if (keywords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: keywords.map((kw) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(kw, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6))),
                    )).toList(),
                  ),
                ],
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(desc, style: TextStyle(fontSize: 14, color: NeuColors.textMuted(context), height: 1.5)),
                ],
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        Icon(Icons.link_outlined, size: 16, color: LinkyColors.primary),
                        const SizedBox(width: 6),
                        Text(url, style: TextStyle(fontSize: 13, color: LinkyColors.primary, decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
