import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/routes/app_routes.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _eventsCreated = 0;
  int _eventsSaved = 0;
  StreamSubscription? _eventsSub;
  StreamSubscription? _savedSub;
  String? _cachedDisplayName;
  String? _cachedPhotoURL;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _loadStats();
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _savedSub?.cancel();
    super.dispose();
  }

  void _loadCachedProfile() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final cached = CacheService.instance.getProfile(userId);
    if (cached != null && mounted) {
      setState(() {
        _cachedDisplayName = cached['displayName'] as String?;
        _cachedPhotoURL = cached['photoURL'] as String?;
      });
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      CacheService.instance.setProfile(userId, {
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'uid': userId,
      });
    }
  }

  void _loadStats() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _eventsSub = FirebaseFirestore.instance
        .collection('events')
        .where('hostId', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _eventsCreated = snap.docs.length);
    });

    _savedSub = FirebaseFirestore.instance
        .collection('savedEvents')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _eventsSaved = snap.docs.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = _cachedDisplayName ?? user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'U');
    final photoURL = _cachedPhotoURL ?? user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;

    final creationTime = user?.metadata.creationTime;
    final memberSince = creationTime != null
        ? '${_monthName(creationTime.month)} ${creationTime.year}'
        : 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              const Text('Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 24),

              // ── Profile card ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.darkBackground,
                      backgroundImage:
                          hasPhoto ? NetworkImage(photoURL) : null,
                      onBackgroundImageError:
                          hasPhoto ? (_, __) {} : null,
                      child: !hasPhoto
                          ? Text(initial,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText,
                              ))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText,
                              )),
                          const SizedBox(height: 2),
                          Text(email,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.darkTextSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.calendar_month_outlined,
                                size: 12, color: AppColors.lime),
                            const SizedBox(width: 4),
                            Text('Since $memberSince',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.lime,
                                )),
                          ]),
                        ]),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Stats ─────────────────────────────────────────────────
              Row(children: [
                Expanded(
                    child: _StatCard(
                  value: _eventsCreated.toString(),
                  label: 'Created',
                  icon: Icons.event_note_outlined,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                  value: _eventsSaved.toString(),
                  label: 'Saved',
                  icon: Icons.bookmark_outline_rounded,
                  accent: true,
                )),
              ]),

              const SizedBox(height: 28),

              const Text('Account',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextSecondary,
                    letterSpacing: 0.06,
                  )),
              const SizedBox(height: 8),

              _ProfileTile(
                icon: Icons.event_note_rounded,
                label: 'My Events',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.myEvents),
              ),
              _ProfileTile(
                icon: Icons.bookmark_outline_rounded,
                label: 'Saved Events',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.savedEvents),
              ),
              _ProfileTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.settings),
              ),

              const SizedBox(height: 20),

              // ── Sign out ──────────────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool accent;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.lime.withValues(alpha: 0.1)
            : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent
                ? AppColors.lime.withValues(alpha: 0.15)
                : AppColors.darkBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18,
              color:
                  accent ? AppColors.lime : AppColors.darkText),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                  height: 1)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary)),
        ]),
      ]),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.darkText, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.darkTextSecondary, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
