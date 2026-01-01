import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../DatabaseService.dart';
import '../models/product.dart';
import '../providers/AddressProvider.dart';
import '../screens/AddEditAddressScreen.dart';
import '../themes.dart';

class AddressListScreen extends StatelessWidget {
  final bool isSelectionMode;

  const AddressListScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    // Access provider for selection logic
    final addressProvider = Provider.of<AddressProvider>(context); // Listen to changes to update selection UI

    return Scaffold(
      backgroundColor: AppTheme.background, // Light grey background
      appBar: AppBar(
        title: Text(
          isSelectionMode ? "Select Address" : "My Addresses",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: userId == null
                  ? _buildNotLoggedInState(context)
                  : StreamBuilder<List<UserAddress>>(
                stream: dbService.getUserAddresses(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.swiggyOrange));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  final addresses = snapshot.data!;
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildModernAddressCard(
                        context,
                        addresses[index],
                        userId,
                        addressProvider,
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Sticky Action Button (Consistent with AddEditAddressScreen)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.swiggyOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("ADD NEW ADDRESS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("Login to manage addresses", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
        ],
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Icon(Icons.location_off_rounded, size: 60, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            "No addresses saved",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a location to speed up checkout",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAddressCard(
      BuildContext context,
      UserAddress address,
      String userId,
      AddressProvider provider,
      ) {
    final isSelected = provider.selectedAddress?.id == address.id;
    final isDefault = address.isDefault;

    return InkWell(
      onTap: () {
        if (isSelectionMode) {
          provider.selectAddress(address);
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Highlight border if selected in selection mode
          border: Border.all(
            color: isSelectionMode && isSelected ? AppTheme.swiggyOrange : Colors.grey.shade200,
            width: isSelectionMode && isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isSelectionMode && isSelected) ? AppTheme.swiggyOrange.withOpacity(0.1) : Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForLabel(address.label),
                    color: (isSelectionMode && isSelected) ? AppTheme.swiggyOrange : Colors.grey.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.qcGreenLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("DEFAULT", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.qcGreen)),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${address.street}, ${address.city}",
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      Text(
                        "${address.state} - ${address.zipCode}",
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            address.phone,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing Widget: Radio (Selection Mode) OR Menu (Normal Mode)
                if (isSelectionMode)
                  Transform.scale(
                    scale: 1.2,
                    child: Radio<String>(
                      value: address.id,
                      groupValue: provider.selectedAddress?.id,
                      activeColor: AppTheme.swiggyOrange,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (_) {
                        provider.selectAddress(address);
                        Navigator.pop(context);
                      },
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address)));
                      } else if (value == 'delete') {
                        await DatabaseService().deleteAddress(userId, address.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text("Edit", style: TextStyle(fontWeight: FontWeight.w500))]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 12), Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500))]),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'work': return Icons.work_outline_rounded;
      case 'other': return Icons.location_on_outlined;
      default: return Icons.home_outlined;
    }
  }
}