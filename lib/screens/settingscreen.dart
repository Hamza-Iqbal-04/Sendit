import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isWorking = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _rand = Random();

  // --- CONFIGURATION FOR INSTAMART-LIKE DATA ---

  // This map matches the Tabs and Sub-Categories in your new Home Screen
  final Map<String, List<String>> _categoryStructure = {
    'Winter': ['Blankets', 'Heaters', 'Skin Care', 'Winter Food'],
    'Wedding': ['Gifting', 'Jewellery', 'Decor', 'Essentials'],
    'Gourmet': ['Cheese', 'Chocolates', 'Imported'],
    'Electronics': ['Headphones', 'Chargers'],
    'Fruits': ['Fresh Fruits', 'Exotic Fruits'],
    'Vegetables': ['Daily Veggies', 'Leafy Greens'],
    'Dairy': ['Milk', 'Cheese & Butter', 'Yogurt'],
  };

  // Specific Theme Colors for Categories (Instamart Style)
  final Map<String, int> _categoryColors = {
    'Winter': 0xFF64B5F6, // Blue
    'Wedding': 0xFFB71C1C, // Red
    'Gourmet': 0xFFF57F17, // Gold
    'Electronics': 0xFF455A64, // Blue Grey
    'Fruits': 0xFF2E7D32, // Green
    'Vegetables': 0xFF43A047, // Light Green
    'Dairy': 0xFF1976D2, // Blue
  };

  final List<String> _brands = [
    'Nestle', 'Amul', 'Britannia', 'Tata', 'Parle', 'Nivea', 'Philips', 'Sony', 'Cadbury'
  ];

  final List<String> _imagePlaceholders = [
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1604719312566-b7cb04464528?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1550989460-0adf9ea622e2?auto=format&fit=crop&w=400&q=80',
  ];

  final List<String> _suppliers = [
    'Fresh Farms', 'Mega Distributors', 'Local Wholesale', 'Direct Imports'
  ];

  // --- GENERATOR LOGIC ---

  Future<void> _generateSpecificProducts() async {
    setState(() => _isWorking = true);
    final WriteBatch batch = _db.batch();
    final now = Timestamp.now();
    int globalCounter = 0;

    try {
      // Loop through our specific Categories
      for (var entry in _categoryStructure.entries) {
        String categoryName = entry.key;
        List<String> subCategories = entry.value;
        String categoryId = categoryName.toLowerCase();

        // --- 1. CREATE CATEGORY DOCUMENT ---
        // This explicitly populates the 'categories' collection
        final categoryDocRef = _db.collection('categories').doc(categoryId);
        final Map<String, dynamic> categoryData = {
          'id': categoryId,
          'name': categoryName,
          'themeColor': _categoryColors[categoryName] ?? 0xFF7E0095, // Default Purple
          'image': _imagePlaceholders[_rand.nextInt(_imagePlaceholders.length)], // Placeholder icon
          'subCategories': subCategories.map((sub) => {
            'name': sub,
            'image': _imagePlaceholders[_rand.nextInt(_imagePlaceholders.length)], // Placeholder for sub-cat card
            'offer': 'UP TO ${10 + _rand.nextInt(50)}% OFF'
          }).toList(),
          'isActive': true,
          'createdAt': now,
        };
        batch.set(categoryDocRef, categoryData);


        // Loop through Sub-Categories (e.g., "Heaters") to create PRODUCTS
        for (String subCat in subCategories) {

          // Create 2-3 products per sub-category to ensure coverage without excessive data
          int productsCount = 2 + _rand.nextInt(2);

          for (int i = 0; i < productsCount; i++) {
            globalCounter++;
            final String productId = "PROD-${globalCounter.toString().padLeft(5, '0')}";
            final productDocRef = _db.collection('products').doc(productId);
            final inventoryDocRef = _db.collection('inventory').doc();

            final String productName = _makeProductName(subCat, i);
            final double mrp = (50 + _rand.nextInt(2000)).toDouble();
            final double price = (mrp * 0.8).floorToDouble();
            final String unit = _pickUnit(categoryName);
            final int initialQty = 50 + _rand.nextInt(100);

            // --- 2. PRODUCT DOCUMENT ---
            final Map<String, dynamic> productDoc = {
              'id': productId,
              'name': productName,
              'description': 'Premium $productName for your needs.',
              'brand': _brands[_rand.nextInt(_brands.length)],
              'category': {
                'id': categoryId,
                'name': categoryName,
              },
              'subCategory': subCat,
              'images': [_imagePlaceholders[_rand.nextInt(_imagePlaceholders.length)]],
              'thumbnail': _imagePlaceholders[_rand.nextInt(_imagePlaceholders.length)],
              'price': price,
              'mrp': mrp,
              'discount': ((mrp - price) / mrp * 100),
              'unit': unit,
              'unitText': '1 $unit',
              'stock': {
                'availableQty': initialQty,
                'isAvailable': true,
                'lowStock': false,
                'lastUpdated': now,
              },
              'variants': [],
              'attributes': {
                'weight': 500,
                'weightUnit': 'g',
                'vegetarian': true,
                'organic': false,
                'allergens': [],
                'perishable': false,
                'minOrder': 1,
                'maxOrder': 5,
              },
              'isActive': true,
              'isFeatured': _rand.nextBool(), // Randomly featured for "Popular" filter
              'isBestSeller': _rand.nextBool(), // Randomly bestseller
              'ratings': {
                'average': 3.0 + _rand.nextDouble() * 2.0, // Random rating 3.0-5.0
                'count': 10 + _rand.nextInt(500),
              },
              'soldCount': _rand.nextInt(1000),
              'searchKeywords': [categoryName.toLowerCase(), subCat.toLowerCase(), productName.toLowerCase()],
              'tags': [categoryName, subCat],
              'createdAt': now, // For "New Arrivals" filter
              'updatedAt': now,
            };

            batch.set(productDocRef, productDoc);

            // --- 3. INVENTORY DOCUMENT ---
            final Map<String, dynamic> inventoryDoc = {
              'inventoryId': inventoryDocRef.id,
              'productId': productId,
              'productName': productName,
              'sku': 'SKU-${productId.split('-').last}',
              'batch': {
                'batchId': 'BATCH-${DateTime.now().millisecondsSinceEpoch}-${_rand.nextInt(1000)}',
                'batchNumber': 'B${(i+1).toString().padLeft(3, '0')}',
                'supplierBatch': 'SUP-${_rand.nextInt(10000)}',
                'manufactureDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: _rand.nextInt(30)))),
                'expiryDate': null,
                'daysToExpiry': null,
              },
              'stock': {
                'initialQty': initialQty,
                'currentQty': initialQty,
                'reservedQty': 0,
                'availableQty': initialQty,
                'damagedQty': 0,
                'returnedQty': 0,
                'unit': unit,
                'location': {
                  'aisle': ['A', 'B', 'C'][_rand.nextInt(3)],
                  'rack': 'R${_rand.nextInt(10) + 1}',
                  'shelf': 'S${_rand.nextInt(5) + 1}',
                  'bin': 'B${_rand.nextInt(20) + 1}',
                },
              },
              'purchase': {
                'supplierId': 'SUP-${_rand.nextInt(10) + 1}',
                'supplierName': _suppliers[_rand.nextInt(_suppliers.length)],
                'purchasePrice': double.parse((price * 0.6).toStringAsFixed(2)),
                'purchaseDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: _rand.nextInt(30)))),
                'invoiceNumber': 'INV-${DateTime.now().millisecondsSinceEpoch}',
                'taxPercent': 18,
              },
              'status': {
                'isActive': true,
                'isExpired': false,
                'qualityCheck': 'approved',
                'holdReason': null,
              },
              'reorder': {
                'reorderPoint': 10 + _rand.nextInt(30),
                'reorderQty': 50 + _rand.nextInt(150),
                'leadTimeDays': 1 + _rand.nextInt(7),
                'lastReorderDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: _rand.nextInt(30)))),
                'nextReorderDate': null,
              },
              'createdAt': now,
              'updatedAt': now,
            };

            batch.set(inventoryDocRef, inventoryDoc);
          }
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generated $globalCounter products & inventory records successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isWorking = false);
    }
  }

  String _makeProductName(String subCat, int index) {
    List<String> adjectives = ['Premium', 'Classic', 'Royal', 'Everyday', 'Super'];
    String adj = adjectives[_rand.nextInt(adjectives.length)];
    return "$adj $subCat ${index + 1}";
  }

  String _pickUnit(String category) {
    switch (category) {
      case 'Fruits':
      case 'Vegetables':
        return 'kg';
      case 'Dairy':
        return 'L';
      case 'Electronics':
      case 'Winter':
      case 'Wedding':
        return 'pcs';
      case 'Gourmet':
        return 'pack';
      default:
        return 'unit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Data Generator",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "This will generate Categories, Products, and Inventory matching the new 'Winter/Wedding' UI flow.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isWorking ? null : _generateSpecificProducts,
                icon: _isWorking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload),
                label: const Text("Generate Full Instamart Data"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}