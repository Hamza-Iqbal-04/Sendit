import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/product.dart';
import '../providers/AddressProvider.dart';
import '../screens/product_list_screen.dart';
import '../screens/profilescreen.dart';
import '../screens/searchscreen.dart';
import '../widgets/ProductCard.dart';
import '../themes.dart';
import 'AddEditAddressScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE ---
  String _selectedCategoryId = 'all'; // Default to 'all'
  String _selectedCategoryName = 'All'; // Display name

  final Color _defaultBg = const Color(0xFFF5F7FD);
  final Color _defaultHeaderColor = AppTheme.swiggyOrange; // Default Orange

  // Single stream source to avoid multiple network requests/index issues
  late Stream<List<Product>> _allProductsStream;
  int _currentBannerIndex = 0; // For carousel

  @override
  void initState() {
    super.initState();
    _allProductsStream = _fetchAllProducts();
  }

  Stream<List<Product>> _fetchAllProducts() {
    // Fetch a batch of active products and filter in UI to avoid complex composite indexes
    return FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .limit(100) // Fetch enough to populate sections
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList());
  }

  void _navigateToList(String title, String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(title: title, searchQuery: query),
      ),
    );
  }

  // --- HELPER: Map Category Name to Icon ---
  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower == 'all') return Icons.grid_view_rounded;
    if (lower.contains('winter')) return Icons.ac_unit_rounded;
    if (lower.contains('wedding')) return Icons.volunteer_activism_rounded;
    if (lower.contains('gourmet')) return Icons.restaurant_rounded;
    if (lower.contains('electronic')) return Icons.headphones_rounded;
    if (lower.contains('fruit')) return Icons.shopping_bag_outlined;
    if (lower.contains('veg')) return Icons.eco_rounded;
    if (lower.contains('dairy')) return Icons.local_drink_rounded;
    if (lower.contains('bread') || lower.contains('bakery')) return Icons.breakfast_dining_rounded;
    if (lower.contains('egg') || lower.contains('meat')) return Icons.egg_alt_rounded;
    if (lower.contains('snack') || lower.contains('munchies')) return Icons.cookie_rounded;
    if (lower.contains('beauty') || lower.contains('care')) return Icons.face_retouching_natural_rounded;
    if (lower.contains('home') || lower.contains('clean')) return Icons.cleaning_services_rounded;
    return Icons.category_rounded;
  }

  // --- ADDRESS BOTTOM SHEET ---
  void _showAddressBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<AddressProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Select Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Add New Address Button
                      InkWell(
                        onTap: () {
                          Navigator.pop(context); // Close sheet
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditAddressScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.add, color: AppTheme.swiggyOrange),
                              const SizedBox(width: 12),
                              const Text("Add New Address", style: TextStyle(color: AppTheme.swiggyOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),

                      // Address List
                      Expanded(
                        child: provider.addresses.isEmpty
                            ? const Center(child: Text("No addresses saved yet.", style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                          controller: scrollController,
                          itemCount: provider.addresses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final addr = provider.addresses[index];
                            final isSelected = provider.selectedAddress?.id == addr.id;

                            return InkWell(
                              onTap: () {
                                provider.selectAddress(addr);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.swiggyOrange.withOpacity(0.05) : Colors.white,
                                  border: Border.all(
                                      color: isSelected ? AppTheme.swiggyOrange : Colors.grey.shade200,
                                      width: isSelected ? 1.5 : 1
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getIconForLabel(addr.label),
                                      color: isSelected ? AppTheme.swiggyOrange : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            addr.label,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isSelected ? AppTheme.swiggyOrange : Colors.black87
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${addr.street}, ${addr.city}",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: AppTheme.swiggyOrange),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'work': return Icons.work_outline;
      case 'other': return Icons.location_on_outlined;
      default: return Icons.home_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, Map<String, dynamic>> categoriesData = {};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final id = data['id'] ?? doc.id;
            categoriesData[id] = data;
          }
        }

        Color headerColor = _defaultHeaderColor;
        List<dynamic> currentGridItems = [];
        bool isAllTab = _selectedCategoryId == 'all';

        if (!isAllTab && categoriesData.containsKey(_selectedCategoryId)) {
          final selectedData = categoriesData[_selectedCategoryId]!;

          if (selectedData['themeColor'] != null) {
            try {
              if (selectedData['themeColor'] is int) {
                headerColor = Color(selectedData['themeColor']);
              } else if (selectedData['themeColor'] is String) {
                String hex = selectedData['themeColor'];
                hex = hex.replaceAll("#", "");
                if (hex.length == 6) hex = "FF$hex";
                headerColor = Color(int.parse("0x$hex"));
              }
            } catch (e) {
              headerColor = _defaultHeaderColor;
            }
          }

          currentGridItems = selectedData['subCategories'] ?? [];
        } else {
          currentGridItems = categoriesData.values.toList();
        }

        return Scaffold(
          backgroundColor: _defaultBg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. DYNAMIC HEADER SECTION
              SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: headerColor,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIXED: Always pass "8 mins" as title
                      _buildTopHeader(context, "8 mins"),
                      _buildSearchBar(context),
                      _buildCategoryTabs(categoriesData.values.toList(), headerColor),

                      if (isAllTab) ...[
                        _buildSaleBannerText(),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              _selectedCategoryName.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]
                              ),
                            ),
                          ),
                        ),
                      ],

                      _buildDynamicCampaignGrid(
                          items: currentGridItems,
                          isAllTab: isAllTab,
                          themeColor: headerColor
                      ),
                    ],
                  ),
                ),
              ),

              // 2. BODY CONTENT
              SliverToBoxAdapter(
                child: Container(
                  color: _defaultBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Your Go-to Items"),
                      _buildHorizontalProductList(filter: (p) => true),

                      _buildSectionTitle("In the Spotlight"),
                      _buildExploreGrid(),

                      if (isAllTab) ...[
                        const SizedBox(height: 12),
                        _buildPromoCarousel(),
                      ],

                      if (isAllTab) ...[
                        _buildSectionTitle("Shop By Category"),
                        _buildAllCategoriesGrid(categoriesData.values.toList()),
                      ],

                      if (isAllTab) ...[
                        const SizedBox(height: 12),
                        _buildSectionTitle("Best Sellers"),
                        _buildHorizontalProductList(filter: (p) => p.isBestSeller),
                      ],

                      if (isAllTab) ...[
                        const SizedBox(height: 12),
                        _buildSectionTitle("Featured Collections"),
                        _buildHorizontalProductList(filter: (p) => p.isFeatured),
                      ],

                      _buildAdBanner(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildTopHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Consumer<AddressProvider>(
              builder: (context, addrProvider, _) {
                final selected = addrProvider.selectedAddress;
                return GestureDetector(
                  onTap: () => _showAddressBottomSheet(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.0),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        selected != null ? "${selected.label} - ${selected.street}" : "Select Location",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppTheme.swiggyOrange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Search for '${_selectedCategoryId == 'all' ? 'milk' : _selectedCategoryName}'...",
                  style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              const SizedBox(width: 12),
              const Icon(Icons.mic_none, color: AppTheme.swiggyOrange, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> categories, Color activeThemeColor) {
    final allTab = {'id': 'all', 'name': 'All'};
    final displayList = [allTab, ...categories];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: displayList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final cat = displayList[index];
          final id = cat['id'] as String;
          final name = cat['name'] as String;
          final isSelected = _selectedCategoryId == id;
          final iconData = _getCategoryIcon(name);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryId = id;
                _selectedCategoryName = name;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50, width: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                  ),
                  child: Icon(
                    iconData,
                    color: isSelected ? activeThemeColor : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 3, width: 24,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicCampaignGrid({
    required List<dynamic> items,
    required bool isAllTab,
    required Color themeColor
  }) {
    if (items.isEmpty) return const SizedBox(height: 20);

    return Container(
      height: 165,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final String title = item['name'] ?? '';
          final String offer = item['offer'] ?? (isAllTab ? 'EXPLORE' : '');
          final String imageUrl = item['image'] ?? '';

          return _buildCategoryCard(
            title: title,
            offer: offer,
            color: Colors.white,
            textColor: themeColor,
            image: imageUrl,
            onTap: () => _navigateToList(title, title),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String offer,
    required Color color,
    required Color textColor,
    required String image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
            ]
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Text(
                title.replaceAll(" ", "\n"),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: image.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: image,
                  height: 55,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(Icons.shopping_bag_outlined, color: textColor.withOpacity(0.3), size: 40),
                )
                    : Icon(Icons.shopping_bag_outlined, color: textColor.withOpacity(0.3), size: 40),
              ),
            ),
            if (offer.isNotEmpty)
              Positioned(
                bottom: 10, left: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFC6FF00), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                      offer,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCarousel() {
    final List<String> promoImages = [
      "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1550989460-0adf9ea622e2?auto=format&fit=crop&w=800&q=80",
    ];

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: promoImages.length,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(promoImages[index]),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(promoImages.length, (index) =>
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentBannerIndex == index ? 16 : 6,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == index ? AppTheme.swiggyOrange : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              )
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
          TextButton(
              onPressed: () => _navigateToList(title, "All"),
              child: const Text("See All", style: TextStyle(color: AppTheme.swiggyOrange, fontWeight: FontWeight.bold, fontSize: 13))
          ),
        ],
      ),
    );
  }

  Widget _buildSaleBannerText() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            const Text("SENDIT EVERYDAY", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Text("Fresh Groceries & Essentials", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5D1049), Color(0xFF911E6E)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF5D1049).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Text("AD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF5D1049)))),
          const SizedBox(width: 12),
          const Expanded(child: Text("Free delivery on your first order!", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
        ],
      ),
    );
  }

  Widget _buildAdventCalendar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.shade100)),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFF7E0095), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("New arrivals in Dairy", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              const Text("Check out Amul Products >", style: TextStyle(color: Color(0xFF7E0095), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildExploreGrid() {
    final items = [
      {"name": "Organic", "icon": Icons.eco_rounded, "color": Colors.green},
      {"name": "Instant", "icon": Icons.bolt_rounded, "color": Colors.orange},
      {"name": "Gourmet", "icon": Icons.restaurant_menu_rounded, "color": Colors.purple},
      {"name": "Offers", "icon": Icons.local_offer_rounded, "color": Colors.blue},
    ];

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => _navigateToList(item['name'] as String, item['name'] as String),
            child: Column(
              children: [
                Container(
                  height: 50, width: 50,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                ),
                const SizedBox(height: 8),
                Text(item['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllCategoriesGrid(List<dynamic> categories) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        if (cat['id'] == 'all') return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _navigateToList(cat['name'], cat['name']),
          child: Column(
            children: [
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: cat['image'] != null && cat['image'].toString().isNotEmpty
                      ? CachedNetworkImage(imageUrl: cat['image'], fit: BoxFit.contain, height: 40)
                      : Icon(_getCategoryIcon(cat['name']), color: AppTheme.swiggyOrange, size: 30),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cat['name'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
              )
            ],
          ),
        );
      },
    );
  }

  // --- REUSABLE PRODUCT LIST BUILDER ---
  Widget _buildHorizontalProductList({required bool Function(Product) filter}) {
    return StreamBuilder<List<Product>>(
      stream: _allProductsStream, // Use the single broad stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));

        final allProducts = snapshot.data ?? [];
        final filteredProducts = allProducts.where(filter).take(10).toList();

        if (filteredProducts.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 270,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: filteredProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 160,
                // Removed outer GestureDetector as ProductCard now handles the tap
                child: ProductCard(
                    product: filteredProducts[index],
                    heroTag: "home_${filteredProducts[index].id}_$index" // Ensuring uniqueness
                ),
              );
            },
          ),
        );
      },
    );
  }
}