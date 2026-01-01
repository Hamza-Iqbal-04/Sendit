import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/product.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRODUCTS ---
  Stream<List<Product>> getProducts() {
    return _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product.fromMap(data);
      }).toList();
    });
  }

  // --- CATEGORIES (Fix for AllCategoriesScreen) ---
  Stream<List<Map<String, dynamic>>> getCategories() {
    return _db
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // --- ORDERS (Fix for ReorderScreen) ---
  Future<String> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required String addressId,
    String paymentMethod = 'cod',
  }) async {
    try {
      final orderId = _db.collection('orders').doc().id;
      final now = Timestamp.now();

      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'items': items,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        'status': 'pending', // pending, delivered, cancelled
        'statusHistory': [
          {
            'status': 'pending',
            'timestamp': now,
            'note': 'Order placed',
          }
        ],
        'createdAt': now,
        'updatedAt': now,
      };

      await _db.collection('orders').doc(orderId).set(orderData);
      return orderId;
    } catch (e) {
      rethrow;
    }
  }

  // Fetch User's Past Orders
  Stream<List<Map<String, dynamic>>> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // --- ADDRESSES ---
  Stream<List<UserAddress>> getUserAddresses(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .orderBy('isDefault', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserAddress.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> saveAddress(String userId, UserAddress address) async {
    try {
      if (address.isDefault) {
        // Remove default status from other addresses
        final addressesSnapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .get();

        final batch = _db.batch();
        for (var doc in addressesSnapshot.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        await batch.commit();
      }

      if (address.id.isEmpty) {
        await _db
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .add(address.toMap());
      } else {
        await _db
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(address.id)
            .update(address.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}