import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_provider.dart';
import '../themes.dart';

// Import all functional screens
import 'FavoritesScreen.dart';
import 'ReorderScreen.dart';
import '../widgets/AddressListScreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final User? authUser = authProvider.currentUser;

    // Safety check
    if (authUser == null) {
      return const Scaffold(body: Center(child: Text("Please login to view profile")));
    }

    // Stream from 'users' collection to get real-time updates (Phone, Name changes)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(authUser.uid).snapshots(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator()),
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
            title: const Text("My Account"),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),

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
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                            if (phone != "No phone number") ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 12, color: AppTheme.textTertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    phone,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
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
                        tooltip: "Edit Profile",
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Menu Section: Content
                _buildSectionHeader("CONTENT"),

                _buildMenuTile(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: "My Orders",
                  subtitle: "Track & reorder past purchases",
                  // ✅ Linked to ReorderScreen
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReorderScreen())),
                ),

                _buildMenuTile(
                  context,
                  icon: Icons.favorite_rounded,
                  title: "My Wishlist",
                  subtitle: "Your saved products",
                  // ✅ Linked to FavoritesScreen
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                ),

                _buildMenuTile(
                  context,
                  icon: Icons.location_on_rounded,
                  title: "Delivery Addresses",
                  subtitle: "Manage your saved addresses",
                  // ✅ Linked to AddressListScreen
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())),
                ),

                const SizedBox(height: 12),

                // 3. Menu Section: Preferences
                _buildSectionHeader("PREFERENCES"),

                _buildMenuTile(
                  context,
                  icon: Icons.payment_rounded,
                  title: "Payment Methods",
                  onTap: () => _showComingSoon(context, "Payments"),
                ),

                _buildMenuTile(
                  context,
                  icon: Icons.notifications_active_rounded,
                  title: "Notifications",
                  trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeColor: AppTheme.qcGreen
                  ),
                  onTap: () {},
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
                          // Pop everything and go back to login (or main wrapper which redirects to login)
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.swiggyOrange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: AppTheme.swiggyOrange,
                      ),
                      child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Text("Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper Widgets
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textTertiary, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: AppTheme.textPrimary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature coming soon!"), duration: const Duration(seconds: 1)),
    );
  }

  // Edit Profile Dialog
  void _showEditProfileDialog(BuildContext context, String uid, String currentName, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone == "No phone number" ? "" : currentPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name", hintText: "Enter your name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number", hintText: "+91 0000000000"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update Firestore
                await FirebaseFirestore.instance.collection('users').doc(uid).set({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  // We merge to avoid overwriting email or created date if they exist
                }, SetOptions(merge: true));

                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating profile: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}