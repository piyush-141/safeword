import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/credential.dart';
import '../theme/app_theme.dart';

class CredentialCard extends StatelessWidget {
  final Credential credential;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const CredentialCard({
    super.key,
    required this.credential,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
  });

  IconData _serviceIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('google')) return Icons.g_mobiledata_rounded;
    if (t.contains('github')) return Icons.code_rounded;
    if (t.contains('twitter') || t.contains('x.com')) return Icons.tag_rounded;
    if (t.contains('facebook') || t.contains('fb')) return Icons.facebook_rounded;
    if (t.contains('instagram')) return Icons.photo_camera_rounded;
    if (t.contains('bank') || t.contains('pay')) return Icons.account_balance_rounded;
    if (t.contains('email') || t.contains('mail')) return Icons.mail_rounded;
    if (t.contains('amazon')) return Icons.shopping_bag_rounded;
    if (t.contains('netflix')) return Icons.movie_rounded;
    if (t.contains('spotify')) return Icons.music_note_rounded;
    if (t.contains('apple')) return Icons.apple_rounded;
    return Icons.lock_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(credential.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 26),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: GoogleFonts.sofiaSans(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Delete Credential',
                style: GoogleFonts.sofiaSans(color: AppTheme.ink, fontWeight: FontWeight.w600, fontSize: 20)),
            content: Text(
              'Are you sure you want to delete "${credential.title}"?',
              style: GoogleFonts.sofiaSans(color: AppTheme.slate, fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel',
                    style: GoogleFonts.sofiaSans(color: AppTheme.slate, fontWeight: FontWeight.w500)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                child: Text('Delete',
                    style: GoogleFonts.sofiaSans(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2DDD9)),
            boxShadow: AppTheme.navShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: AppTheme.arcOrange.withOpacity(0.06),
              highlightColor: AppTheme.canvas.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // ── Circular service icon (Mastercard circle motif) ────────
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.canvas,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2DDD9)),
                      ),
                      child: Icon(_serviceIcon(credential.title), color: AppTheme.ink, size: 22),
                    ),
                    const SizedBox(width: 16),
                    // ── Content ───────────────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            credential.title,
                            style: GoogleFonts.sofiaSans(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              letterSpacing: -0.32,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            credential.username ?? 'No username',
                            style: GoogleFonts.sofiaSans(
                              color: AppTheme.slate,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _timeAgo(credential.updatedAt),
                            style: GoogleFonts.sofiaSans(
                              color: AppTheme.dust,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Action row ────────────────────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleAction(
                          icon: Icons.copy_outlined,
                          tooltip: 'Copy password',
                          onTap: onCopy,
                        ),
                        const SizedBox(width: 6),
                        _CircleAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          onTap: onEdit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2DDD9)),
          ),
          child: Icon(icon, color: AppTheme.slate, size: 17),
        ),
      ),
    );
  }
}
