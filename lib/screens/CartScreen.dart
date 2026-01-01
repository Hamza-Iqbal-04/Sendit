import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/AddressProvider.dart';
import '../widgets/AddressListScreen.dart';
import '../themes.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  double _tipAmount = 0.0;
  bool _donateToFeedingIndia = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6), // Instamart grey bg
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Consumer2<CartProvider, AddressProvider>(
              builder: (context, cart, addressProvider, _) {
                final addressLabel = addressProvider.selectedAddress?.label ?? "Home";
                return Text(
                  "${cart.itemCount} items • to $addressLabel",
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w400),
                );
              },
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) return _buildEmptyState(context);

          // Calculations
          final double itemTotal = cart.totalAmount;
          final double handlingFee = 4.0;
          final double deliveryFee = itemTotal > 199 ? 0.0 : 25.0;
          final double donation = _donateToFeedingIndia ? 2.0 : 0.0;
          final double toPay = itemTotal + handlingFee + deliveryFee + _tipAmount + donation;
          final double savings = (itemTotal * 0.1); // Mock savings

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                // 1. Delivery Promise
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA), // Light Cyan
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Color(0xFF00ACC1), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Delivery in 8 minutes", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text("Shipment of 1 item", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // 2. Cart Items
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        itemBuilder: (ctx, i) => _buildCartRow(cart.items.values.toList()[i], cart),
                      ),
                      // Add More Items Button
                      InkWell(
                        onTap: () {
                          // Navigate back to Home/Main wrapper to shop more
                          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAF8), // Very light green
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, size: 18, color: Colors.black54),
                              const SizedBox(width: 8),
                              const Text("Add more items", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400)
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // 3. Coupon Section
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer_outlined, color: AppTheme.instamartPurple),
                      const SizedBox(width: 12),
                      const Text("Apply Coupon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      Text("Select", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400)
                    ],
                  ),
                ),

                // 4. Tip Delivery Partner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tip your delivery partner", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text("Thank your delivery partner for helping you stay safe indoors. Support them with a tip.",
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        children: [10, 20, 30, 50].map((amt) =>
                            GestureDetector(
                              onTap: () => setState(() => _tipAmount = _tipAmount == amt.toDouble() ? 0.0 : amt.toDouble()),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _tipAmount == amt.toDouble() ? const Color(0xFFFFF3E0) : Colors.white,
                                  border: Border.all(
                                      color: _tipAmount == amt.toDouble() ? Colors.orange : Colors.grey.shade300
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    if(_tipAmount == amt.toDouble()) const Text("💰 ", style: TextStyle(fontSize: 10)),
                                    Text("₹$amt", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                        ).toList(),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 5. Bill Details
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Bill Details", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 12),
                      _buildBillRow("Item Total", itemTotal),
                      _buildBillRow("Handling Charge", handlingFee, tooltip: "Handling fees help us serve you better"),
                      _buildBillRow("Delivery Fee", deliveryFee, isStrike: deliveryFee == 0, strikeText: "25"),
                      if (_tipAmount > 0) _buildBillRow("Delivery Tip", _tipAmount),
                      if (_donateToFeedingIndia) _buildBillRow("Donation", donation),

                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("To Pay", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text("₹${toPay.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),

                      // Savings Tag
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1), // Light Teal
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF80CBC4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.savings_outlined, size: 16, color: Color(0xFF00796B)),
                            const SizedBox(width: 8),
                            Text("You saved ₹${savings.toStringAsFixed(0)} on this order!",
                                style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // 6. Feeding India Toggle
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.volunteer_activism, color: Colors.red, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Feeding India Donation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text("Help feed the needy for just ₹2", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _donateToFeedingIndia,
                        onChanged: (v) => setState(() => _donateToFeedingIndia = v),
                        activeColor: AppTheme.swiggyOrange,
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Consumer2<CartProvider, AddressProvider>(
        builder: (context, cart, addressProvider, _) {
          if (cart.items.isEmpty) return const SizedBox.shrink();
          final toPay = cart.totalAmount + 4.0 + (cart.totalAmount > 199 ? 0 : 25) + _tipAmount + (_donateToFeedingIndia ? 2 : 0);
          final selectedAddress = addressProvider.selectedAddress;

          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Address Strip
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressListScreen(isSelectionMode: true),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            selectedAddress == null ? Icons.location_off : Icons.location_on,
                            size: 20,
                            color: AppTheme.swiggyOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedAddress == null ? "No Address Selected" : "Delivering to ${selectedAddress.label}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800),
                              ),
                              Text(
                                selectedAddress == null ? "Tap to select delivery location" : "${selectedAddress.street}, ${selectedAddress.city}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "CHANGE",
                          style: TextStyle(color: AppTheme.swiggyOrange, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pay Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _placeOrder(cart, addressProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.qcGreen, // Green for "Go"
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("₹${toPay.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            const Text("TOTAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70)),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              selectedAddress == null ? "Select Address" : "Proceed to Pay",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white)
                          ],
                        )
                      ],
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Your cart is empty", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("You can go to home page to view more items.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.swiggyOrange),
              child: const Text("See restaurants near you", style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }

  Widget _buildCartRow(CartItem item, CartProvider cart) {
    return Row(
      children: [
        // 1. Veg/Non-Veg icon (Optional based on data, keeping generic)
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4)),
          child: const Icon(Icons.circle, size: 8, color: Colors.green),
        ),
        const SizedBox(width: 12),

        // 2. Product Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: item.product.thumbnail,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),

        // 3. Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(item.product.unitText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text("₹${item.product.price.toInt()}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),

        // 4. Quantity Controls
        Container(
          height: 36,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.qcGreen),
              boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => cart.removeItem(item.product.id),
                child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.remove, color: AppTheme.qcGreen, size: 16)),
              ),
              Text("${item.quantity}", style: const TextStyle(color: AppTheme.qcGreen, fontWeight: FontWeight.bold, fontSize: 14)),
              InkWell(
                onTap: () => cart.addItem(item.product),
                child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.add, color: AppTheme.qcGreen, size: 16)),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBillRow(String label, double amount, {bool isTotal = false, bool isStrike = false, String? strikeText, String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              color: isTotal ? Colors.black : Colors.grey.shade700,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
          )),
          if (tooltip != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 12, color: Colors.grey),
          ],
          const Spacer(),
          if (isStrike) ...[
            Text("₹$strikeText", style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 4),
            const Text("FREE", style: TextStyle(color: AppTheme.qcGreen, fontWeight: FontWeight.bold, fontSize: 12)),
          ] else
            Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
                fontSize: isTotal ? 16 : 13
            )),
        ],
      ),
    );
  }

  Future<void> _placeOrder(CartProvider cart, AddressProvider addressProvider) async {
    if (addressProvider.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a delivery address first"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Optional: Auto open address selection
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen(isSelectionMode: true)));
      return;
    }

    setState(() => _isLoading = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    try {
      // Pass the selected address ID to placeOrder
      await cart.placeOrder(addressProvider.selectedAddress!.id);

      if(mounted) {
        // Show success animation/dialog (Instamart style)
        Navigator.pop(context); // Close Cart
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order Placed Successfully!"), backgroundColor: AppTheme.qcGreen),
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
}