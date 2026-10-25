import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../core/shared_ui.dart';
import '../core/theme.dart';
import '../core/localization/app_localizations.dart';
import '../main.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: ClayAppBar(title: loc.settings),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(context, loc.appearance),
          const SizedBox(height: 12),
          _buildSettingTile(
            context,
            icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: loc.darkMode,
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
              activeColor: LinkyColors.neonGreen,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            context,
            icon: Icons.language,
            title: loc.language,
            onTap: () => _showLanguageSheet(context),
          ),
          const SizedBox(height: 30),
          _buildSectionTitle(context, loc.account),
          const SizedBox(height: 12),
          _buildSettingTile(
            context,
            icon: Icons.person_outline,
            title: loc.editProfile,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.notifications_none,
            title: loc.notifications,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.lock_outline,
            title: loc.security,
          ),
          const SizedBox(height: 30),
          _buildSectionTitle(context, loc.others),
          const SizedBox(height: 12),
          _buildSettingTile(
            context,
            icon: Icons.help_outline,
            title: loc.helpSupport,
          ),
          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: loc.about,
          ),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text(
                loc.logout,
                style: const TextStyle(
                  color: LinkyColors.neonCrimson,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final locProvider = Provider.of<LocaleProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentLocale = locProvider.locale;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                ctx,
                'Français',
                const Locale('fr'),
                currentLocale,
                () {
                  locProvider.setLocale(const Locale('fr'));
                  setModalState(() {});
                },
              ),
              _buildLanguageOption(
                ctx,
                'English',
                const Locale('en'),
                currentLocale,
                () {
                  locProvider.setLocale(const Locale('en'));
                  setModalState(() {});
                },
              ),
              _buildLanguageOption(
                ctx,
                'العربية',
                const Locale('ar'),
                currentLocale,
                () {
                  locProvider.setLocale(const Locale('ar'));
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext ctx,
    String name,
    Locale locale,
    Locale currentLocale,
    VoidCallback onTap,
  ) {
    final isSelected = currentLocale.languageCode == locale.languageCode;
    return ListTile(
      title: Text(name),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: clayPrimary(ctx), size: 22)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: clayTextMuted(context),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0x33000000)
                  : const Color(0x336C63FF),
              blurRadius: 12,
              offset: const Offset(3, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: clayText(context)),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: clayText(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: clayTextMuted(context),
                ),
          ],
        ),
      ),
    );
  }
}
