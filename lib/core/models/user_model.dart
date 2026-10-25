class UserModel {
  final String id;
  final String? firebaseUid;
  final String email;
  final String name;
  final String? username;
  final String bio;
  final String? avatarUrl;
  final String? phone;
  final String? location;
  final String? website;
  final bool isVerified;
  final DateTime? createdAt;
  final List<SocialLinkModel>? socialLinks;
  final List<AddressModel>? addresses;

  UserModel({
    required this.id,
    this.firebaseUid,
    required this.email,
    required this.name,
    this.username,
    this.bio = '',
    this.avatarUrl,
    this.phone,
    this.location,
    this.website,
    this.isVerified = false,
    this.createdAt,
    this.socialLinks,
    this.addresses,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firebaseUid: json['firebase_uid'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      username: json['username'],
      bio: json['bio'] ?? '',
      avatarUrl: json['avatar_url'],
      phone: json['phone'],
      location: json['location'],
      website: json['website'],
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      socialLinks: json['social_links'] != null
          ? (json['social_links'] as List).map((e) => SocialLinkModel.fromJson(e)).toList()
          : null,
      addresses: json['addresses'] != null
          ? (json['addresses'] as List).map((e) => AddressModel.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'username': username,
    'bio': bio,
    'avatar_url': avatarUrl,
    'phone': phone,
    'location': location,
    'website': website,
  };
}

class SocialLinkModel {
  final String id;
  final String platform;
  final String username;
  final String? url;
  final bool isActive;

  SocialLinkModel({
    required this.id,
    required this.platform,
    required this.username,
    this.url,
    this.isActive = true,
  });

  factory SocialLinkModel.fromJson(Map<String, dynamic> json) {
    return SocialLinkModel(
      id: json['id'] ?? '',
      platform: json['platform'] ?? '',
      username: json['username'] ?? '',
      url: json['url'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class AddressModel {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String country;
  final String? postalCode;
  final String? phone;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.country = 'DZ',
    this.postalCode,
    this.phone,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Home',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      state: json['state'],
      country: json['country'] ?? 'DZ',
      postalCode: json['postal_code'],
      phone: json['phone'],
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
    );
  }
}
