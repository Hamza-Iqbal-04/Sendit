import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../themes.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "HELP",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found"));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final String status = orderData['status'] ?? 'pending';
          final List<dynamic> items = orderData['items'] ?? [];
          final double total = (orderData['total'] as num).toDouble();
          final double savings = 25.0; // Mock savings for now

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                // 1. HERO SECTION
                _buildHeroSection(status),

                // 2. PROGRESS STEPPER
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _buildOrderStepper(status),
                ),

                // 3. DRIVER CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDriverCard(status),
                ),

                const SizedBox(height: 16),

                // 4. REASSURANCE BANNER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildReassuranceBanner(),
                ),

                const SizedBox(height: 24),

                // 5. ORDER SUMMARY
                _buildOrderSummary(items, total, savings),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.deepOrange,
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  // --- 1. HERO SECTION ---
  Widget _buildHeroSection(String status) {
    // Determine colors/text based on status
    String title = "Arriving in 8 mins";
    String subtitle = "Woah! That was fast!";
    double progress = 0.3;

    if (status == 'delivered') {
      title = "Order Delivered";
      subtitle = "Enjoy your fresh items!";
      progress = 1.0;
    } else if (status == 'shipped' || status == 'out_for_delivery') {
      title = "Arriving in 4 mins";
      subtitle = "On the way to you";
      progress = 0.7;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, bottom: 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7A18), // Deep Orange
            Color(0xFFFF3D00), // Orange
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer glow
              RotationTransition(
                turns: _controller,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.2)],
                    ),
                  ),
                ),
              ),
              // Progress Circle
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC6FF00)), // Neon Green
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Icon or Text inside
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'delivered' ? Icons.check_circle : Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  if (status != 'delivered') ...[
                    const SizedBox(height: 4),
                    const Text("8 min", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. STEPPER ---
  Widget _buildOrderStepper(String currentStatus) {
    int currentStep = 0;
    if (currentStatus == 'shipped' || currentStatus == 'out_for_delivery') currentStep = 1;
    if (currentStatus == 'delivered') currentStep = 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepNode("Packed", 0, currentStep),
          _buildConnector(0, currentStep),
          _buildStepNode("On the Way", 1, currentStep),
          _buildConnector(1, currentStep),
          _buildStepNode("Arrived", 2, currentStep),
        ],
      ),
    );
  }

  Widget _buildStepNode(String label, int index, int currentStep) {
    bool isCompleted = index <= currentStep;
    bool isCurrent = index == currentStep;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 24 : 18,
          height: isCurrent ? 24 : 18,
          decoration: BoxDecoration(
            color: isCompleted ? AppTheme.qcGreen : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: AppTheme.qcGreen.withOpacity(0.3), width: 4) : null,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
            color: isCompleted ? AppTheme.textPrimary : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int index, int currentStep) {
    bool isCompleted = index < currentStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14), // Align with dots
        decoration: BoxDecoration(
          color: isCompleted ? AppTheme.qcGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // --- 3. DRIVER CARD ---
  Widget _buildDriverCard(String status) {
    if (status == 'pending') return const SizedBox.shrink(); // No driver yet

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              image: const DecorationImage(
                image: NetworkImage("https://randomuser.me/api/portraits/men/32.jpg"), // Static mock
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Rajesh Kumar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: const Text("VACCINATED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Delivery Partner • 4.8 ★", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          // Call Button
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.swiggyOrange,
            ),
            child: IconButton(
              icon: const Icon(Icons.phone, color: Colors.white, size: 20),
              onPressed: () {
                // Mock Call Action
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calling Rajesh...")));
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. REASSURANCE BANNER ---
  Widget _buildReassuranceBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6EA), // Light Green
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppTheme.qcGreen),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Your order is safe and hygienic. Temperature checked.",
              style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. ORDER SUMMARY ---
  Widget _buildOrderSummary(List<dynamic> items, double total, double savings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Summary", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          // Items List
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Qty box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.swiggyOrange)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['name'],
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text("₹${item['price']}", style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          )).toList(),

          const Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Bill", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("₹$total", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
            child: Text("You saved ₹$savings on this order!", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}