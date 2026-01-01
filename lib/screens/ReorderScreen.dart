import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../DatabaseService.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../themes.dart';
import 'OrderTrackingScreen.dart'; // Import for navigation

class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  final int _limit = 3;
  int _currentLimit = 3;
  bool _isLoadingMore = false;

  @override
  Widget build(BuildContext context) {
    // Use the service directly to ensure we get the correct path and data processing
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
        title: const Text("Past Orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Reverted to using the service to guarantee data availability
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

          // Full list of orders from the database
          final allOrders = snapshot.data!;

          // Pagination Logic:
          // We limit the number of items displayed based on _currentLimit.
          // Since we are streaming all orders (standard for small-medium apps),
          // we just slice the list for display.
          final bool hasMore = allOrders.length > _currentLimit;
          final displayOrders = allOrders.take(_currentLimit).toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for floating nav
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.swiggyOrange)
        )
            : TextButton.icon(
          onPressed: () {
            setState(() {
              _isLoadingMore = true;
            });

            // Simulate network delay for UI effect
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _currentLimit += _limit;
                  _isLoadingMore = false;
                });
              }
            });
          },
          icon: const Icon(Icons.expand_more_rounded, color: AppTheme.swiggyOrange),
          label: const Text(
              "Load More Orders",
              style: TextStyle(color: AppTheme.swiggyOrange, fontWeight: FontWeight.bold)
          ),
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.swiggyOrange.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
            ),
            child: Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            "No past orders",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Your order history will appear here",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.swiggyOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Start Shopping", style: TextStyle(fontWeight: FontWeight.bold)),
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

    // Status Colors
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'delivered':
        statusBgColor = AppTheme.qcGreenLight;
        statusTextColor = AppTheme.qcGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        statusBgColor = Colors.red.shade50;
        statusTextColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusBgColor = Colors.orange.shade50;
        statusTextColor = Colors.orange.shade800;
        statusIcon = Icons.access_time_filled_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
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
                // Header: Icon + Date + Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.black87, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Summary",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusTextColor),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),
                ),

                // Items List
                Text(
                  _formatItemsList(items),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                ),

                const SizedBox(height: 16),

                // Footer: Total + Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Paid", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                      ],
                    ),

                    Row(
                      children: [
                        // Track Button (Only for active orders)
                        if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled') ...[
                          TextButton(
                            onPressed: () {
                              if (orderId.isNotEmpty) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.swiggyOrange,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            child: const Text("TRACK"),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Repeat Button
                        OutlinedButton.icon(
                          onPressed: () => _repeatOrder(context, items),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text("REPEAT"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.swiggyOrange,
                            side: BorderSide(color: AppTheme.swiggyOrange.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        action: SnackBarAction(
            label: "VIEW CART",
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/cart')
        ),
      ),
    );
  }
}