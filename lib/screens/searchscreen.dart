import 'package:flutter/material.dart';
import '../DatabaseService.dart';
import '../models/product.dart';
import '../widgets/ProductCard.dart';
import '../themes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          decoration: const InputDecoration(
            hintText: "Search for 'Paneer' or 'Milk'...",
            border: InputBorder.none,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _searchQuery.isEmpty ? _buildSuggestions() : _buildSearchResults(),
    );
  }

  Widget _buildSuggestions() {
    final List<String> suggestions = ["Milk", "Bread", "Eggs", "Butter", "Paneer"];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Popular Searches", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) => ActionChip(
              label: Text(s),
              backgroundColor: Colors.grey[100],
              side: BorderSide.none,
              onPressed: () {
                _searchController.text = s;
                setState(() => _searchQuery = s.toLowerCase());
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<Product>>(
      stream: _dbService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) return const SizedBox();

        // Client-side filtering (Note: For large apps, move this to Algolia/ElasticSearch)
        final results = snapshot.data!.where((p) =>
        p.name.toLowerCase().contains(_searchQuery) ||
            p.searchKeywords.contains(_searchQuery)
        ).toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("No matching items found", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) => ProductCard(product: results[index]),
        );
      },
    );
  }
}