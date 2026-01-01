import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../themes.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import Firestore for recommended products
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String? heroTag; // Changed from heroSuffix to heroTag for direct control

  const ProductCard({
    super.key,
    required this.product,
    this.heroTag,
  });

  // --- SHOW PRODUCT DETAILS ---
  void _showProductDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Use DraggableScrollableSheet for flexible height
        return DraggableScrollableSheet(
          initialChildSize: 0.9, // Almost full screen initially
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            // Using the internal ProductDetailsSheet widget
            return ProductDetailsSheet(
                product: product,
                scrollController: scrollController
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the passed tag directly, or fallback to product.id.
    // If duplicates exist in the list, the caller MUST provide a unique heroTag (e.g. "$id-$index").
    final String tag = heroTag ?? product.id;
    final isOutOfStock = product.stock.availableQty <= 0;

    // CACHE BUSTER
    String imageUrl = product.thumbnail;
    if (imageUrl.isNotEmpty) {
      final separator = imageUrl.contains('?') ? '&' : '?';
      imageUrl += "${separator}v=${product.stock.lastUpdated.millisecondsSinceEpoch}";
    }

    return GestureDetector(
      onTap: () => _showProductDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    // Only wrap in Hero if tag is valid.
                    // Ideally, ensure tag is unique across the entire screen.
                    child: Hero(
                      tag: tag,
                      child: _buildImage(imageUrl),
                    ),
                  ),
                ),

                // Discount Tag
                if (!isOutOfStock && product.discount > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.swiggyOrange,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomRight: Radius.circular(8)),
                      ),
                      child: Text(
                        "${product.discount.toInt()}% OFF",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                // Time Badge
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 10, color: Colors.grey.shade700),
                        const SizedBox(width: 2),
                        Text("12 mins", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                      ],
                    ),
                  ),
                ),

                // (+) Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: isOutOfStock
                      ? _buildOutOfStockBadge()
                      : Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      final qty = cart.items.containsKey(product.id) ? cart.items[product.id]!.quantity : 0;
                      return qty == 0
                          ? _buildAddIcon(context, cart)
                          : _buildQtyControl(context, cart, qty, product.id, product.stock.availableQty);
                    },
                  ),
                ),
              ],
            ),

            // CONTENT SECTION
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Name, Unit, Ratings (Wrapped in Expanded + SingleChildScrollView to prevent overflow)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(), // Disable user scrolling, just for layout safety
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Name
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2, color: Color(0xFF1C1C1C)),
                            ),
                            const SizedBox(height: 4),
                            // Unit
                            Text(
                              product.unitText,
                              style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            // Rating Badge
                            if (product.ratings.count > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green.shade100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 10, color: Colors.green),
                                    const SizedBox(width: 2),
                                    Text(
                                      product.ratings.average.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "(${product.ratings.count})",
                                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4), // Small gap before price

                    // PRICE (Fixed at bottom)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.discount > 0)
                          Text(
                            "₹${product.mrp.toInt()}",
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        Text(
                          "₹${product.price.toInt()}",
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1C1C1C)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return imageUrl.isEmpty
        ? const Icon(Icons.image_not_supported, color: Colors.grey)
        : CachedNetworkImage(
      key: ValueKey(imageUrl),
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => Center(
        child: Container(
            width: 20,
            height: 20,
            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)
        ),
      ),
      errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildOutOfStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text("OOS", style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAddIcon(BuildContext context, CartProvider cart) {
    return GestureDetector(
      onTap: () => cart.addItem(product),
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.qcGreen),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: const Icon(Icons.add, color: AppTheme.qcGreen, size: 20),
      ),
    );
  }

  Widget _buildQtyControl(BuildContext context, CartProvider cart, int qty, String productId, int maxStock) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.qcGreen,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => cart.removeItem(productId),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              "$qty",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (qty < maxStock) cart.addItem(product);
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailsSheet extends StatelessWidget {
  final Product product;
  final ScrollController? scrollController;

  const ProductDetailsSheet({super.key, required this.product, this.scrollController});

  @override
  Widget build(BuildContext context) {
    // To fix "Multiple heroes share same tag" error:
    // We REMOVE the Hero widget from the detail sheet's image.
    // The animation isn't worth the crash if tags aren't perfectly unique in the source list.

    final isOutOfStock = product.stock.availableQty <= 0;
    final isLowStock = product.stock.lowStock && !isOutOfStock;

    return Stack(
      children: [
        CustomScrollView(
          controller: scrollController,
          slivers: [
            // 1. IMAGE CAROUSEL (No Hero)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: product.images.isNotEmpty
                        ? PageView.builder(
                      itemCount: product.images.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            // NO HERO HERE -> Fixes the crash
                            child: Image.network(
                              product.images[index],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                        : const Center(child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey)),
                  ),
                ],
              ),
            ),

            // 2. INFO
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand.isNotEmpty)
                      Text(
                        product.brand.toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 14),
                          const SizedBox(width: 4),
                          const Text("12 MINS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          "₹${product.price.toInt()}",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        if (product.discount > 0) ...[
                          Text(
                            "₹${product.mrp.toInt()}",
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.swiggyOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${product.discount.toInt()}% OFF",
                              style: const TextStyle(color: AppTheme.swiggyOrange, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text("(Inclusive of all taxes)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 24),
                    const Divider(),
                  ],
                ),
              ),
            ),

            // 3. DETAILS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Product Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _buildDetailRow("Unit", product.unitText),
                    if(product.attributes.weight > 0)
                      _buildDetailRow("Net Weight", "${product.attributes.weight} ${product.attributes.weightUnit}"),
                    _buildDetailRow("Shelf Life", product.attributes.perishable ? "2-3 Days" : "6 Months"),
                    if(product.attributes.organic)
                      _buildDetailRow("Type", "Organic Product"),
                    const SizedBox(height: 16),
                    const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      product.description.isEmpty
                          ? "No description available."
                          : product.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                  ],
                ),
              ),
            ),

            // 4. SIMILAR PRODUCTS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Similar Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 260,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .where('category.name', isEqualTo: product.category)
                            .where('isActive', isEqualTo: true)
                            .limit(6)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          final docs = snapshot.data!.docs
                              .where((d) => d.id != product.id)
                              .toList();

                          if (docs.isEmpty) return const Text("No similar products found.", style: TextStyle(color: Colors.grey));

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final p = Product.fromMap(docs[index].data() as Map<String, dynamic>);
                              return SizedBox(
                                width: 150,
                                // Ensure these cards have a UNIQUE tag so they don't clash with home screen
                                child: ProductCard(
                                    product: p,
                                    heroTag: "similar_${p.id}_${product.id}"
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // BOTTOM BAR
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        final qty = cart.items[product.id]?.quantity ?? 0;
                        return qty == 0
                            ? ElevatedButton(
                          onPressed: () => cart.addItem(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.qcGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Add to Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        )
                            : Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.qcGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => cart.removeItem(product.id),
                                icon: const Icon(Icons.remove, color: Colors.white),
                              ),
                              Text(
                                "$qty",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (qty < product.stock.availableQty) {
                                    cart.addItem(product);
                                  }
                                },
                                icon: const Icon(Icons.add, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}