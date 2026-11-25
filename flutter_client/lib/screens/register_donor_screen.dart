import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../models/blood_compatibility.dart';
import '../services/api_service.dart';

class RegisterDonorScreen extends StatefulWidget {
  const RegisterDonorScreen({super.key});

  @override
  State<RegisterDonorScreen> createState() => _RegisterDonorScreenState();
}

class _RegisterDonorScreenState extends State<RegisterDonorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();

  String _gender = 'Male';
  String _bloodGroup = 'O+';
  double? _latitude;
  double? _longitude;

  bool _isSubmitting = false;
  bool _isCapturingLocation = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCapturingLocation = true;
      _message = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _message = 'Location services are disabled on this device.';
          _isSuccess = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _message = 'Location permissions denied. You can continue without GPS.';
            _isSuccess = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _message = 'Location permissions permanently denied. You can continue without GPS.';
          _isSuccess = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _message = '✓ GPS Location captured successfully (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Unable to capture GPS: $e. You can continue without GPS.';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isCapturingLocation = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 25,
        'gender': _gender,
        'bloodGroup': _bloodGroup,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'address': _addressController.text.trim(),
        if (_latitude != null && _longitude != null)
          'location': {
            'type': 'Point',
            'coordinates': [_longitude, _latitude],
          },
      };

      await ApiService.registerDonorLegacy(payload);

      setState(() {
        _message = 'Donor registered successfully! Your details have been saved in BloodBridge.';
        _isSuccess = true;
        _nameController.clear();
        _ageController.clear();
        _phoneController.clear();
        _emailController.clear();
        _cityController.clear();
        _pincodeController.clear();
        _addressController.clear();
        _latitude = null;
        _longitude = null;
      });
    } on ApiException catch (e) {
      setState(() {
        _message = e.message;
        _isSuccess = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Registration failed: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🩸 BloodBridge',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Donor Registration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Become a donor and help save lives in medical emergencies.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(labelText: 'Age (18-65) *'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 18 || n > 65) return 'Age 18-65';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: const InputDecoration(labelText: 'Gender *'),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                              DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                            ],
                            onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _bloodGroup,
                      decoration: const InputDecoration(labelText: 'Blood Group *'),
                      items: BloodCompatibility.allBloodGroups
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _bloodGroup = v ?? 'O+'),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        hintText: '10-digit mobile number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || !RegExp(r'^[0-9]{10}$').hasMatch(v.trim())
                              ? 'Enter valid 10-digit number'
                              : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email Address *'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            decoration: const InputDecoration(labelText: 'PIN Code *'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Residential / Street Address *',
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // GPS Location Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GPS Location (Optional)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Capture your coordinates to help hospitals dispatch blood rapidly in nearby emergencies.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.my_location, size: 16),
                            label: Text(_isCapturingLocation ? 'Capturing Location...' : '📍 Capture My Location'),
                            onPressed: _isCapturingLocation ? null : _captureLocation,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_message != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess ? const Color(0xFFDCFCE7) : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isSuccess ? AppTheme.greenSuccess : AppTheme.emergencyRed,
                          ),
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _isSuccess ? AppTheme.greenSuccess : AppTheme.primaryDark,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Register as Donor',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
