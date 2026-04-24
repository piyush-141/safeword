import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../models/credential.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/credential_card.dart';
import 'add_edit_credential_screen.dart';
import 'category_detail_screen.dart';
import 'credential_detail_screen.dart';
import 'lock_screen.dart';
import 'login_screen.dart';

class VaultListScreen extends StatefulWidget {
  const VaultListScreen({super.key});

  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen>
    with WidgetsBindingObserver {
  List<Credential> _credentials = [];
  bool _isLoading = true;
  String? _error;

  final _searchCtrl = TextEditingController();
  Timer? _inactivityTimer;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _resetInactivityTimer();

    _searchCtrl.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _load(search: _searchCtrl.text.trim());
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (!AuthService.isUnlocked) {
        _navigateToLock();
      } else {
        _resetInactivityTimer();
      }
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      Duration(seconds: AppConfig.autoLockSeconds),
      _navigateToLock,
    );
  }

  void _navigateToLock() {
    AuthService.lock();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LockScreen()),
      (_) => false,
    );
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final creds = await ApiService.getCredentials(search: search);
      if (mounted) setState(() => _credentials = creds);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(Credential cred) async {
    try {
      await ApiService.deleteCredential(cred.id);
      if (mounted) {
        setState(() => _credentials.removeWhere((c) => c.id == cred.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${cred.title}" deleted'),
            backgroundColor: AppTheme.danger.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _copyPassword(Credential cred) async {
    _resetInactivityTimer();
    final pwd = cred.decryptedPassword ?? '';
    await Clipboard.setData(ClipboardData(text: pwd));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.accentGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              'Password copied — clears in ${AppConfig.clipboardClearSeconds}s',
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
            ),
          ],
        ),
        duration: Duration(seconds: AppConfig.clipboardClearSeconds),
        action: SnackBarAction(
          label: 'Clear Now',
          textColor: AppTheme.accentOrange,
          onPressed: () => Clipboard.setData(const ClipboardData(text: '')),
        ),
      ),
    );

    // Auto-clear clipboard
    Future.delayed(Duration(seconds: AppConfig.clipboardClearSeconds), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openAddEdit({Credential? credential, String? initialCategory}) {
    _resetInactivityTimer();
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => AddEditCredentialScreen(
            credential: credential,
            initialCategory: initialCategory,
          ),
        ))
        .then((_) => _load());
  }

  void _openDetail(Credential credential) {
    _resetInactivityTimer();
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => CredentialDetailScreen(credential: credential),
        ))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      child: Scaffold(
        backgroundColor: AppTheme.canvas,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddEdit(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text('Add',
              style: GoogleFonts.sofiaSans(
                  fontWeight: FontWeight.w500, fontSize: 16,
                  letterSpacing: -0.32)),
          backgroundColor: AppTheme.ink,
          foregroundColor: AppTheme.canvas,
          elevation: 0,
          extendedPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Row(
        children: [
          // Ink circle logo — Mastercard circle motif
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded,
                color: AppTheme.canvas, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SafeWord',
                  style: GoogleFonts.sofiaSans(
                    color: AppTheme.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  '${_credentials.length} credential${_credentials.length == 1 ? '' : 's'}',
                  style: GoogleFonts.sofiaSans(
                    color: AppTheme.slate,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Circular icon buttons — Mastercard satellite CTA style
          _NavCircleButton(
            icon: Icons.lock_outline_rounded,
            tooltip: 'Lock vault',
            onPressed: _navigateToLock,
          ),
          const SizedBox(width: 4),
          _NavCircleButton(
            icon: Icons.logout_rounded,
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.sofiaSans(color: AppTheme.ink, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search by title or username…',
          hintStyle: GoogleFonts.sofiaSans(color: AppTheme.dust, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.slate, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.slate, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _load();
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide:
                const BorderSide(color: Color(0xFFE2DDD9), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide:
                const BorderSide(color: Color(0xFFE2DDD9), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: AppTheme.ink, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    color: AppTheme.danger, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.sofiaSans(
                    color: AppTheme.danger, fontSize: 14,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 46),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_credentials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFE2DDD9), width: 1.5),
                ),
                child: const Icon(Icons.lock_open_outlined,
                    color: AppTheme.ink, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                _searchCtrl.text.isEmpty
                    ? 'Your vault is empty'
                    : 'No results found',
                style: GoogleFonts.sofiaSans(
                  color: AppTheme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.44,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchCtrl.text.isEmpty
                    ? 'Tap + Add to save your first credential'
                    : 'Try a different search term',
                style: GoogleFonts.sofiaSans(
                    color: AppTheme.slate, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<Credential>>{};
    for (final c in _credentials) {
      final cat = (c.category == null || c.category!.trim().isEmpty)
          ? 'Uncategorized'
          : c.category!.trim();
      grouped.putIfAbsent(cat, () => []).add(c);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Uncategorized') return 1;
        if (b == 'Uncategorized') return -1;
        return a.compareTo(b);
      });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Text(
              'CATEGORIES',
              style: GoogleFonts.sofiaSans(
                color: AppTheme.slate,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.ink,
              backgroundColor: AppTheme.white,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final cat = sortedKeys[index];
                  final creds = grouped[cat]!;
                  return _buildCategoryCard(cat, creds);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, List<Credential> credentials) {
    // Sort credentials by date (latest first)
    final latest = List<Credential>.from(credentials)
      ..sort((a, b) => b.id.compareTo(a.id)); // Using ID for stability if date isn't available
    
    final preview = latest.take(3).toList();

    IconData icon;
    Color iconBg;
    switch (category.toLowerCase()) {
      case 'social':
        icon = Icons.public;
        iconBg = const Color(0xFFE3F2FD);
        break;
      case 'tech':
        icon = Icons.laptop;
        iconBg = const Color(0xFFE8F5E9);
        break;
      case 'shopping':
        icon = Icons.shopping_cart_outlined;
        iconBg = const Color(0xFFFFF3E0);
        break;
      case 'finance':
        icon = Icons.account_balance_outlined;
        iconBg = const Color(0xFFF3E5F5);
        break;
      case 'health':
        icon = Icons.favorite_outline;
        iconBg = const Color(0xFFFFEBEE);
        break;
      case 'travel':
        icon = Icons.airplanemode_active;
        iconBg = const Color(0xFFE0F7FA);
        break;
      case 'entertainment':
        icon = Icons.videogame_asset_outlined;
        iconBg = const Color(0xFFF3E5F5);
        break;
      default:
        icon = Icons.more_horiz;
        iconBg = const Color(0xFFF5F5F5);
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(
            category: category,
            credentials: credentials,
          ),
        )).then((_) => _load());
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2DDD9), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.ink.withOpacity(0.7)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: AppTheme.ink, size: 22),
                      onPressed: () =>
                          _openAddEdit(initialCategory: category),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Add to $category',
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.slate, size: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              category,
              style: GoogleFonts.sofiaSans(
                color: AppTheme.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${credentials.length} credential${credentials.length == 1 ? '' : 's'}',
              style: GoogleFonts.sofiaSans(
                color: AppTheme.slate,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            // Preview of 2-3 items
            ...preview.map((c) => InkWell(
              onTap: () => _openDetail(c),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${c.title}',
                  style: GoogleFonts.sofiaSans(
                    color: AppTheme.slate,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.slate.withOpacity(0.3),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Satellite-style circular nav button — Mastercard design ──────────────────
class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _NavCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2DDD9)),
            color: AppTheme.white,
          ),
          child: Icon(icon, color: AppTheme.slate, size: 18),
        ),
      ),
    );
  }
}
