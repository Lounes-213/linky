import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/localization/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _api = ApiService();
  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  String? _currentPhotoUrl;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _currentPhotoUrl = user.photoURL;
    }
    final response = await _api.get('/api/users/me');
    if (response.isSuccess && mounted) {
      final data = response.data;
      _usernameController.text = data?['username']?.toString() ?? '';
      if (data?['name'] != null) _nameController.text = data!['name'].toString();
      if (data?['bio'] != null) _bioController.text = data!['bio'].toString();
      if (data?['phone'] != null) _phoneController.text = data!['phone'].toString();
      if (data?['location'] != null) _locationController.text = data!['location'].toString();
      if (data?['website'] != null) _websiteController.text = data!['website'].toString();
      if (data?['avatar_url'] != null && data!['avatar_url'].toString().isNotEmpty) {
        _currentPhotoUrl = data['avatar_url'].toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: LinkyColors.primary,
                ),
                title: const Text('Caméra'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: LinkyColors.primary,
                ),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = picked;
        _hasChanges = true;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final filename = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await _api.upload(
        '/api/upload',
        bytes,
        filename,
        folder: 'profile',
      );
      if (!response.isSuccess) return null;
      return response.data?['url']?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final photoUrl = await _uploadImage();

      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().replaceFirst(RegExp(r'^@+'), ''),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
      };
      if (photoUrl != null) body['photoUrl'] = photoUrl;

      final response = await _api.put('/api/profile', body: body);

      if (mounted) {
        if (response.isSuccess) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await user.updateDisplayName(_nameController.text.trim());
            if (photoUrl != null && photoUrl != _currentPhotoUrl) {
              await user.updatePhotoURL(photoUrl);
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).save,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: LinkyColors.neonGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            final errorMsg = response.error ??
                response.data?['error']?.toString() ??
                AppLocalizations.of(context).error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
              content: Text(
                errorMsg,
              ),
                backgroundColor: LinkyColors.discount,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).error),
            backgroundColor: LinkyColors.discount,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            _buildTopBar(loc),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  onChanged: _markChanged,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildPhotoPicker(),
                      const SizedBox(height: 32),
                      _buildField(
                        controller: _nameController,
                        icon: Icons.person_outline,
                        label: 'Nom',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _usernameController,
                        icon: Icons.alternate_email,
                        label: 'Nom d\'utilisateur',
                        prefix: '@',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          final clean = v.trim().replaceFirst(RegExp(r'^@+'), '');
                          if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(clean)) {
                            return '3-20 caractères, lettres/chiffres/_';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _bioController,
                        icon: Icons.info_outline,
                        label: 'Bio',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _locationController,
                        icon: Icons.location_on_outlined,
                        label: 'Localisation',
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _websiteController,
                        icon: Icons.language,
                        label: 'Site web',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 32),
                      _buildSaveButton(loc),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: clayCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: clayBorder(context)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: linkyTextPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            loc.editProfile,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (_hasChanges)
            GestureDetector(
              onTap: _isLoading ? null : _saveProfile,
              child: Text(
                loc.save,
                style: const TextStyle(
                  color: LinkyColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: LinkyColors.primary, width: 3),
            ),
            child: _selectedImage != null
                ? _XFileCircleAvatar(xfile: _selectedImage!, radius: 52)
                : CircleAvatar(
                    radius: 52,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                        ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                        : null,
                    child: (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                        ? Icon(Icons.person, size: 52,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))
                        : null,
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: LinkyColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: clayCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: clayBorder(context)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              Icon(
                icon,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                size: 22,
              ),
              if (prefix != null)
                Text(
                  prefix,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(width: 4),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: clayBorder(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: clayBorder(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: clayPrimary(context), width: 1.5),
          ),
          filled: true,
          fillColor: clayCard(context),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations loc) {
    return GestureDetector(
      onTap: _isLoading ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LinkyColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                loc.save,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

/// Cross-platform CircleAvatar from XFile (works on web + mobile)
class _XFileCircleAvatar extends StatefulWidget {
  final XFile xfile;
  final double radius;
  const _XFileCircleAvatar({required this.xfile, required this.radius});

  @override
  State<_XFileCircleAvatar> createState() => _XFileCircleAvatarState();
}

class _XFileCircleAvatarState extends State<_XFileCircleAvatar> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.xfile.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (_, snap) {
        if (snap.hasData) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundImage: MemoryImage(snap.data!),
          );
        }
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }
}
