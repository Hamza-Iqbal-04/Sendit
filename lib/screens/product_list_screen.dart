import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../themes.dart';
import '../widgets/ProductCard.dart';
import '../widgets/FloatingCartButton.dart';

class ProductListScreen extends StatefulWidget {
  final String title;
  final String searchQuery; // Category Name (e.g., "Winter") or "All"

  const ProductListScreen({
    super.key,
    required this.title,
    required this.searchQuery
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // Selected index for the left sidebar
  int _selectedSidebarIndex = 0;

  // Filter States
  String _sortBy = "Relevance";
  String _selectedBrand = "All";
  bool _showHandpicked = false;
  bool _showBestseller = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  // Filter locally to get accurate count for this screen
                  final count = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (widget.searchQuery != "All" &&
                        data['category'] != widget.searchQuery &&
                        data['subCategory'] != widget.searchQuery &&
                        !(data['searchKeywords'] as List).contains(widget.searchQuery.toLowerCase())) {
                      return false;
                    }
                    return true;
                  }).length;

                  return Text(
                    "$count items",
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w400),
                  );
                }
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. HORIZONTAL FILTER BAR
              _buildFilterBar(),

              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

              // 2. MAIN CONTENT (Sidebar + Grid)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // 1. Process Data
                    List<Product> allProducts = snapshot.data!.docs.map((doc) {
                      return Product.fromMap(doc.data() as Map<String, dynamic>);
                    }).toList();

                    // 2. Filter by Main Category
                    if (widget.searchQuery != "All") {
                      allProducts = allProducts.where((p) {
                        return p.category == widget.searchQuery ||
                            p.subCategory == widget.searchQuery ||
                            p.searchKeywords.contains(widget.searchQuery.toLowerCase());
                      }).toList();
                    }

                    // 3. Extract Sub-Categories Dynamically
                    final Set<String> subs = {};
                    for (var p in allProducts) {
                      if (p.subCategory.isNotEmpty) subs.add(p.subCategory);
                    }
                    final currentSubCategories = ["All", ...subs.toList()];

                    // 4. Filter by Selected Sidebar Item
                    if (_selectedSidebarIndex >= currentSubCategories.length) {
                      _selectedSidebarIndex = 0;
                    }

                    final selectedSubCat = currentSubCategories[_selectedSidebarIndex];
                    var filteredProducts = allProducts;

                    if (selectedSubCat != "All") {
                      filteredProducts = filteredProducts.where((p) => p.subCategory == selectedSubCat).toList();
                    }

                    // 5. Apply Top Filters
                    if (_showHandpicked) {
                      filteredProducts = filteredProducts.where((p) => p.isFeatured).toList();
                    }
                    if (_showBestseller) {
                      filteredProducts = filteredProducts.where((p) => p.isBestSeller).toList();
                    }
                    if (_selectedBrand != "All") {
                      filteredProducts = filteredProducts.where((p) => p.brand == _selectedBrand).toList();
                    }
                    // Implement Sort
                    if (_sortBy == "Price: Low to High") {
                      filteredProducts.sort((a, b) => a.price.compareTo(b.price));
                    } else if (_sortBy == "Price: High to Low") {
                      filteredProducts.sort((a, b) => b.price.compareTo(a.price));
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SIDEBAR
                        _buildSidebar(currentSubCategories),

                        // GRID
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Text
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                                child: Text(
                                  "${filteredProducts.length} items in $selectedSubCat",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.52, // Keep this ratio to prevent overflow
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 12,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    return ProductCard(product: filteredProducts[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating Cart
          const FloatingCartButton(),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildFilterBar() {
    return Container(
      height: 56,
      width: double.infinity,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune, size: 16, color: Colors.black),
          ),
          const SizedBox(width: 8),

          _buildDropdownFilter("Sort By", _sortBy, ["Relevance", "Price: Low to High", "Price: High to Low"], (val) => setState(() => _sortBy = val)),
          const SizedBox(width: 8),
          _buildDropdownFilter("Brand", _selectedBrand, ["All", "Amul", "Nestle", "Britannia"], (val) => setState(() => _selectedBrand = val)),
          const SizedBox(width: 8),
          _buildToggleFilter("Handpicked", Icons.thumb_up_alt, _showHandpicked, () => setState(() => _showHandpicked = !_showHandpicked)),
          const SizedBox(width: 8),
          _buildToggleFilter("Bestseller", Icons.emoji_events, _showBestseller, () => setState(() => _showBestseller = !_showBestseller)),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String currentValue, List<String> options, Function(String) onSelect) {
    return PopupMenuButton<String>(
      onSelected: onSelect,
      itemBuilder: (BuildContext context) {
        return options.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: currentValue != (label == "Sort By" ? "Relevance" : "All") ? const Color(0xFFD32F2F) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: currentValue != (label == "Sort By" ? "Relevance" : "All") ? const Color(0xFFFFF0F0) : Colors.white,
        ),
        child: Row(
          children: [
            Text(currentValue == "Relevance" || currentValue == "All" ? label : currentValue,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: currentValue != (label == "Sort By" ? "Relevance" : "All") ? const Color(0xFFD32F2F) : Colors.black)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: currentValue != (label == "Sort By" ? "Relevance" : "All") ? const Color(0xFFD32F2F) : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleFilter(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? const Color(0xFFD32F2F) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: isActive ? const Color(0xFFFFF0F0) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFFD32F2F) : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? const Color(0xFFD32F2F) : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(List<String> categories) {
    return Container(
      width: 90,
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedSidebarIndex == index;
          String name = categories[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedSidebarIndex = index),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFF5F7FD),
                border: isSelected
                    ? const Border(left: BorderSide(color: Color(0xFFD32F2F), width: 4))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFFFFF0F0) : Colors.white,
                    ),
                    child: Icon(
                      _getIconForSubCat(name),
                      color: isSelected ? const Color(0xFFD32F2F) : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UPDATED ICON LOGIC FOR ALL CATEGORIES ---
  IconData _getIconForSubCat(String name) {
    name = name.toLowerCase();

    // Main Categories
    if (name == 'all') return Icons.grid_view;
    if (name.contains('winter')) return Icons.ac_unit;
    if (name.contains('wedding')) return Icons.volunteer_activism;
    if (name.contains('gourmet')) return Icons.restaurant;
    if (name.contains('electronics')) return Icons.electrical_services;
    if (name.contains('fruits')) return Icons.eco;
    if (name.contains('vegetables')) return Icons.spa;
    if (name.contains('dairy')) return Icons.local_drink;

    // Sub Categories - Winter
    if (name.contains('blanket')) return Icons.bed;
    if (name.contains('heater')) return Icons.wb_sunny;
    if (name.contains('skin')) return Icons.face;
    if (name.contains('food')) return Icons.soup_kitchen;

    // Sub Categories - Wedding
    if (name.contains('gift')) return Icons.card_giftcard;
    if (name.contains('jewel')) return Icons.diamond;
    if (name.contains('decor')) return Icons.celebration;
    if (name.contains('essential')) return Icons.shopping_bag;

    // Sub Categories - Gourmet
    if (name.contains('cheese')) return Icons.breakfast_dining;
    if (name.contains('chocolate')) return Icons.cake;
    if (name.contains('imported')) return Icons.public;

    // Sub Categories - Electronics
    if (name.contains('headphone')) return Icons.headphones;
    if (name.contains('charger')) return Icons.battery_charging_full;

    // Sub Categories - Fruits/Veg/Dairy
    if (name.contains('fresh')) return Icons.eco;
    if (name.contains('exotic')) return Icons.sunny;
    if (name.contains('daily')) return Icons.calendar_today;
    if (name.contains('leafy')) return Icons.grass;
    if (name.contains('milk')) return Icons.local_drink;
    if (name.contains('butter')) return Icons.breakfast_dining;
    if (name.contains('yogurt')) return Icons.icecream;

    // Fallbacks (from your previous list)
    if (name.contains('snack')) return Icons.cookie;
    if (name.contains('bowl')) return Icons.rice_bowl;
    if (name.contains('plate')) return Icons.radio_button_unchecked;
    if (name.contains('jar')) return Icons.kitchen;
    if (name.contains('glass')) return Icons.local_drink;
    if (name.contains('tray')) return Icons.calendar_view_day;

    return Icons.category;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("No products found", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}