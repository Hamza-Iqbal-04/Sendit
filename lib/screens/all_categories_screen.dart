// import 'package:flutter/material.dart';
// import '../DatabaseService.dart';
// import '../themes.dart';
// import 'product_list_screen.dart'; // Ensure this import exists from previous steps
//
// class AllCategoriesScreen extends StatelessWidget {
//   const AllCategoriesScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final DatabaseService dbService = DatabaseService();
//
//     return Scaffold(
//       backgroundColor: AppTheme.background,
//       appBar: AppBar(
//         title: const Text("All Categories"),
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: dbService.getCategories(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.category_outlined, size: 60, color: Colors.grey[300]),
//                   const SizedBox(height: 16),
//                   const Text("No categories found", style: TextStyle(color: Colors.grey)),
//                 ],
//               ),
//             );
//           }
//
//           var categories = snapshot.data!;
//           // Remove 'All' if it exists in the full view to avoid redundancy
//           categories = categories.where((c) => c['name'] != 'All').toList();
//
//           return GridView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: categories.length,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 4, // 4 items per row like Blinkit/Zepto
//               mainAxisSpacing: 20,
//               crossAxisSpacing: 16,
//               childAspectRatio: 0.75,
//             ),
//             itemBuilder: (context, index) {
//               final cat = categories[index];
//               return GestureDetector(
//                 onTap: () {
//                   // Navigate to product list filtered by this category
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ProductListScreen(
//                           title: cat['name'],
//                           searchQuery: cat['name']
//                       ),
//                     ),
//                   );
//                 },
//                 child: Column(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF3F4F6), // Soft grey background
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Center(
//                           child: cat['image'] != null && cat['image'].isNotEmpty
//                               ? Padding(
//                             padding: const EdgeInsets.all(12.0),
//                             child: Image.network(
//                               cat['image'],
//                               fit: BoxFit.contain,
//                               errorBuilder: (_,__,___) => Icon(Icons.category, color: AppTheme.primaryColor.withOpacity(0.5)),
//                             ),
//                           )
//                               : Icon(Icons.category, color: AppTheme.primaryColor.withOpacity(0.5)),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       cat['name'],
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: AppTheme.textSecondary
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }