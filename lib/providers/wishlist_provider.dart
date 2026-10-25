import 'package:flutter/foundation.dart';
import '../core/api/api_service.dart';
import '../core/constants/app_constants.dart';

class WishlistProvider with ChangeNotifier {
  final Set<String> _productIds = {};
  final List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  Set<String> get productIds => Set.from(_productIds);
  List<Map<String, dynamic>> get products => List.from(_products);
  bool get isLoading => _isLoading;

  bool isWishlisted(String productId) => _productIds.contains(productId);

  Map<String, dynamic>? getProductById(String id) {
    for (final p in _products) {
      if (p['product_id'].toString() == id) return p;
    }
    return null;
  }

  Future<void> toggle(String productId) async {
    final api = ApiService();
    final wasWishlisted = _productIds.contains(productId);

    if (wasWishlisted) {
      _productIds.remove(productId);
      _products.removeWhere((p) => p['product_id'].toString() == productId);
      notifyListeners();
      final res = await api.delete('${AppConstants.wishlistBase}/$productId');
      if (!res.isSuccess) {
        _productIds.add(productId);
        notifyListeners();
      }
    } else {
      _productIds.add(productId);
      notifyListeners();
      final res = await api.post(
        AppConstants.wishlistBase,
        body: {'product_id': productId},
      );
      if (!res.isSuccess) {
        _productIds.remove(productId);
        notifyListeners();
      }
    }
  }

  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    final api = ApiService();
    final res = await api.get(AppConstants.wishlistBase);

    if (res.isSuccess && res.data != null) {
      final List<dynamic> items = res.data!['items'] ?? res.data!['data'] ?? [];
      _productIds.clear();
      _products.clear();
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final id = (item['product_id'] ?? '').toString();
          if (id.isNotEmpty) {
            _productIds.add(id);
            _products.add(item);
          }
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
