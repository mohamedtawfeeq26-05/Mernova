import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import '../models/blood_compatibility.dart';

class AuthDialog extends StatefulWidget {
  final String initialMode; // 'login' or 'register'
  final String initialRole; // 'donor', 'requester', 'admin'

  const AuthDialog({
    super.key,
    this.initialMode = 'login',
    this.initialRole = 'donor',
  });

  static Future<void> show(
    BuildContext context, {
    String mode = 'login',
    String role = 'donor',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AuthDialog(initialMode: mode, initialRole: role),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _formKey = GlobalKey<FormState>();

  late bool _isLogin;
  late String _role;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController(text: '25');
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _bloodGroup = 'O+';
  String _gender = 'Male';

  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialMode == 'login';
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _fillPreset(String presetRole, String email, String password) {
    setState(() {
      _isLogin = true;
      _role = presetRole;
      _emailController.text = email;
      _passwordController.text = password;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  bool _validatePhone(String phone) {
    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone);
  }

  bool _validatePassword(String pass) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$')
        .hasMatch(pass);
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_isLogin) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter your full name.');
        return;
      }
      if (!_validatePhone(_phoneController.text.trim())) {
        setState(() => _errorMessage =
            'Please enter a valid 10-digit Indian mobile number starting with 6, 7, 8 or 9.');
        return;
      }
      if (!_validatePassword(_passwordController.text)) {
        setState(() => _errorMessage =
            'Password must contain at least 8 characters, one uppercase letter, one lowercase letter, one number and one special character.');
        return;
      }
    } else {
      if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
        setState(() => _errorMessage = 'Please enter both email and password.');
        return;
      }
    }

    setState(() => _isLoading = true);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    bool success = false;
    if (_isLogin) {
      success = await authProv.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
    } else {
      final payload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
        'role': _role,
        'bloodGroup': _role == 'donor' ? _bloodGroup : null,
        'age': int.tryParse(_ageController.text),
        'gender': _role == 'donor' ? _gender : null,
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      };
      success = await authProv.register(payload);
    }

    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _successMessage = 'Authentication successful! Welcome, ${authProv.user?.name}';
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() {
        _errorMessage = authProv.authError ?? 'Authentication failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🩸 BloodBridge Access',
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
                'Login or Register with Role-Based Access Control',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // One-Click Evaluation Presets
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ One-Click Evaluation Login:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip(
                          label: '🛡️ Admin',
                          color: const Color(0xFF6B21A8),
                          onTap: () => _fillPreset(
                            'admin',
                            'admin@bloodbridge.org',
                            'AdminPassword@123',
                          ),
                        ),
                        _buildPresetChip(
                          label: '🩸 Donor (O+)',
                          color: AppTheme.primary,
                          onTap: () => _fillPreset(
                            'donor',
                            'rahul.donor@bloodbridge.org',
                            'Password@123',
                          ),
                        ),
                        _buildPresetChip(
                          label: '🏥 Hospital',
                          color: const Color(0xFF0284C7),
                          onTap: () => _fillPreset(
                            'requester',
                            'apollo.mumbai@bloodbridge.org',
                            'Password@123',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mode Tabs: Sign In / Create Account
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isLogin ? AppTheme.primaryLight : Colors.transparent,
                        side: BorderSide(
                          color: _isLogin ? AppTheme.primary : AppTheme.borderSubtle,
                        ),
                      ),
                      onPressed: () => setState(() {
                        _isLogin = true;
                        _errorMessage = null;
                        _successMessage = null;
                      }),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: _isLogin ? AppTheme.primaryDark : AppTheme.textSecondary,
                          fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !_isLogin ? AppTheme.primaryLight : Colors.transparent,
                        side: BorderSide(
                          color: !_isLogin ? AppTheme.primary : AppTheme.borderSubtle,
                        ),
                      ),
                      onPressed: () => setState(() {
                        _isLogin = false;
                        _errorMessage = null;
                        _successMessage = null;
                      }),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: !_isLogin ? AppTheme.primaryDark : AppTheme.textSecondary,
                          fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Role Selector Pills
              const Text(
                'Selected Role:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildRolePill('donor', '🩸 Blood Donor'),
                  const SizedBox(width: 6),
                  _buildRolePill('requester', '🏥 Requester'),
                  const SizedBox(width: 6),
                  _buildRolePill('admin', '🛡️ Admin'),
                ],
              ),
              const SizedBox(height: 16),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name *'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email Address *'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password *'),
                      obscureText: true,
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '• Min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special symbol',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number (10 digits) *',
                          hintText: 'e.g. 9876543210',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      if (_role == 'donor') ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _bloodGroup,
                                decoration: const InputDecoration(labelText: 'Blood Group *'),
                                items: BloodCompatibility.allBloodGroups
                                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                    .toList(),
                                onChanged: (v) => setState(() => _bloodGroup = v ?? 'O+'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                decoration: const InputDecoration(labelText: 'Age *'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(labelText: 'City *'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeController,
                              decoration: const InputDecoration(labelText: 'PIN Code'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address / Area'),
                      ),
                    ],
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.emergencyRed),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.primaryDark, fontSize: 13),
                  ),
                ),
              ],

              if (_successMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.greenSuccess),
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: AppTheme.greenSuccess, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isLogin ? 'Sign In as $_role' : 'Register as $_role',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolePill(String roleKey, String label) {
    final isSelected = _role == roleKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = roleKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.scaffoldBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryDark : AppTheme.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
