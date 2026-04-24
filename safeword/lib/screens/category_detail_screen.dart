import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/credential.dart';
import '../theme/app_theme.dart';
import '../widgets/credential_card.dart';
import 'add_edit_credential_screen.dart';
import 'credential_detail_screen.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import '../config.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;
  final List<Credential> credentials;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.credentials,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late List<Credential> _credentials;

  @override
  void initState() {
    super.initState();
    _credentials = List.from(widget.credentials);
  }

  Future<void> _load() async {
    try {
      final creds = await ApiService.getCredentials();
      if (mounted) {
        setState(() {
          _credentials = creds.where((c) {
            final cat = (c.category == null || c.category!.trim().isEmpty)
                ? 'Uncategorized'
                : c.category!.trim();
            return cat == widget.category;
          }).toList();
        });
      }
    } catch (_) {}
  }

  void _openDetail(Credential credential) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => CredentialDetailScreen(credential: credential),
        ))
        .then((_) => _load());
  }

  void _openEdit(Credential credential) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => AddEditCredentialScreen(credential: credential),
        ))
        .then((_) => _load());
  }

  void _openAdd() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) =>
              AddEditCredentialScreen(initialCategory: widget.category),
        ))
        .then((_) => _load());
  }

  Future<void> _delete(Credential cred) async {
    try {
      await ApiService.deleteCredential(cred.id);
      if (mounted) {
        setState(() => _credentials.removeWhere((c) => c.id == cred.id));
      }
    } catch (_) {}
  }

  Future<void> _copyPassword(Credential cred) async {
    final pwd = cred.decryptedPassword ?? '';
    await Clipboard.setData(ClipboardData(text: pwd));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: GoogleFonts.sofiaSans(
            color: AppTheme.ink,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.ink),
            onPressed: _openAdd,
            tooltip: 'Add to ${widget.category}',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _credentials.isEmpty
          ? Center(
              child: Text(
                'No credentials in this category',
                style: GoogleFonts.sofiaSans(color: AppTheme.slate),
              ),
            )
          : ListView.builder(
              itemCount: _credentials.length,
              padding: const EdgeInsets.only(bottom: 100),
              itemBuilder: (context, index) {
                final cred = _credentials[index];
                return CredentialCard(
                  credential: cred,
                  onTap: () => _openDetail(cred),
                  onEdit: () => _openEdit(cred),
                  onDelete: () => _delete(cred),
                  onCopy: () => _copyPassword(cred),
                );
              },
            ),
    );
  }
}
