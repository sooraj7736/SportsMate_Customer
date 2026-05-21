import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/tournament/data/tournament_repository.dart';
import 'package:sportsmate/features/tournament/domain/tournament_entity.dart';
import 'package:sportsmate/core/widgets/location_picker.dart';
import 'package:sportsmate/features/sports/data/sports_catalog.dart';
import 'package:intl/intl.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends ConsumerState<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _maxTeamsController = TextEditingController();
  final TextEditingController _minPlayersController = TextEditingController(text: '5');
  final TextEditingController _ageRestrictionController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _prizePoolController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _customAddressController = TextEditingController();

  String _selectedSport = '';
  String? _selectedLocationId;
  List<Map<String, dynamic>> _availableTurfs = [];
  bool _isOtherLocation = false;
  double? _latitude;
  double? _longitude;
  DateTime? _startDate;
  DateTime? _endDate;
  File? _posterImage;
  bool _isBoosted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTurfs();
  }

  Future<void> _fetchTurfs() async {
    try {
      final turfs = await ref.read(tournamentRepositoryProvider).getAvailableTurfs();
      if (mounted) {
        setState(() {
          _availableTurfs = turfs;
          if (turfs.isNotEmpty) {
            _selectedLocationId = turfs.first['id'] as String;
            _isOtherLocation = false;
          } else {
            _selectedLocationId = 'other';
            _isOtherLocation = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedLocationId = 'other';
          _isOtherLocation = true;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _posterImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end dates')));
      return;
    }
    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start date cannot be after end date')));
      return;
    }

    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User profile not found')));
      return;
    }

    final sportsAsync = ref.read(sportsCatalogProvider);
    final availableSports = sportsAsync.asData?.value ?? const [];
    final sportNames = availableSports.isNotEmpty ? availableSports.map((sport) => sport.name).toList() : ['Football'];
    final selectedSport = sportNames.contains(_selectedSport) ? _selectedSport : sportNames.first;

    setState(() {
      _isLoading = true;
    });

    try {
      String posterUrl = '';
      if (_posterImage != null) {
        posterUrl = await ref.read(tournamentRepositoryProvider).uploadPosterImage(userProfile.uid, _posterImage!);
      }

      String locationName = '';
      String? turfId;
      String? customAddress;
      bool isVerifiedTurf = false;

      if (_isOtherLocation) {
        locationName = _customAddressController.text.trim();
        customAddress = locationName;
      } else {
        final turf = _availableTurfs.firstWhere((t) => t['id'] == _selectedLocationId, orElse: () => {'name': 'Unknown Turf'});
        locationName = turf['name'] ?? 'Unknown Turf';
        turfId = turf['id'];
        isVerifiedTurf = turf['isVerified'] ?? false;
      }

      final tournament = TournamentEntity(
        id: '',
        hostUid: userProfile.uid,
        hostName: userProfile.name,
        sport: selectedSport,
        tournamentName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        posterUrl: posterUrl,
        maxTeams: int.tryParse(_maxTeamsController.text.trim()) ?? 0,
        registeredTeams: [],
        ageRestriction: _ageRestrictionController.text.trim(),
        registrationFee: double.tryParse(_feeController.text.trim()) ?? 0.0,
        startDate: _startDate!,
        endDate: _endDate!,
        location: locationName,
        turfId: turfId,
        customAddress: customAddress,
        lat: _latitude,
        lng: _longitude,
        isVerifiedTurf: isVerifiedTurf,
        prizePool: _prizePoolController.text.trim(),
        rules: _rulesController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        isBoosted: _isBoosted,
        status: 'Open',
        minPlayersPerTeam: int.tryParse(_minPlayersController.text.trim()) ?? 5,
      );

      await ref.read(tournamentRepositoryProvider).addTournament(tournament);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament created successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create tournament: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sportsAsync = ref.watch(sportsCatalogProvider);
    final availableSports = sportsAsync.asData?.value ?? const [];
    final sportNames = availableSports.isNotEmpty ? availableSports.map((sport) => sport.name).toList() : ['Football'];
    final selectedSport = sportNames.contains(_selectedSport) ? _selectedSport : sportNames.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host a Tournament'),
        elevation: 0.5,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: _posterImage != null 
                          ? DecorationImage(image: FileImage(_posterImage!), fit: BoxFit.cover) 
                          : null,
                      ),
                      child: _posterImage == null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey.shade500),
                              const SizedBox(height: 8),
                              Text('Add Tournament Poster', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedSport,
                    decoration: const InputDecoration(
                      labelText: 'Sport',
                      border: OutlineInputBorder(),
                    ),
                    items: sportNames.map((sport) => DropdownMenuItem(value: sport, child: Text(sport))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSport = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tournament Name', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maxTeamsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Teams',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _minPlayersController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min Players / Team',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed <= 0) return 'Must be > 0';
                            if (parsed > 15) return 'Max is 15';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _feeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Entry Fee (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _ageRestrictionController,
                          decoration: const InputDecoration(
                            labelText: 'Age Restriction',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedLocationId != null)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedLocationId,
                      decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                      items: [
                        ..._availableTurfs.map((turf) {
                          final isVerified = turf['isVerified'] == true;
                          return DropdownMenuItem<String>(
                            value: turf['id'] as String,
                            child: Row(
                              children: [
                                Expanded(child: Text(turf['name'] ?? 'Turf', overflow: TextOverflow.ellipsis)),
                                if (isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                                ]
                              ],
                            ),
                          );
                        }),
                        const DropdownMenuItem<String>(value: 'other', child: Text('Other (Custom Map / Address)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedLocationId = val;
                          _isOtherLocation = val == 'other';
                        });
                      },
                    ),
                  if (_isOtherLocation) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customAddressController,
                      decoration: const InputDecoration(labelText: 'Custom Address / Map Details', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map)),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPicker(
                              onLocationSelected: (lat, lng) {
                                setState(() {
                                  _latitude = lat;
                                  _longitude = lng;
                                  _customAddressController.text = "Map Location Selected";
                                });
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: Text(_latitude != null ? "Location Selected on Map" : "Pick Location on Map"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _latitude != null ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _prizePoolController,
                    decoration: const InputDecoration(labelText: 'Prize Pool (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rulesController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Rules & Regulations (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact Phone Number', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Start Date'),
                          subtitle: Text(_startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Select Date'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('End Date'),
                          subtitle: Text(_endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select Date'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Boost Tournament', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Reach more players in your area (Extra charges apply)'),
                    value: _isBoosted,
                    onChanged: (val) => setState(() => _isBoosted = val),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Create Tournament', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }
}
