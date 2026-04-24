import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../models/credential.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_edit_credential_screen.dart';

class CredentialDetailScreen extends StatefulWidget {
  final Credential credential;

  const CredentialDetailScreen({super.key, required this.credential});

  @override
  State<CredentialDetailScreen> createState() => _CredentialDetailScreenState();
}

class _CredentialDetailScreenState extends State<CredentialDetailScreen> {
  late Credential _credential;
  bool _passwordVisible = false;
  Timer? _hideTimer;
  int _countdown = AppConfig.passwordHideSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _credential = widget.credential;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => _passwordVisible = !_passwordVisible);

    if (_passwordVisible) {
      _countdown = AppConfig.passwordHideSeconds;
      _hideTimer?.cancel();
      _countdownTimer?.cancel();

      _hideTimer = Timer(Duration(seconds: AppConfig.passwordHideSeconds), () {
        if (mounted) setState(() => _passwordVisible = false);
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _countdown--);
        if (_countdown <= 0) {
          t.cancel();
          setState(() {
            _passwordVisible = false;
            _countdown = AppConfig.passwordHideSeconds;
          });
        }
      });
    } else {
      _hideTimer?.cancel();
      _countdownTimer?.cancel();
      _countdown = AppConfig.passwordHideSeconds;
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
    // Auto-clear
    Future.delayed(Duration(seconds: AppConfig.clipboardClearSeconds), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Credential',
            style: GoogleFonts.inter(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
            'Permanently delete "${_credential.title}"? This cannot be undone.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteCredential(_credential.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = _credential.decryptedPassword ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    Expanded(
                      child: Text(
                        _credential.title,
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AddEditCredentialScreen(
                              credential: _credential),
                        )).then((updated) {
                          if (updated is Credential) {
                            setState(() => _credential = updated);
                          }
                        });
                      },
                      icon: const Icon(Icons.edit_rounded,
                          color: AppTheme.primary),
                    ),
                    IconButton(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_rounded,
                          color: AppTheme.danger),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Timestamps
                Text(
                  'Updated ${_formatDate(_credential.updatedAt)}',
                  style: GoogleFonts.inter(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 32),

                // Username
                if (_credential.username != null &&
                    _credential.username!.isNotEmpty)
                  _buildField(
                    label: 'Username',
                    value: _credential.username!,
                    icon: Icons.person_rounded,
                    onCopy: () =>
                        _copyToClipboard(_credential.username!, 'Username'),
                  ),

                const SizedBox(height: 16),

                // Password
                _buildPasswordField(password),

                const SizedBox(height: 16),

                // More Info
                if (_credential.moreInfo != null &&
                    _credential.moreInfo!.isNotEmpty)
                  _buildField(
                    label: 'Notes',
                    value: _credential.moreInfo!,
                    icon: Icons.notes_rounded,
                    showCopy: false,
                  ),

                const SizedBox(height: 24),

                // Security badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.accentGreen.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: AppTheme.accentGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Zero-knowledge encrypted. The backend never sees your password.',
                          style: GoogleFonts.inter(
                              color: AppTheme.accentGreen, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onCopy,
    bool showCopy = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textMuted, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(value,
                    style: GoogleFonts.inter(
                        color: AppTheme.textPrimary, fontSize: 15)),
              ),
              if (showCopy && onCopy != null)
                GestureDetector(
                  onTap: onCopy,
                  child: const Icon(Icons.copy_rounded,
                      color: AppTheme.primary, size: 18),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String password) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Password',
                style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            if (_passwordVisible)
              Text(
                'Hides in ${_countdown}s',
                style: GoogleFonts.inter(
                    color: AppTheme.accentOrange, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _passwordVisible
                    ? AppTheme.primary.withOpacity(0.5)
                    : AppTheme.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded,
                  color: AppTheme.textMuted, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _passwordVisible ? password : '• ' * 12,
                  style: _passwordVisible
                      ? GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        )
                      : const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _togglePasswordVisibility,
                child: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(password, 'Password'),
                child: const Icon(Icons.copy_rounded,
                    color: AppTheme.primary, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
