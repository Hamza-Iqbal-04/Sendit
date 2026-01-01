import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Needed for Provider.of
import '../DatabaseService.dart';
import '../models/product.dart';
import '../providers/AddressProvider.dart'; // Needed for AddressProvider
import '../screens/AddEditAddressScreen.dart';
import '../themes.dart';

class AddressListScreen extends StatelessWidget {
  final bool isSelectionMode; // Add this flag

  const AddressListScreen({
    super.key,
    this.isSelectionMode = false, // Default is management mode
  });

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    // Access provider for selection logic
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isSelectionMode ? "Select Delivery Address" : "My Addresses"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text("Login to manage addresses"))
          : StreamBuilder<List<UserAddress>>(
        stream: dbService.getUserAddresses(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final addresses = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildAddressCard(
                context,
                addresses[index],
                userId,
                addressProvider,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
        ),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add New Address", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No addresses saved yet", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
      BuildContext context,
      UserAddress address,
      String userId,
      AddressProvider provider,
      ) {
    // Check if this address is currently selected in the provider
    final isSelected = provider.selectedAddress?.id == address.id;

    return InkWell(
      onTap: () {
        if (isSelectionMode) {
          // Select and Go Back
          provider.selectAddress(address);
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelectionMode && isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2) // Highlight selected
              : (address.isDefault
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1)
              : Border.all(color: AppTheme.border)),
          boxShadow: isSelectionMode && isSelected
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 4)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForLabel(address.label),
                        size: 20,
                        color: isSelectionMode && isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelectionMode && isSelected ? AppTheme.primaryColor : Colors.black,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.qcGreenLight, borderRadius: BorderRadius.circular(4)),
                          child: const Text("DEFAULT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        )
                      ]
                    ],
                  ),
                  // Only show menu if NOT in selection mode, or allow both
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address)));
                      } else if (value == 'delete') {
                        await DatabaseService().deleteAddress(userId, address.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit")),
                      const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                    ],
                    child: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${address.fullName}\n${address.street}\n${address.city}, ${address.state} - ${address.zipCode}\nPhone: ${address.phone}",
                style: const TextStyle(height: 1.5, color: AppTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'work': return Icons.work_outline;
      case 'other': return Icons.location_on_outlined;
      default: return Icons.home_outlined;
    }
  }
}