import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../view_models/app_state_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'manager@sari-safety.io');
  final _passwordController = TextEditingController(text: '••••••••');
  UserRole _selectedRole = UserRole.facilityManager;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _busy = false;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty || _busy) return;

    setState(() => _busy = true);
    final state = context.read<AppStateViewModel>();
    final ok = await state.login(email, pass, _selectedRole, isSignUp: _isSignUp);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.dangerRed, content: Text(state.tr('authFailed'))),
      );
    }
  }

  void _fillDemo(UserRole role, String email) {
    setState(() {
      _selectedRole = role;
      _emailController.text = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateViewModel>();
    final isArabic = state.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Language Switcher Banner Header
                Align(
                  alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: InkWell(
                    onTap: () => state.toggleLanguage(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language_rounded, size: 16, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Text(
                            isArabic ? 'English' : 'العربية',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Official SARI Logo Header
                Center(
                  child: Image.asset(
                    'assets/images/sari_logo.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    state.tr('appTitle'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    state.tr('appSubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Auth Mode Toggle
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(state.tr('signIn'))),
                        selected: !_isSignUp,
                        onSelected: (val) => setState(() => _isSignUp = false),
                        selectedColor: AppColors.primaryBlue,
                        backgroundColor: AppColors.darkSurface,
                        labelStyle: TextStyle(
                          color: !_isSignUp ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(state.tr('register'))),
                        selected: _isSignUp,
                        onSelected: (val) => setState(() => _isSignUp = true),
                        selectedColor: AppColors.primaryBlue,
                        backgroundColor: AppColors.darkSurface,
                        labelStyle: TextStyle(
                          color: _isSignUp ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Role selector
                Text(
                  state.tr('selectRole'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  dropdownColor: AppColors.cardBg,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(role.displayName),
                    );
                  }).toList(),
                  onChanged: (role) {
                    if (role != null) setState(() => _selectedRole = role);
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: state.tr('email'),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryBlue),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: state.tr('password'),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main Submit Button
                ElevatedButton(
                  onPressed: _busy ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    _isSignUp ? state.tr('createAccount') : state.tr('accessDashboard'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: 12),

                // Quick Demo Logins
                Center(
                  child: Text(
                    state.tr('quickDemo'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Facility Manager', style: TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.darkSurface,
                      onPressed: () => _fillDemo(UserRole.facilityManager, 'manager@sari-facility.io'),
                    ),
                    ActionChip(
                      label: const Text('Residential', style: TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.darkSurface,
                      onPressed: () => _fillDemo(UserRole.residential, 'homeowner@sari-home.io'),
                    ),
                    ActionChip(
                      label: const Text('Admin', style: TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.darkSurface,
                      onPressed: () => _fillDemo(UserRole.admin, 'admin@sari-system.io'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
