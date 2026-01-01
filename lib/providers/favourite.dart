import 'package:flutter/foundation.dart';
import '../models/product.dart';

class FavoritesProvider with ChangeNotifier {
  final Map<String, Product> _items = {};

  Map<String, Product> get items => _items;
  int get count => _items.length;

  bool isFavorite(String productId) {
    return _items.containsKey(productId);
  }

  void toggleFavorite(Product product) {
    if (_items.containsKey(product.id)) {
      _items.remove(product.id);
    } else {
      _items.putIfAbsent(product.id, () => product);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}