class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String shopName;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.shopName,
    this.rating = 4.5,
  });
}
