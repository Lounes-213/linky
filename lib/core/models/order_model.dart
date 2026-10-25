class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final double subtotal;
  final double shippingCost;
  final double discount;
  final double total;
  final String currency;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? notes;
  final DateTime? createdAt;
  final List<OrderStoreModel>? stores;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.subtotal,
    this.shippingCost = 0,
    this.discount = 0,
    required this.total,
    this.currency = 'DA',
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.paymentMethod,
    this.notes,
    this.createdAt,
    this.stores,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      shippingCost: (json['shipping_cost'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'DA',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      stores: json['stores'] != null
          ? (json['stores'] as List).map((e) => OrderStoreModel.fromJson(e)).toList()
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'Préparation';
      case 'shipped': return 'Expédiée';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }
}

class OrderStoreModel {
  final String id;
  final String orderId;
  final String storeId;
  final double subtotal;
  final String status;
  final String shippingStatus;
  final String? trackingNumber;
  final String? storeName;
  final String? storeLogo;
  final List<OrderItemModel>? items;

  OrderStoreModel({
    required this.id,
    required this.orderId,
    required this.storeId,
    required this.subtotal,
    this.status = 'pending',
    this.shippingStatus = 'pending',
    this.trackingNumber,
    this.storeName,
    this.storeLogo,
    this.items,
  });

  factory OrderStoreModel.fromJson(Map<String, dynamic> json) {
    return OrderStoreModel(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      storeId: json['store_id'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      shippingStatus: json['shipping_status'] ?? 'pending',
      trackingNumber: json['tracking_number'],
      storeName: json['store_name'],
      storeLogo: json['store_logo'],
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItemModel.fromJson(e)).toList()
          : null,
    );
  }
}

class OrderItemModel {
  final String id;
  final String orderStoreId;
  final String productId;
  final String? variantId;
  final String productName;
  final String productImage;
  final String? variantName;
  final int quantity;
  final double price;
  final double total;

  OrderItemModel({
    required this.id,
    required this.orderStoreId,
    required this.productId,
    this.variantId,
    required this.productName,
    this.productImage = '',
    this.variantName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      orderStoreId: json['order_store_id'] ?? '',
      productId: json['product_id'] ?? '',
      variantId: json['variant_id'],
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      variantName: json['variant_name'],
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class CartItemModel {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String storeName;
  final String storeId;
  final List<String> images;
  final double price;
  final int quantity;
  final String? color;
  final String? size;

  CartItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.storeName,
    required this.storeId,
    this.images = const [],
    required this.price,
    this.quantity = 1,
    this.color,
    this.size,
  });

  double get total => price * quantity;
  String get primaryImage => images.isNotEmpty ? images.first : '';

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      variantId: json['variant_id'],
      productName: json['product_name'] ?? '',
      storeName: json['store_name'] ?? '',
      storeId: json['store_id'] ?? '',
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      color: json['color'],
      size: json['size'],
    );
  }
}
