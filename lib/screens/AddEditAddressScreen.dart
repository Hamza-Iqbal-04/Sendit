import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart'; // For UserAddress model
import '../providers/AddressProvider.dart';
import '../themes.dart';

class AddEditAddressScreen extends StatefulWidget {
  final UserAddress? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  String _selectedLabel = 'Home'; // Home, Work, Other
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _nameController = TextEditingController(text: addr?.fullName ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _streetController = TextEditingController(text: addr?.street ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _pincodeController = TextEditingController(text: addr?.zipCode ?? '');
    _selectedLabel = addr?.label ?? 'Home';
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen: false because we only need methods, not rebuilds from the provider here
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.background, // Light grey background
      appBar: AppBar(
        title: Text(
          widget.address == null ? "New Address" : "Edit Address",
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Use Current Location" Button (Mock)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Mock functionality - in a real app, use geolocator
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Fetching current location..."), duration: Duration(seconds: 1)),
                            );
                            // Simulate filling data
                            Future.delayed(const Duration(milliseconds: 800), () {
                              if (mounted) {
                                setState(() {
                                  _cityController.text = "Bangalore";
                                  _stateController.text = "Karnataka";
                                  _pincodeController.text = "560001";
                                });
                              }
                            });
                          },
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text("Use Current Location"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppTheme.swiggyOrange.withOpacity(0.5)),
                            foregroundColor: AppTheme.swiggyOrange,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 1: Contact Info
                      Text("CONTACT DETAILS", style: _sectionHeaderStyle),
                      const SizedBox(height: 12),
                      Container(
                        decoration: _cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildModernTextField(
                              controller: _nameController,
                              label: "Full Name",
                              icon: Icons.person_outline_rounded,
                              validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _phoneController,
                              label: "Phone Number",
                              icon: Icons.phone_outlined,
                              inputType: TextInputType.phone,
                              validator: (val) => val != null && val.length == 10 ? null : "Enter valid 10-digit number",
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 2: Address Info
                      Text("ADDRESS DETAILS", style: _sectionHeaderStyle),
                      const SizedBox(height: 12),
                      Container(
                        decoration: _cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildModernTextField(
                              controller: _streetController,
                              label: "House No., Building, Street",
                              icon: Icons.home_work_outlined,
                              maxLines: 2,
                              validator: (val) => val == null || val.isEmpty ? "Street address is required" : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _cityController,
                                    label: "City",
                                    icon: Icons.location_city_rounded,
                                    validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _pincodeController,
                                    label: "Pincode",
                                    icon: Icons.pin_drop_outlined,
                                    inputType: TextInputType.number,
                                    validator: (val) => val != null && val.length == 6 ? null : "Invalid Pincode",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _stateController,
                              label: "State",
                              icon: Icons.map_outlined,
                              validator: (val) => val == null || val.isEmpty ? "Required" : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 3: Save As
                      Text("SAVE AS", style: _sectionHeaderStyle),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildLabelChip("Home", Icons.home_rounded),
                          const SizedBox(width: 12),
                          _buildLabelChip("Work", Icons.work_rounded),
                          const SizedBox(width: 12),
                          _buildLabelChip("Other", Icons.location_on_rounded),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Default Address Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: _cardDecoration,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Set as Default Address", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          value: _isDefault,
                          activeColor: AppTheme.swiggyOrange,
                          trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                          onChanged: (val) => setState(() => _isDefault = val),
                        ),
                      ),
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
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
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _saveAddress(addressProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.swiggyOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SAVE ADDRESS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Styles ---

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 10,
        offset: const Offset(0, 2),
      )
    ],
    border: Border.all(color: Colors.grey.shade100),
  );

  TextStyle get _sectionHeaderStyle => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Colors.grey.shade600,
    letterSpacing: 1.2,
  );

  // --- Widgets ---

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.swiggyOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade200),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade500),
        floatingLabelStyle: const TextStyle(color: AppTheme.swiggyOrange, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLabelChip(String label, IconData icon) {
    final isSelected = _selectedLabel == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedLabel = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.swiggyOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.swiggyOrange : Colors.grey.shade300,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppTheme.swiggyOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic ---

  Future<void> _saveAddress(AddressProvider addressProvider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final newAddress = UserAddress(
        id: widget.address?.id ?? '', // Let Firestore generate ID if empty
        label: _selectedLabel,
        fullName: _nameController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _pincodeController.text.trim(),
        phone: _phoneController.text.trim(),
        isDefault: _isDefault,
      );

      if (widget.address == null) {
        await addressProvider.addAddress(newAddress);
      } else {
        await addressProvider.updateAddress(newAddress);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}