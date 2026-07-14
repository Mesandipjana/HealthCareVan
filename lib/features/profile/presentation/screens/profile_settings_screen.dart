import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _unitIdCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  String? _loadedUserId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _designationCtrl.dispose();
    _phoneCtrl.dispose();
    _unitIdCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(AuthState authState) {
    final user = authState.user;
    if (user == null || _loadedUserId == user.id) return;
    _loadedUserId = user.id;
    _nameCtrl.text = user.name;
    _designationCtrl.text = user.designation;
    _phoneCtrl.text = user.phone;
    _unitIdCtrl.text = user.unitId ?? '';
    _districtCtrl.text = user.district;
    _stateCtrl.text = user.state;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).updateProfile(
          name: _nameCtrl.text.trim(),
          designation: _designationCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          unitId: _unitIdCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          userState: _stateCtrl.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profile settings saved.' : 'Could not save profile.',
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    _syncControllers(authState);

    if (user == null) {
      return const Center(child: Text('No signed-in user.'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.avatarInitials,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${user.roleLabel} - ${user.email}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Settings',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: user.email,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: user.roleLabel,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon:
                                Icon(Icons.admin_panel_settings_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _designationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Designation',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _unitIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Assigned mobile unit ID',
                            prefixIcon: Icon(Icons.directions_bus_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _responsiveFields([
                          TextFormField(
                            controller: _districtCtrl,
                            decoration: const InputDecoration(
                              labelText: 'District',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),
                          TextFormField(
                            controller: _stateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: authState.isLoading ? null : _save,
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Save Profile'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: authState.isLoading ? null : _signOut,
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _responsiveFields(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: EdgeInsets.only(
                      bottom: child == children.last ? 0 : 14,
                    ),
                    child: child,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          children: children
              .map(
                (child) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: child == children.last ? 0 : 12,
                    ),
                    child: child,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
