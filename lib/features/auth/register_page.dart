
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/resqnet_logo.dart';
import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _organizationController = TextEditingController();
  final _organizationDetailsController = TextEditingController();

  final _authService = AuthService();

  String _role = 'citizen';
  String _verificationIdType = 'Other government ID';
  bool _isAffiliated = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _organizationController.dispose();
    _organizationDetailsController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final organization = _organizationController.text.trim();
    final organizationDetails = _organizationDetailsController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill in all required fields.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must contain at least 6 characters.');
      return;
    }

    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      _showMessage('Please enter a valid phone number.');
      return;
    }

    if (_role == 'volunteer' &&
        _isAffiliated &&
        organization.isEmpty) {
      _showMessage('Please enter your organisation name.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmail(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: _role,
        organization: _isAffiliated ? organization : '',
        organizationDetails:
            _isAffiliated ? organizationDetails : '',
        verificationIdType: _role == 'volunteer'
            ? _verificationIdType
            : '',
      );

      if (!mounted) return;

      _showMessage(
        _role == 'volunteer'
            ? 'Application submitted. Await government approval.'
            : 'Account created successfully!',
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      var message = 'Registration failed.';

      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Please choose a stronger password.';
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Registration failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102A43);
    const teal = Color(0xFF087F8C);
    const red = Color(0xFFEF4444);
    const background = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: navy,
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
          child: Column(
            children: [
              const ResQNetLogo(size: 90),
              const SizedBox(height: 16),
              const Text(
                'Join ResQNet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account to access emergency services.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Register as'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: _inputDecoration(
                        hint: 'Select account type',
                        icon: Icons.person_outline,
                        teal: teal,
                        background: background,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'citizen',
                          child: Text('Citizen'),
                        ),
                        DropdownMenuItem(
                          value: 'volunteer',
                          child: Text('Volunteer'),
                        ),
                      ],
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _role = value);
                              }
                            },
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Full Name'),
                    const SizedBox(height: 8),
                    _field(
                      _nameController,
                      'Enter your full name',
                      Icons.person_outline,
                      teal,
                      background,
                      capitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _field(
                      _emailController,
                      'Enter your email',
                      Icons.email_outlined,
                      teal,
                      background,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    _field(
                      _phoneController,
                      'Enter your phone number',
                      Icons.phone_outlined,
                      teal,
                      background,
                      keyboardType: TextInputType.phone,
                    ),
                    if (_role == 'volunteer') ...[
                      const SizedBox(height: 18),
                      _buildLabel('Affiliated with an organisation?'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<bool>(
                        value: _isAffiliated,
                        decoration: _inputDecoration(
                          hint: 'Select affiliation',
                          icon: Icons.groups_outlined,
                          teal: teal,
                          background: background,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text('Yes'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('No'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _isAffiliated = value);
                                }
                              },
                      ),
                      if (_isAffiliated) ...[
                        const SizedBox(height: 18),
                        _buildLabel('Organisation Name'),
                        const SizedBox(height: 8),
                        _field(
                          _organizationController,
                          'Enter organisation name',
                          Icons.business_outlined,
                          teal,
                          background,
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Organisation Details'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _organizationDetailsController,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            hint: 'Role, address or contact details',
                            icon: Icons.info_outline,
                            teal: teal,
                            background: background,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildLabel('Verification ID Type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _verificationIdType,
                        decoration: _inputDecoration(
                          hint: 'Select ID type',
                          icon: Icons.verified_user_outlined,
                          teal: teal,
                          background: background,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Other government ID',
                            child: Text('Other government ID'),
                          ),
                          DropdownMenuItem(
                            value: 'Organisation ID',
                            child: Text('Organisation ID'),
                          ),
                          DropdownMenuItem(
                            value: 'Volunteer certificate',
                            child: Text('Volunteer certificate'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _verificationIdType = value);
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Do not enter your full Aadhaar number here. '
                        'Your application will be reviewed by the government team.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _field(
                      _passwordController,
                      'Create a password',
                      Icons.lock_outline,
                      teal,
                      background,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 8),
                    _field(
                      _confirmPasswordController,
                      'Re-enter your password',
                      Icons.lock_outline,
                      teal,
                      background,
                      obscure: _obscureConfirmPassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _role == 'volunteer'
                                    ? 'SUBMIT APPLICATION'
                                    : 'CREATE ACCOUNT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon,
    Color teal,
    Color background, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      obscureText: obscure,
      decoration: _inputDecoration(
        hint: hint,
        icon: icon,
        teal: teal,
        background: background,
        suffix: suffix,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF102A43),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color teal,
    required Color background,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: teal),
      suffixIcon: suffix,
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
