import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../services/auth_service.dart';
import '../services/encryption_service.dart';
import '../theme/app_theme.dart';
import 'otp_screen.dart';
import 'vault_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureMaster = true;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _masterCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  int _masterStrength = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();

    _masterCtrl.addListener(() {
      setState(() {
        _masterStrength = EncryptionService.passwordStrength(_masterCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _masterCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await AuthService.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          masterPassword: _masterCtrl.text,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VaultListScreen()),
        );
      } else {
        final result = await AuthService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          masterPassword: _masterCtrl.text,
        );

        if (!mounted) return;
        if (result.response.user != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                email: _emailCtrl.text.trim(),
                masterPassword: _masterCtrl.text,
                salt: result.salt,
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                _buildHeader(),
                const SizedBox(height: 48),
                _buildForm(),
                const SizedBox(height: 28),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.ink,
                      strokeWidth: 2,
                    ),
                  )
                else
                  _buildSubmitButton(),
                const SizedBox(height: 20),
                _buildToggle(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ink circle with shield — Mastercard circle motif
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('assets/app_icon.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppConfig.appName,
          style: GoogleFonts.sofiaSans(
            color: AppTheme.ink,
            fontSize: 36,
            fontWeight: FontWeight.w500,
            letterSpacing: -1.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Welcome back. Your secrets are safe.'
              : 'Create your zero-knowledge vault.',
          style: GoogleFonts.sofiaSans(
            color: AppTheme.slate,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          _buildField(
            controller: _emailCtrl,
            label: 'Email Address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w.+-]+@[\w-]+\.\w+$').hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Account password (Supabase)
          _buildField(
            controller: _passwordCtrl,
            label: 'Account Password',
            icon: Icons.key_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (!_isLogin && v.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Master password (encryption key)
          _buildField(
            controller: _masterCtrl,
            label: 'Master Password (Encryption Key)',
            icon: Icons.lock_rounded,
            obscureText: _obscureMaster,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureMaster
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textMuted,
              ),
              onPressed: () => setState(() => _obscureMaster = !_obscureMaster),
            ),
            helperText: '⚠️ NEVER stored anywhere. Forgotten = lost data.',
            validator: (v) {
              if (v == null || v.isEmpty) return 'Master password is required';
              if (v.length < AppConfig.minMasterPasswordLength) {
                return 'Minimum ${AppConfig.minMasterPasswordLength} characters required';
              }
              return null;
            },
          ),
          // Strength indicator (sign up only)
          if (!_isLogin && _masterCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildStrengthIndicator(),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildError(_errorMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.sofiaSans(color: AppTheme.ink, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.sofiaSans(color: AppTheme.slate, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.slate, size: 20),
        suffixIcon: suffixIcon,
        helperText: helperText,
        helperStyle: GoogleFonts.sofiaSans(
          color: AppTheme.signalOrange,
          fontSize: 11,
        ),
        helperMaxLines: 2,
        filled: true,
        fillColor: AppTheme.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0x33141413), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0x22141413), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppTheme.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildStrengthIndicator() {
    const labels = ['Very Weak', 'Weak', 'Fair', 'Strong', 'Very Strong'];
    // Mastercard palette: no neons — use ink progression
    final colors = [
      AppTheme.danger,
      AppTheme.signalOrange,
      AppTheme.arcOrange,
      const Color(0xFF2E7D32),
      AppTheme.ink,
    ];
    final level = _masterStrength.clamp(0, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= level ? colors[level] : const Color(0xFFE2DDD9),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Strength: ${labels[level]}',
          style: GoogleFonts.sofiaSans(
            color: colors[level],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.sofiaSans(
                color: AppTheme.danger,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.ink,
        foregroundColor: AppTheme.canvas,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        textStyle: GoogleFonts.sofiaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.32,
        ),
      ),
      child: Text(_isLogin ? 'Unlock Vault' : 'Create Account'),
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: GoogleFonts.sofiaSans(color: AppTheme.slate, fontSize: 14),
        ),
        TextButton(
          onPressed: _toggleMode,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.ink,
            textStyle: GoogleFonts.sofiaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.28,
              decoration: TextDecoration.underline,
            ),
          ),
          child: Text(_isLogin ? 'Sign Up' : 'Sign In'),
        ),
      ],
    );
  }
}
