import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favourite.dart';
import '../themes.dart';
import '../widgets/ProductCard.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("My Favorites"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Removes back button if on a tab
        actions: [
          // Clear All Button (Only shows if there are items)
          Consumer<FavoritesProvider>(
            builder: (context, fav, _) {
              if (fav.count == 0) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
                tooltip: "Clear All",
                onPressed: () => _showClearDialog(context, fav),
              );
            },
          ),
        ],
      ),
      // Removed Stack and FloatingCartButton because MainNavigation handles the global cart button
      body: Consumer<FavoritesProvider>(
        builder: (context, favorites, child) {
          if (favorites.count == 0) {
            return _buildEmptyState(context);
          }

          final favoriteList = favorites.items.values.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Count
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  "${favorites.count} Items Saved",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              // Product Grid
              Expanded(
                child: GridView.builder(
                  // Bottom padding ensures content isn't hidden behind the global FloatingCartButton
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68, // Matches Home Screen card ratio
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: favoriteList.length,
                  itemBuilder: (ctx, i) {
                    final product = favoriteList[i];
                    return ProductCard(
                      product: product,
                      // Unique Hero Tag for Favorites Screen to prevent conflicts with Home Screen
                      heroTag: "fav_${product.id}",
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Professional Empty State
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            "Your wishlist is empty",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Hit the heart button to save items for later.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate back to Home Tab (index 0)
              // Assuming MainNavigation listens to a provider or we pop to root
              // For now, if pushed, pop. If tab, this might need a callback or Provider logic.
              // Safe default:
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Pill shape
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text("Start Shopping"),
          )
        ],
      ),
    );
  }

  // Confirmation Dialog for Clearing Favorites
  void _showClearDialog(BuildContext context, FavoritesProvider fav) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Clear Favorites?"),
        content: const Text("Are you sure you want to remove all items from your favorites?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              fav.clear();
              Navigator.pop(ctx);
            },
            child: Text("Clear", style: TextStyle(color: AppTheme.swiggyOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}