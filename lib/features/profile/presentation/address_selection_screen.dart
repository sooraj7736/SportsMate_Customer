import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/core/widgets/location_picker.dart';
import 'package:sportsmate/features/profile/data/profile_repository.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  ConsumerState<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends ConsumerState<AddressSelectionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressTextController = TextEditingController();

  Future<void> _addAddress(Athlete athlete, double lat, double lng) async {
    final name = _nameController.text.trim();
    final addressText = _addressTextController.text.trim();
    if (name.isEmpty || addressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and address')));
      return;
    }

    final existingAddresses = ref.read(userAddressesStreamProvider).value ?? [];
    final isActive = existingAddresses.isEmpty;

    final id = FirebaseFirestore.instance.collection('addresses').doc().id;
    await FirebaseFirestore.instance.collection('addresses').doc(id).set({
      'uid': athlete.uid,
      'name': name,
      'addressText': addressText,
      'lat': lat,
      'lng': lng,
      'isActive': isActive,
    });

    if (mounted) {
      Navigator.pop(context); // close bottom sheet
      _nameController.clear();
      _addressTextController.clear();
    }
  }

  Future<void> _selectAddress(String selectedAddressId) async {
    final existingAddresses = ref.read(userAddressesStreamProvider).value ?? [];
    final batch = FirebaseFirestore.instance.batch();
    for (final addr in existingAddresses) {
      final addrId = addr['id'] as String;
      batch.update(
        FirebaseFirestore.instance.collection('addresses').doc(addrId),
        {'isActive': addrId == selectedAddressId},
      );
    }
    await batch.commit();
  }

  void _showAddAddressSheet(Athlete athlete) {
    double? selectedLat;
    double? selectedLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add New Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Address Label (e.g. Home, Work)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressTextController,
                decoration: const InputDecoration(labelText: "Address Details", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPicker(
                        onLocationSelected: (lat, lng) {
                          setSheetState(() {
                            selectedLat = lat;
                            selectedLng = lng;
                          });
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: Text(selectedLat != null ? "Location Selected on Map" : "Pick Location on Map"),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedLat == null ? null : () => _addAddress(athlete, selectedLat!, selectedLng!),
                  child: const Text("Save Address"),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final userAddressesAsync = ref.watch(userAddressesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("My Addresses")),
      body: userProfileAsync.when(
        data: (athlete) {
          if (athlete == null) return const Center(child: Text("Profile not found"));

          return userAddressesAsync.when(
            data: (addressesList) {
              return Column(
                children: [
                  Expanded(
                    child: addressesList.isEmpty
                        ? const Center(child: Text("No addresses added yet."))
                        : ListView.builder(
                            itemCount: addressesList.length,
                            itemBuilder: (context, index) {
                              final address = addressesList[index];
                              final addressId = address['id'] as String? ?? '';
                              final isActive = address['isActive'] as bool? ?? false;
                              return ListTile(
                                title: Text(address['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(address['addressText'] ?? ''),
                                leading: Icon(
                                  isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isActive ? Colors.blue : Colors.grey,
                                ),
                                onTap: () => _selectAddress(addressId),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddAddressSheet(athlete),
                      icon: const Icon(Icons.add),
                      label: const Text("Add New Address"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error loading addresses: $err")),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
