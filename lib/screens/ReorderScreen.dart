import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../DatabaseService.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../themes.dart';

class ReorderScreen extends StatelessWidget {
  const ReorderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Please login to see orders")));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Past Orders"),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final orders = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text("No past orders yet", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text("Start Shopping"),
          )
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final Timestamp? timestamp = order['createdAt'];
    final dateStr = timestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
        : 'Processing...';

    // Handle int vs double types for total
    final double total = (order['total'] is int)
        ? (order['total'] as int).toDouble()
        : (order['total'] as double? ?? 0.0);

    final String status = order['status'] ?? 'Pending';
    Color statusColor = Colors.orange;
    if (status.toLowerCase() == 'delivered') statusColor = AppTheme.qcGreen;
    if (status.toLowerCase() == 'cancelled') statusColor = Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.storefront_rounded, color: Colors.black87, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Order Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatItemsList(items),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Paid", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _repeatOrder(context, items),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text("REPEAT ORDER"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      const SnackBar(content: Text("Items added to cart!"), backgroundColor: AppTheme.qcGreen),
    );
  }
}