import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../DatabaseService.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../themes.dart';
import 'OrderTrackingScreen.dart';

class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  final int _limit = 5;
  int _currentLimit = 5;
  bool _isLoadingMore = false;

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text("Please login to see orders")),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Past Orders", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF2D3436))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: dbService.getUserOrders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.swiggyOrange));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final allOrders = snapshot.data!;
          final bool hasMore = allOrders.length > _currentLimit;
          final displayOrders = allOrders.take(_currentLimit).toList();

          return ListView.separated(
            // INCREASED PADDING: Changed bottom padding from 120 to 160 to prevent floating cart overlap
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
            physics: const BouncingScrollPhysics(),
            itemCount: displayOrders.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == displayOrders.length) {
                return _buildLoadMoreButton();
              }
              return _buildModernOrderCard(context, displayOrders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
            height: 24, width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.swiggyOrange)
        )
            : TextButton(
          onPressed: () {
            setState(() {
              _isLoadingMore = true;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _currentLimit += _limit;
                  _isLoadingMore = false;
                });
              }
            });
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.swiggyOrange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppTheme.swiggyOrange.withOpacity(0.3)),
            ),
          ),
          child: const Text("Load More Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
              ],
            ),
            child: Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            "No past orders",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: const Color(0xFF2D3436)
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your order history will appear here",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.swiggyOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Start Shopping", style: TextStyle(fontWeight: FontWeight.w800)),
          )
        ],
      ),
    );
  }

  Widget _buildModernOrderCard(BuildContext context, Map<String, dynamic> order) {
    final String orderId = order['orderId'] ?? '';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final Timestamp? timestamp = order['createdAt'];
    final dateStr = timestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
        : 'Processing...';

    final double total = (order['total'] is int)
        ? (order['total'] as int).toDouble()
        : (order['total'] as double? ?? 0.0);

    final String status = order['status'] ?? 'Pending';

    // Status Styling
    Color statusBg;
    Color statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'delivered':
        statusBg = AppTheme.qcGreenLight;
        statusText = AppTheme.qcGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        statusBg = const Color(0xFFFFF0F0);
        statusText = const Color(0xFFE74C3C);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusBg = const Color(0xFFFFF8E1);
        statusText = const Color(0xFFFFA000);
        statusIcon = Icons.access_time_filled_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (orderId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF2D3436), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}".toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2D3436)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusText),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0F0F5)),
                const SizedBox(height: 16),

                // Items
                Text(
                  _formatItemsList(items),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF636E72), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 16),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Amount", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
                        const SizedBox(height: 2),
                        Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2D3436))),
                      ],
                    ),

                    Row(
                      children: [
                        if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled') ...[
                          TextButton(
                            onPressed: () {
                              if (orderId.isNotEmpty) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
                              }
                            },
                            child: const Text("Track Order", style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                        ],

                        ElevatedButton.icon(
                          onPressed: () => _repeatOrder(context, items),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text("Repeat"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.swiggyOrange,
                            elevation: 0,
                            side: BorderSide(color: AppTheme.swiggyOrange.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatItemsList(List<dynamic> items) {
    if (items.isEmpty) return "No items";
    return items.map((i) => "${i['quantity']} x ${i['name']}").join(", ");
  }

  void _repeatOrder(BuildContext context, List<dynamic> items) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    for (var item in items) {
      final product = Product(
          id: item['productId'],
          name: item['name'],
          price: (item['price'] as num).toDouble(),
          description: '', brand: '', mrp: 0, discount: 0, unit: '',
          unitText: item['unit'] ?? '', images: [], thumbnail: item['image'] ?? '',
          stock: ProductStock(availableQty: 99, isAvailable: true, lowStock: false, lastUpdated: DateTime.now()),
          category: '', categoryId: '', isFeatured: false, isBestSeller: false,
          ratings: ProductRatings(average: 0, count: 0), soldCount: 0, variants: [],
          attributes: ProductAttributes.fromMap({}), searchKeywords: [], tags: []
      );
      cart.addItem(product);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Items added to cart!"),
        backgroundColor: AppTheme.qcGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
            label: "VIEW CART",
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/cart') // Ensure route exists or replace with push
        ),
      ),
    );
  }
}