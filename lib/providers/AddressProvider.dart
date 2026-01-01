import 'dart:async';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';


import '../DatabaseService.dart';
import '../models/product.dart';

class AddressProvider with ChangeNotifier {
  UserAddress? _selectedAddress;
  List<UserAddress> _addresses = [];
  final DatabaseService _dbService = DatabaseService();

  // Subscriptions
  StreamSubscription? _addressSubscription;
  StreamSubscription? _authSubscription;

  UserAddress? get selectedAddress => _selectedAddress;
  List<UserAddress> get addresses => _addresses;

  // Initialize: Listen to Auth Changes FIRST
  void init() {
    // Cancel any existing listeners to avoid duplicates
    _authSubscription?.cancel();

    // Listen for User Login/Logout events
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _addressSubscription?.cancel(); // Stop listening to old user's addresses

      if (user != null) {
        // ✅ NEW USER LOGGED IN: Fetch THEIR addresses
        _addressSubscription = _dbService.getUserAddresses(user.uid).listen((List<UserAddress> addrList) {
          _addresses = addrList;
          _updateSelectedAddress(addrList);
          notifyListeners();
        });
      } else {
        // ❌ USER LOGGED OUT: Clear data
        _addresses = [];
        _selectedAddress = null;
        notifyListeners();
      }
    });
  }

  // Helper logic to pick a default address
  void _updateSelectedAddress(List<UserAddress> addrList) {
    if (_selectedAddress == null || !addrList.any((a) => a.id == _selectedAddress!.id)) {
      if (addrList.isNotEmpty) {
        // Prefer default, otherwise pick first
        _selectedAddress = addrList.firstWhere(
              (a) => a.isDefault,
          orElse: () => addrList.first,
        );
      } else {
        _selectedAddress = null;
      }
    }
  }

  void selectAddress(UserAddress address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> addAddress(UserAddress address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _dbService.saveAddress(user.uid, address);
    }
  }

  Future<void> updateAddress(UserAddress address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _dbService.saveAddress(user.uid, address);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _dbService.deleteAddress(user.uid, addressId);
    }
  }

  @override
  void dispose() {
    _addressSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}