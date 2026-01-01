import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_provider.dart';
import '../themes.dart';

// Import all functional screens
import 'FavoritesScreen.dart';
import 'ReorderScreen.dart'; // Using ReorderScreen for "My Orders"
import '../widgets/AddressListScreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final User? authUser = authProvider.currentUser;

    // Safety check
    if (authUser == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text("Please login to view profile")),
      );
    }

    // Stream from 'users' collection to get real-time updates (Phone, Name changes)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(authUser.uid).snapshots(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator(color: AppTheme.swiggyOrange)),
          );
        }

        // Parse Data
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final String displayName = userData?['name'] ?? authUser.displayName ?? "User";
        final String email = userData?['email'] ?? authUser.email ?? "";
        final String phone = userData?['phone'] ?? "No phone number";

        // Avatar Initials
        final String initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text(
              "My Account",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            // leading: IconButton(
            //   icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            //   onPressed: () => Navigator.pop(context),
            // ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 40),
            child: Column(
              children: [
                // 1. Profile Header Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppTheme.qcGreenLight,
                        child: Text(
                          initials,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.qcGreen),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                              ),
                            if (phone != "No phone number") ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    phone,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                      // Edit Button
                      IconButton(
                        onPressed: () => _showEditProfileDialog(context, authUser.uid, displayName, phone),
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.qcGreen),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.qcGreenLight.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        tooltip: "Edit Profile",
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 2. Menu Section: Content
                _buildSectionHeader("CONTENT"),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _buildMenuTile(
                        context,
                        icon: Icons.receipt_long_rounded,
                        title: "My Orders",
                        subtitle: "Track & reorder past purchases",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReorderScreen())),
                        isFirst: true,
                      ),
                      _buildDivider(),
                      _buildMenuTile(
                        context,
                        icon: Icons.favorite_rounded,
                        title: "My Wishlist",
                        subtitle: "Your saved products",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                      ),
                      _buildDivider(),
                      _buildMenuTile(
                        context,
                        icon: Icons.location_on_rounded,
                        title: "Delivery Addresses",
                        subtitle: "Manage your saved addresses",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())),
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Menu Section: Preferences
                _buildSectionHeader("PREFERENCES"),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _buildMenuTile(
                        context,
                        icon: Icons.payment_rounded,
                        title: "Payment Methods",
                        onTap: () => _showComingSoon(context, "Payments"),
                        isFirst: true,
                      ),
                      _buildDivider(),
                      _buildMenuTile(
                        context,
                        icon: Icons.notifications_active_rounded,
                        title: "Notifications",
                        trailing: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: true,
                            onChanged: (val) {},
                            activeColor: AppTheme.swiggyOrange,
                            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                          ),
                        ),
                        onTap: () {},
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 4. Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        await authProvider.logout();
                        if (context.mounted) {
                          // Pop everything and go back to login
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.swiggyOrange.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: AppTheme.swiggyOrange,
                        backgroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Text(
                  "Version 1.0.0",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ]
                  ],
                ),
              ),
              // Trailing
              trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 64);
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature coming soon!"), duration: const Duration(seconds: 1), backgroundColor: AppTheme.swiggyOrange),
    );
  }

  // --- Dialogs ---

  void _showEditProfileDialog(BuildContext context, String uid, String currentName, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone == "No phone number" ? "" : currentPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(uid).set({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                }, SetOptions(merge: true));

                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.swiggyOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}