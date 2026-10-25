import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ApiService();
    final res = await api.get(AppConstants.ordersBase);

    if (res.isSuccess && res.data != null) {
      final List<dynamic> items = res.data!['orders'] ?? res.data!['data'] ?? [];
      setState(() {
        _orders = items.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = res.error ?? 'Erreur lors du chargement';
      });
    }
  }

  List<Map<String, dynamic>> _filteredOrders(String status) {
    if (status == 'all') return _orders;
    return _orders.where((o) => o['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: LinkyColors.primary))
                  : _error != null
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrderList(_filteredOrders('all')),
                            _buildOrderList(_filteredOrders('pending')),
                            _buildOrderList(_filteredOrders('delivered')),
                            _buildOrderList(_filteredOrders('cancelled')),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final loc = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: clayCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: clayBorder(context)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
          ),
          const Spacer(),
          Text(
            loc.orderHistory,
            style: TextStyle(
              color: onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        indicator: BoxDecoration(
          color: clayPrimary(context),
          borderRadius: BorderRadius.circular(20),
        ),
        tabs: [
          Tab(text: loc.allNotifications),
          Tab(text: loc.orders),
          Tab(text: loc.done),
          Tab(text: loc.cancel),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: clayPrimary(context),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final loc = AppLocalizations.of(context);
    final status = order['status'] ?? 'pending';
    final statusInfo = _getStatusInfo(status, loc);

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: clayCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: clayBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                   loc.orderNumber.replaceFirst('{number}', '${order['order_number'] ?? order['id'] ?? '---'}'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusInfo['label'],
                    style: TextStyle(
                      color: statusInfo['color'],
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.store_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  order['store_name'] ?? order['store'] ?? 'N/A',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                ),
                const Spacer(),
                Icon(Icons.shopping_bag_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  loc.itemsCount.replaceFirst('{count}', '${(order['items'] as List?)?.length ?? 0}'),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order['created_at']),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12),
                ),
                Text(
                  '${(order['total'] ?? 0).toInt()} DA',
                  style: const TextStyle(
                    color: LinkyColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status, AppLocalizations loc) {
    switch (status) {
      case 'delivered':
        return {'label': loc.delivered, 'color': LinkyColors.accent};
      case 'cancelled':
        return {'label': loc.cancelled, 'color': LinkyColors.discount};
      case 'shipped':
        return {'label': loc.shipped, 'color': LinkyColors.primary};
      case 'preparing':
        return {'label': loc.preparing, 'color': LinkyColors.star};
      case 'confirmed':
        return {'label': loc.confirmed, 'color': LinkyColors.primaryLight};
      default:
        return {'label': loc.pending, 'color': Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)};
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '--/--/----';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final loc = AppLocalizations.of(context);
    final statusInfo = _getStatusInfo(order['status'] ?? 'pending', loc);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.orderHistory,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(loc.orderNumberLabel, '#${order['order_number'] ?? order['id'] ?? '---'}'),
              _buildDetailRow(loc.date, _formatDate(order['created_at'])),
              _buildDetailRow(loc.store, order['store_name'] ?? order['store'] ?? loc.noData),
              _buildDetailRow(loc.status, statusInfo['label']),
              _buildDetailRow(loc.items, '${(order['items'] as List?)?.length ?? 0}'),
              _buildDetailRow(loc.total, '${(order['total'] ?? 0).toInt()} DA'),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: clayPrimary(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  loc.close,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
          Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: clayCard(context),
              shape: BoxShape.circle,
              border: Border.all(color: clayBorder(context)),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 60, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            loc.noData,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.ordersAppearHere,
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
            onTap: _loadOrders,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: clayPrimary(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(loc.retry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
