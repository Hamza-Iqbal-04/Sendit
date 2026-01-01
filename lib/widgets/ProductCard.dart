import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favourite.dart';
import '../themes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String? heroTag;

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
      backgroundColor: Colors.transparent, // Transparent for custom shape
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ProductDetailsSheet(
                  product: product,
                  scrollController: scrollController
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String tag = heroTag ?? product.id;
    final isOutOfStock = product.stock.availableQty <= 0;

    // Cache buster logic
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
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C3E50).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE & BADGES SECTION
            Stack(
              children: [
                // Image Container
                Container(
                  height: 140, // Slightly taller for better visual
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Hero(
                      tag: tag,
                      child: _buildImage(imageUrl),
                    ),
                  ),
                ),

                // Discount Tag (Modern "Bookmark" style or minimal tag)
                if (!isOutOfStock && product.discount > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E86DE), // A nice blue or keep swiggyOrange
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                        ],
                      ),
                      child: Text(
                        "${product.discount.toInt()}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Favorite Button (Subtle styling)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, fav, _) {
                      final isFav = fav.isFavorite(product.id);
                      return Material(
                        color: Colors.white.withOpacity(0.9),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => fav.toggleFavorite(product),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? const Color(0xFFE74C3C) : Colors.grey.shade400,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // CONTENT SECTION
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery Time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 10, color: Colors.grey.shade800),
                              const SizedBox(width: 4),
                              Text(
                                "12 MINS",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter', // Assuming Inter or system font
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF2D3436),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Unit
                    Text(
                      product.unitText,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // Price & Action Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price Block
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.discount > 0)
                              Text(
                                "₹${product.mrp.toInt()}",
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              "₹${product.price.toInt()}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                          ],
                        ),

                        // Add Button Logic
                        isOutOfStock
                            ? _buildOutOfStockBadge()
                            : Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            final qty = cart.items.containsKey(product.id) ? cart.items[product.id]!.quantity : 0;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: qty == 0
                                  ? _buildAddButton(context, cart)
                                  : _buildQtyControl(context, cart, qty, product.id, product.stock.availableQty),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return imageUrl.isEmpty
        ? const Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 40)
        : CachedNetworkImage(
      key: ValueKey(imageUrl),
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade200),
        ),
      ),
      errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
    );
  }

  Widget _buildOutOfStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        "Out of Stock",
        style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Modern "ADD" Button
  Widget _buildAddButton(BuildContext context, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        // HapticFeedback.lightImpact(); // Optional: Add haptic feedback
        cart.addItem(product);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.qcGreen, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.qcGreen.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: const Text(
          "ADD",
          style: TextStyle(
            color: AppTheme.qcGreen,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Modern Qty Control (Green Pill)
  Widget _buildQtyControl(BuildContext context, CartProvider cart, int qty, String productId, int maxStock) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.qcGreen,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.qcGreen.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQtyIcon(Icons.remove, () => cart.removeItem(productId)),
          SizedBox(
            width: 24, // Fixed width for number stability
            child: Text(
              "$qty",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          _buildQtyIcon(Icons.add, () {
            if (qty < maxStock) cart.addItem(product);
          }),
        ],
      ),
    );
  }

  Widget _buildQtyIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// Keeping the Details Sheet Mostly Same but cleaning styles
class ProductDetailsSheet extends StatelessWidget {
  final Product product;
  final ScrollController? scrollController;

  const ProductDetailsSheet({super.key, required this.product, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 280,
                    child: product.images.isNotEmpty
                        ? PageView.builder(
                      itemCount: product.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CachedNetworkImage(
                            imageUrl: product.images[index],
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, size: 60, color: Colors.grey),
                          ),
                        );
                      },
                    )
                        : const Center(child: Icon(Icons.image_not_supported_rounded, size: 80, color: Colors.grey)),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.swiggyOrange,
                        letterSpacing: 1.2,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2D3436), height: 1.2),
                  ),
                  const SizedBox(height: 16),

                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${product.price.toInt()}",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2D3436)),
                      ),
                      const SizedBox(width: 12),
                      if (product.discount > 0) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "₹${product.mrp.toInt()}",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.swiggyOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${product.discount.toInt()}% OFF",
                              style: const TextStyle(color: AppTheme.swiggyOrange, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("(Inclusive of all taxes)", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),

                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 32),

                  const Text("Product Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3436))),
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow("Unit", product.unitText),
                        if(product.attributes.weight > 0)
                          _buildDetailRow("Net Weight", "${product.attributes.weight} ${product.attributes.weightUnit}"),
                        _buildDetailRow("Shelf Life", product.attributes.perishable ? "2-3 Days" : "6 Months"),
                        if(product.attributes.organic)
                          _buildDetailRow("Type", "Organic Product"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3436))),
                  const SizedBox(height: 12),
                  Text(
                    product.description.isEmpty ? "No description available." : product.description,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6),
                  ),
                  const SizedBox(height: 120), // Space for bottom bar
                ]),
              ),
            ),
          ],
        ),

        // Floating Action Bar in Details
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30), // Extra bottom padding for safety
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))
              ],
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                // Favorite Toggle in Details
                Consumer<FavoritesProvider>(
                  builder: (context, fav, _) {
                    final isFav = fav.isFavorite(product.id);
                    return Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: isFav ? const Color(0xFFFFF0F0) : Colors.white,
                        border: Border.all(color: isFav ? const Color(0xFFFFD1D1) : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFE74C3C) : Colors.grey.shade600,
                          size: 28,
                        ),
                        onPressed: () => fav.toggleFavorite(product),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      final qty = cart.items[product.id]?.quantity ?? 0;
                      return qty == 0
                          ? ElevatedButton(
                        onPressed: () => cart.addItem(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.qcGreen,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Add to Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      )
                          : Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.qcGreen,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppTheme.qcGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () => cart.removeItem(product.id),
                              icon: const Icon(Icons.remove, color: Colors.white),
                            ),
                            Text(
                              "$qty",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
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
        )
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF2D3436))),
        ],
      ),
    );
  }
}