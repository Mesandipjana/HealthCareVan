import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _unitIdCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  String _selectedRole = AppConstants.roleOfficer;
  bool _isCreatingAccount = false;
  bool _obscurePassword = true;

  static const _demoAccounts = [
    {
      'role': 'Admin',
      'email': 'admin@healthcare.org',
      'password': 'Admin@123',
      'color': AppColors.adminColor,
      'icon': Icons.admin_panel_settings,
    },
    {
      'role': 'Coordinator',
      'email': 'coordinator@healthcare.org',
      'password': 'Coord@123',
      'color': AppColors.coordinatorColor,
      'icon': Icons.supervisor_account,
    },
    {
      'role': 'Doctor/Nurse',
      'email': 'officer@healthcare.org',
      'password': 'Officer@123',
      'color': AppColors.officerColor,
      'icon': Icons.medical_services,
    },
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _designationCtrl.dispose();
    _phoneCtrl.dispose();
    _unitIdCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).signIn(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _signInDemo(Map<String, Object> account) async {
    final success = await ref.read(authProvider.notifier).signInWithDemoAccount(
          account['email'] as String,
          account['password'] as String,
        );
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).createAccount(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _selectedRole,
          designation: _designationCtrl.text.trim().isEmpty
              ? AppConstants.roleLabels[_selectedRole] ?? 'Healthcare User'
              : _designationCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          unitId: _unitIdCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          userState: _stateCtrl.text.trim(),
        );
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null && ModalRoute.of(context)?.isCurrent == true) {
        context.go('/dashboard');
      }
    });

    final authState = ref.watch(authProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isMobile ? _buildMobile(authState) : _buildDesktop(authState),
    );
  }

  Widget _buildDesktop(AuthState authState) {
    return Row(
      children: [
        // Left Panel — Branding
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2044),
                  Color(0xFF1565C0),
                  Color(0xFF0288D1)
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      const AppLogoMark(size: 48, elevated: true),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HealthOps',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          Text('Mobile Healthcare Platform',
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Powering Community\nHealth Operations',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'A unified platform for managing mobile healthcare units,\nfield activities, service delivery, and analytics.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildFeatureRow(
                      Icons.directions_bus, 'Mobile Unit Tracking'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.map, 'GPS Field Verification'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.analytics, 'Real-time Analytics'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.inventory_2, 'Inventory Monitoring'),
                  const Spacer(),
                  Text(
                    '© 2024 Healthcare Operations Platform. All rights reserved.',
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right Panel — Login Form
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(_isCreatingAccount ? 'Create Account' : 'Sign In',
                        style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(
                        _isCreatingAccount
                            ? 'Choose a role to set feature access'
                            : 'Enter your credentials to access the platform',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 32),
                    _buildForm(authState),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Row(
            children: [
              const AppLogoMark(size: 44, elevated: true),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HealthOps',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('Mobile Healthcare Platform',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          Text(_isCreatingAccount ? 'Create Account' : 'Sign In',
              style:
                  GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              _isCreatingAccount
                  ? 'Choose your role'
                  : 'Enter your credentials',
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 28),
          _buildForm(authState),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (authState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.errorLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.errorLight, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authState.errorMessage!,
                      style: GoogleFonts.inter(
                          color: AppColors.errorLight, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isCreatingAccount) ...[
            Text('Full Name',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter full name',
                prefixIcon: Icon(Icons.person_outline, size: 18),
              ),
              validator: (v) => !_isCreatingAccount
                  ? null
                  : (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
            ),
            const SizedBox(height: 16),
            Text('Role',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 18),
              ),
              items: AppConstants.roleLabels.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedRole = value;
                  if (_designationCtrl.text.trim().isEmpty) {
                    _designationCtrl.text =
                        AppConstants.roleLabels[value] ?? 'Healthcare User';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          Text('Email Address',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Email is required' : null,
          ),
          const SizedBox(height: 16),
          if (_isCreatingAccount) ...[
            Text('Designation',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _designationCtrl,
              decoration: const InputDecoration(
                hintText: 'Program Coordinator, Doctor, Nurse, etc.',
                prefixIcon: Icon(Icons.badge_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            Text('Phone',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            Text('Assigned Unit ID',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _unitIdCtrl,
              decoration: const InputDecoration(
                hintText: 'Optional, e.g. unit_001',
                prefixIcon: Icon(Icons.directions_bus_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _districtCtrl,
                    decoration: const InputDecoration(
                      hintText: 'District',
                      prefixIcon: Icon(Icons.location_city_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateCtrl,
                    decoration: const InputDecoration(
                      hintText: 'State',
                      prefixIcon: Icon(Icons.map_outlined, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text('Password',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outlined, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (_isCreatingAccount && v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onFieldSubmitted: (_) =>
                _isCreatingAccount ? _createAccount() : _signIn(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : (_isCreatingAccount ? _createAccount : _signIn),
              child: authState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(_isCreatingAccount ? 'Create Account' : 'Sign In',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          if (!_isCreatingAccount) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 26),
                label: Text('Continue with Google',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 18),
            _buildDemoAccounts(authState),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: authState.isLoading
                  ? null
                  : () {
                      setState(() {
                        _isCreatingAccount = !_isCreatingAccount;
                        if (_isCreatingAccount &&
                            _designationCtrl.text.trim().isEmpty) {
                          _designationCtrl.text =
                              AppConstants.roleLabels[_selectedRole] ??
                                  'Healthcare User';
                        }
                      });
                    },
              child: Text(
                _isCreatingAccount
                    ? 'Already have an account? Sign in'
                    : 'Create an account with a role',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccounts(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Demo Accounts',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns = constraints.maxWidth >= 360;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _demoAccounts.map((account) {
                final width = useTwoColumns
                    ? (constraints.maxWidth - 8) / 2
                    : constraints.maxWidth;
                final color = account['color'] as Color;
                return SizedBox(
                  width: width,
                  child: OutlinedButton(
                    onPressed:
                        authState.isLoading ? null : () => _signInDemo(account),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      side: BorderSide(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(account['icon'] as IconData,
                            color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account['role'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              Text(
                                account['email'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
