import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../config/theme.dart';
import '../models/blood_compatibility.dart';

class CreateRequestDialog extends StatefulWidget {
  const CreateRequestDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const CreateRequestDialog(),
    );
  }

  @override
  State<CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<CreateRequestDialog> {
  final _formKey = GlobalKey<FormState>();

  final _patientNameController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _bloodGroup = 'O+';
  String _urgency = 'Emergency';

  @override
  void initState() {
    super.initState();
    final authUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (authUser != null) {
      if (authUser.city != null) _cityController.text = authUser.city!;
      _phoneController.text = authUser.phone;
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalNameController.dispose();
    _unitsController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to post a blood request.')),
      );
      return;
    }

    final payload = {
      'patientName': _patientNameController.text.trim(),
      'hospitalName': _hospitalNameController.text.trim(),
      'bloodGroup': _bloodGroup,
      'unitsRequired': int.tryParse(_unitsController.text.trim()) ?? 1,
      'urgency': _urgency,
      'city': _cityController.text.trim(),
      'address': _addressController.text.trim(),
      'contactPhone': _phoneController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    final reqProv = Provider.of<RequestProvider>(context, listen: false);
    final success = await reqProv.createRequest(auth.token!, payload);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.greenSuccess,
            content: Text(reqProv.statusMessage ?? 'Blood request posted!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.emergencyRed,
            content: Text(reqProv.errorMessage ?? 'Failed to post blood request.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reqProv = Provider.of<RequestProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🚨 Post Blood Request',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Text(
                  'Matching available donors will be instantly alerted in real-time.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Patient Name & Blood Group
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _patientNameController,
                        decoration: const InputDecoration(labelText: 'Patient Name *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _bloodGroup,
                        decoration: const InputDecoration(labelText: 'Blood *'),
                        items: BloodCompatibility.allBloodGroups
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _bloodGroup = v ?? 'O+'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Units & Urgency
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _unitsController,
                        decoration: const InputDecoration(labelText: 'Units Required *'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final numVal = int.tryParse(v ?? '');
                          if (numVal == null || numVal < 1) return 'Min 1';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _urgency,
                        decoration: const InputDecoration(labelText: 'Urgency Level *'),
                        items: const [
                          DropdownMenuItem(value: 'Normal', child: Text('Normal (Routine)')),
                          DropdownMenuItem(value: 'Emergency', child: Text('🚨 Emergency')),
                          DropdownMenuItem(value: 'Critical', child: Text('⚠️ Critical / Trauma')),
                        ],
                        onChanged: (v) => setState(() => _urgency = v ?? 'Emergency'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Hospital Name
                TextFormField(
                  controller: _hospitalNameController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital Name *',
                    hintText: 'e.g. Apollo Hospital, Lilavati Hospital',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Hospital required' : null,
                ),
                const SizedBox(height: 12),

                // City & Contact Phone
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'City required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Contact Phone *'),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Address / Ward
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital Address / Ward No. *',
                    hintText: 'e.g. ICU Ward 3, 2nd Floor',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Address required' : null,
                ),
                const SizedBox(height: 12),

                // Clinical Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Notes (Optional)',
                    hintText: 'Surgery details, platelet need, replacement terms...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: reqProv.actionLoading ? null : _submit,
                  child: reqProv.actionLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Broadcast Blood Request',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
