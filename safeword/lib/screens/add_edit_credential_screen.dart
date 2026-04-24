import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/credential.dart';
import '../services/api_service.dart';
import '../services/encryption_service.dart';
import '../theme/app_theme.dart';

class AddEditCredentialScreen extends StatefulWidget {
  final Credential? credential; // null = add mode
  final String? initialCategory;

  const AddEditCredentialScreen({
    super.key,
    this.credential,
    this.initialCategory,
  });

  @override
  State<AddEditCredentialScreen> createState() =>
      _AddEditCredentialScreenState();
}

class _AddEditCredentialScreenState extends State<AddEditCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _moreInfoCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  int _passwordStrength = 0;

  bool get _isEdit => widget.credential != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final c = widget.credential!;
      _titleCtrl.text = c.title;
      _usernameCtrl.text = c.username ?? '';
      _categoryCtrl.text = c.category ?? '';
      _passwordCtrl.text = c.decryptedPassword ?? '';
      _moreInfoCtrl.text = c.moreInfo ?? '';
    } else if (widget.initialCategory != null) {
      _categoryCtrl.text = widget.initialCategory!;
    }

    _passwordCtrl.addListener(() {
      setState(() {
        _passwordStrength =
            EncryptionService.passwordStrength(_passwordCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _moreInfoCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final pwd = EncryptionService.generatePassword(
      length: 20,
      includeUppercase: true,
      includeDigits: true,
      includeSymbols: true,
    );
    setState(() {
      _passwordCtrl.text = pwd;
      _obscurePassword = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Strong password generated!')),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Credential saved;
      if (_isEdit) {
        saved = await ApiService.updateCredential(
          id: widget.credential!.id,
          title: _titleCtrl.text.trim(),
          username: _usernameCtrl.text.trim().isEmpty
              ? null
              : _usernameCtrl.text.trim(),
          plainPassword: _passwordCtrl.text,
          moreInfo: _moreInfoCtrl.text.trim().isEmpty
              ? null
              : _moreInfoCtrl.text.trim(),
          category: _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
        );
      } else {
        saved = await ApiService.createCredential(
          title: _titleCtrl.text.trim(),
          username: _usernameCtrl.text.trim().isEmpty
              ? null
              : _usernameCtrl.text.trim(),
          plainPassword: _passwordCtrl.text,
          moreInfo: _moreInfoCtrl.text.trim().isEmpty
              ? null
              : _moreInfoCtrl.text.trim(),
          category: _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Credential updated!' : 'Credential saved!'),
          backgroundColor: AppTheme.accentGreen.withOpacity(0.8),
        ),
      );
      Navigator.of(context).pop(saved);
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Header
              Row(
                children: [
                  // Circular back button — satellite CTA style
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFE2DDD9)),
                        color: AppTheme.white,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.ink, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Credential' : 'New Credential',
                      style: GoogleFonts.sofiaSans(
                        color: AppTheme.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.44,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      controller: _titleCtrl,
                      label: 'Title *',
                      icon: Icons.label_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _usernameCtrl,
                      label: 'Username / Email',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _categoryCtrl,
                      label: 'Category (optional)',
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildPasswordField(),
                    if (_passwordCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildStrengthBar(),
                    ],
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _moreInfoCtrl,
                      label: 'Notes (optional)',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDED),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppTheme.danger.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.danger, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_error!,
                                  style: GoogleFonts.sofiaSans(
                                      color: AppTheme.danger, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.ink, strokeWidth: 2))
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: Icon(
                              _isEdit
                                  ? Icons.save_outlined
                                  : Icons.add_rounded,
                              size: 20),
                          label: Text(
                            _isEdit
                                ? 'Update Credential'
                                : 'Save Credential',
                            style: GoogleFonts.sofiaSans(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                letterSpacing: -0.32),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.ink,
                            foregroundColor: AppTheme.canvas,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.sofiaSans(color: AppTheme.ink, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.sofiaSans(color: AppTheme.slate, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.slate, size: 20),
        filled: true,
        fillColor: AppTheme.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 999),
          borderSide:
              const BorderSide(color: Color(0x22141413), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 999),
          borderSide:
              const BorderSide(color: Color(0x22141413), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 999),
          borderSide: const BorderSide(color: AppTheme.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 999),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      style: GoogleFonts.sofiaSans(color: AppTheme.ink, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Password *',
        labelStyle: GoogleFonts.sofiaSans(color: AppTheme.slate, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppTheme.slate, size: 20),
        filled: true,
        fillColor: AppTheme.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide:
              const BorderSide(color: Color(0x22141413), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide:
              const BorderSide(color: Color(0x22141413), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppTheme.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.slate,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined,
                  color: AppTheme.ink, size: 20),
              tooltip: 'Generate secure password',
              onPressed: _generatePassword,
            ),
          ],
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        return null;
      },
    );
  }

  Widget _buildStrengthBar() {
    final colors = [
      AppTheme.danger,
      AppTheme.signalOrange,
      AppTheme.arcOrange,
      const Color(0xFF2E7D32),
      AppTheme.ink,
    ];
    const labels = ['Very Weak', 'Weak', 'Fair', 'Strong', 'Very Strong'];
    final level = _passwordStrength.clamp(0, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 4 ? 3 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= level
                      ? colors[level]
                      : const Color(0xFFE2DDD9),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Strength: ${labels[level]}',
                style: GoogleFonts.sofiaSans(
                    color: colors[level], fontSize: 11,
                    fontWeight: FontWeight.w500)),
            TextButton.icon(
              onPressed: _generatePassword,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Regenerate',
                  style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                  foregroundColor: AppTheme.ink,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ],
        ),
      ],
    );
  }
}
