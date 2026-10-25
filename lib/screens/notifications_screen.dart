import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ApiService();
    final res = await api.get(AppConstants.notificationsBase);

    if (res.isSuccess && res.data != null) {
      final List<dynamic> items = res.data!['notifications'] ?? res.data!['data'] ?? [];
      setState(() {
        _notifications = items.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = res.error ?? 'Erreur lors du chargement';
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    final api = ApiService();
    await api.put('${AppConstants.notificationsBase}/$id/read');
    setState(() {
      final idx = _notifications.indexWhere((n) => n['id'] == id);
      if (idx != -1) _notifications[idx]['is_read'] = true;
    });
  }

  Future<void> _markAllRead() async {
    final api = ApiService();
    await api.put('${AppConstants.notificationsBase}/read-all');
    setState(() {
      for (final n in _notifications) {
        n['is_read'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      appBar: ClayAppBar(
        title: loc.notifications,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              loc.markAllRead,
              style: TextStyle(color: clayPrimary(context), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: clayPrimary(context)))
          : _error != null
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  :                     RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: clayPrimary(context),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) => _buildNotificationItem(_notifications[index]),
                      ),
                    ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final loc = AppLocalizations.of(context);
    final bool isRead = notification['is_read'] == true;
    final String type = notification['type'] ?? 'info';
    final IconData icon = _getIconForType(type);
    final Color iconColor = _getColorForType(type);

    return GestureDetector(
      onTap: () {
        if (!isRead) _markAsRead(notification['id'] ?? '');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRead ? Theme.of(context).colorScheme.surface : clayPrimary(context).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Theme.of(context).dividerColor.withValues(alpha: 0.5) : clayPrimary(context).withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Neumorphism.circle(
              size: 44,
              context: context,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] ?? '',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['body'] ?? notification['message'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification['created_at'], loc),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 6),
                decoration: BoxDecoration(
                  color: LinkyColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'order':
      case 'new_order':
      case 'order_update':
        return Icons.shopping_bag_outlined;
      case 'promo':
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'follow':
      case 'social':
        return Icons.person_add_outlined;
      case 'like':
        return Icons.favorite_outline;
      case 'review':
        return Icons.star_outline;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'payment':
        return Icons.payment_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'order':
      case 'new_order':
      case 'order_update':
      case 'shipping':
        return LinkyColors.primary;
      case 'promo':
      case 'promotion':
        return LinkyColors.discount;
      case 'follow':
      case 'social':
        return LinkyColors.accent;
      case 'like':
        return LinkyColors.discount;
      case 'review':
        return LinkyColors.star;
      case 'payment':
        return LinkyColors.accent;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  String _timeAgo(dynamic date, AppLocalizations loc) {
    if (date == null) return '';
    try {
      final DateTime then = DateTime.parse(date.toString());
      final diff = DateTime.now().difference(then);
      if (diff.inMinutes < 1) return loc.justNow;
      if (diff.inMinutes < 60) return '${diff.inMinutes}${loc.minUnit}';
      if (diff.inHours < 24) return '${diff.inHours}${loc.hourUnit}';
      if (diff.inDays < 7) return '${diff.inDays}${loc.dayUnit}';
      return '${(diff.inDays / 7).floor()}${loc.weekUnit}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildEmptyState() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Neumorphism.light(
            borderRadius: 30,
            context: context,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Icon(Icons.notifications_none, size: 60, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.noNotifications,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.notificationsEmptySubtitle,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: LinkyColors.discount),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadNotifications,
            child: Neumorphism.button(
              borderRadius: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(loc.retry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
