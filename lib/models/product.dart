import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String brand;
  final double price;
  final double mrp;
  final double discount;
  final String unit;
  final String unitText;
  final List<String> images;
  final String thumbnail;
  final ProductStock stock;
  final String category;
  final String categoryId;
  final String subCategory; // NEW FIELD
  final bool isFeatured;
  final bool isBestSeller;
  final ProductRatings ratings;
  final int soldCount;
  final List<Map<String, dynamic>> variants;
  final ProductAttributes attributes;
  final List<String> searchKeywords;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.brand,
    required this.price,
    required this.mrp,
    required this.discount,
    required this.unit,
    required this.unitText,
    required this.images,
    required this.thumbnail,
    required this.stock,
    required this.category,
    required this.categoryId,
    this.subCategory = '', // Default empty
    required this.isFeatured,
    required this.isBestSeller,
    required this.ratings,
    required this.soldCount,
    required this.variants,
    required this.attributes,
    required this.searchKeywords,
    required this.tags,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    // 1. Parse images list first so we can use it as a fallback
    List<String> parsedImages = List<String>.from(map['images'] ?? []);

    // 2. Robust Thumbnail Logic:
    // Check fields in order of priority. Ignore null AND empty strings.
    String? thumb = map['thumbnail'];
    if (thumb == null || thumb.isEmpty) {
      thumb = map['imageUrl'];
    }
    if (thumb == null || thumb.isEmpty) {
      thumb = map['image'];
    }
    // Fallback: If still empty, use the first image from the list
    if ((thumb == null || thumb.isEmpty) && parsedImages.isNotEmpty) {
      thumb = parsedImages.first;
    }

    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      brand: map['brand'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      unitText: map['unitText'] ?? '',
      images: parsedImages,
      // FIX: Use the robust thumb calculated above
      thumbnail: thumb ?? '',
      stock: ProductStock.fromMap(map['stock'] ?? {}),
      category: map['category']?['name']?.toString() ?? '',
      categoryId: map['category']?['id']?.toString() ?? '',
      subCategory: map['subCategory'] ?? '', // Map from DB
      isFeatured: map['isFeatured'] ?? false,
      isBestSeller: map['isBestSeller'] ?? false,
      ratings: ProductRatings.fromMap(map['ratings'] ?? {}),
      soldCount: map['soldCount'] ?? 0,
      variants: List<Map<String, dynamic>>.from(map['variants'] ?? []),
      attributes: ProductAttributes.fromMap(map['attributes'] ?? {}),
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

class ProductStock {
  final int availableQty;
  final bool isAvailable;
  final bool lowStock;
  final DateTime lastUpdated;

  ProductStock({
    required this.availableQty,
    required this.isAvailable,
    required this.lowStock,
    required this.lastUpdated,
  });

  factory ProductStock.fromMap(Map<String, dynamic> map) {
    return ProductStock(
      availableQty: map['availableQty'] ?? 0,
      isAvailable: map['isAvailable'] ?? false,
      lowStock: map['lowStock'] ?? false,
      // FIX: Use a fixed epoch time instead of DateTime.now() to prevent URL flickering
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ProductRatings {
  final double average;
  final int count;

  ProductRatings({
    required this.average,
    required this.count,
  });

  factory ProductRatings.fromMap(Map<String, dynamic> map) {
    return ProductRatings(
      average: (map['average'] as num?)?.toDouble() ?? 0.0,
      count: map['count'] ?? 0,
    );
  }
}

class ProductAttributes {
  final int weight;
  final String weightUnit;
  final bool vegetarian;
  final bool organic;
  final List<String> allergens;
  final bool perishable;
  final int minOrder;
  final int maxOrder;

  ProductAttributes({
    required this.weight,
    required this.weightUnit,
    required this.vegetarian,
    required this.organic,
    required this.allergens,
    required this.perishable,
    required this.minOrder,
    required this.maxOrder,
  });

  factory ProductAttributes.fromMap(Map<String, dynamic> map) {
    return ProductAttributes(
      weight: map['weight'] ?? 0,
      weightUnit: map['weightUnit'] ?? 'g',
      vegetarian: map['vegetarian'] ?? true,
      organic: map['organic'] ?? false,
      allergens: List<String>.from(map['allergens'] ?? []),
      perishable: map['perishable'] ?? false,
      minOrder: map['minOrder'] ?? 1,
      maxOrder: map['maxOrder'] ?? 10,
    );
  }
}

class UserAddress {
  final String id;
  final String label;
  final String fullName;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    this.isDefault = false,
  });

  factory UserAddress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAddress(
      id: doc.id,
      label: data['label'] ?? 'Home',
      fullName: data['fullName'] ?? '',
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      phone: data['phone'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'fullName': fullName,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'isDefault': isDefault,
    };
  }
}