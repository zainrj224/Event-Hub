import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() =>
      _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _likeLoading = true;
  late int _likeCount;

  // Host avatar loaded from Firestore (base64 or URL)
  String? _hostAvatarResolved;

  Event get event => widget.event;
  bool get _isExpired => event.date.isBefore(DateTime.now());
  bool get _shouldAutoDelete =>
      _isExpired &&
      DateTime.now().difference(event.date).inHours >= 24;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.event.interested;
    _checkUserInterest();
    _checkSaved();
    _loadHostAvatar();
    if (_shouldAutoDelete) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _autoDelete());
    }
  }

  // ── Load host avatar from Firestore users collection ──────────
  Future<void> _loadHostAvatar() async {
    if (event.hostId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(event.hostId)
          .get();
      final base64Photo =
          doc.data()?['photoBase64'] as String?;
      if (base64Photo != null &&
          base64Photo.isNotEmpty &&
          mounted) {
        setState(() => _hostAvatarResolved = base64Photo);
        return;
      }
      // Fallback to photoURL stored on the user doc
      final photoUrl =
          doc.data()?['photoURL'] as String?;
      if (photoUrl != null &&
          photoUrl.isNotEmpty &&
          photoUrl != 'profile_photo_in_firestore' &&
          mounted) {
        setState(() => _hostAvatarResolved = photoUrl);
      }
    } catch (_) {}
  }

  Future<void> _autoDelete() async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .delete();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'This event was automatically removed after 24 hours.'),
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _checkUserInterest() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _likeLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('interested')
          .doc('${event.id}_$userId')
          .get();
      if (mounted) {
        setState(() {
          _isLiked = doc.exists;
          _likeLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _likeLoading = false);
    }
  }

  Future<void> _checkSaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('savedEvents')
          .doc('${userId}_${event.id}')
          .get();
      if (mounted) setState(() => _isSaved = doc.exists);
    } catch (_) {}
  }

  Future<void> _toggleInterested() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sign in to mark interest'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final newLiked = !_isLiked;
    setState(() {
      _isLiked = newLiked;
      _likeCount += newLiked ? 1 : -1;
    });
    try {
      final docRef = FirebaseFirestore.instance
          .collection('interested')
          .doc('${event.id}_$userId');
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event.id);
      if (newLiked) {
        await docRef.set({
          'eventId': event.id,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await eventRef
            .update({'interested': FieldValue.increment(1)});
      } else {
        await docRef.delete();
        await eventRef
            .update({'interested': FieldValue.increment(-1)});
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = !newLiked;
          _likeCount += newLiked ? -1 : 1;
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final newSaved = !_isSaved;
    setState(() => _isSaved = newSaved);
    final ref = FirebaseFirestore.instance
        .collection('savedEvents')
        .doc('${userId}_${event.id}');
    try {
      if (newSaved) {
        await ref.set({
          'userId': userId,
          'eventId': event.id,
          'savedAt': FieldValue.serverTimestamp(),
          'eventTitle': event.title,
          'eventDate': event.date.toIso8601String(),
          'eventImage': event.image,
          'eventLocation': event.location,
          'eventCategory': event.category,
          'hostName': event.hostName,
          'hostAvatar': event.hostAvatar,
          'hostId': event.hostId,
        });
      } else {
        await ref.delete();
      }
    } catch (_) {
      if (mounted) setState(() => _isSaved = !newSaved);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.darkText)),
        content: const Text(
            'Are you sure you want to permanently delete this event?',
            style: TextStyle(
                color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.darkTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Event deleted'),
                behavior: SnackBarBehavior.floating));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete: $e'),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid;
    final isCreator =
        currentUserId != null && currentUserId == event.hostId;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero image app bar ───────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.darkBackground,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor:
                        Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18),
                      onPressed: () =>
                          Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  _appBarBtn(
                    icon: _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _isSaved
                        ? const Color(0xFFFBBF24)
                        : Colors.white,
                    onTap: _toggleSave,
                  ),
                  _appBarBtn(
                    icon: Icons.share_rounded,
                    color: Colors.white,
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content:
                                    Text('Share coming soon!'),
                                behavior:
                                    SnackBarBehavior.floating)),
                  ),
                  if (isCreator)
                    _appBarBtn(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.white,
                      bg: Colors.red.withValues(alpha: 0.75),
                      onTap: _confirmDelete,
                    ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeroImage()),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildBadgesRow(),
                    _buildTitle(),
                    if (_isExpired) _buildExpiredBanner(),
                    _buildDivider(),
                    _buildDateTimeSection(),
                    _buildDivider(),
                    _buildLocationSection(),
                    _buildDivider(),
                    _buildDescriptionSection(),
                    if (event.tags.isNotEmpty) ...[
                      _buildDivider(),
                      _buildTagsSection(),
                    ],
                    _buildDivider(),
                    _buildHostSection(),
                    _buildDivider(),
                    _buildStatsSection(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),

          // ── Bottom bar ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(isCreator),
          ),
        ],
      ),
    );
  }

  Widget _appBarBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color? bg,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8, bottom: 8, left: 4),
      child: CircleAvatar(
        backgroundColor:
            bg ?? Colors.black.withValues(alpha: 0.45),
        child: IconButton(
          icon: Icon(icon, color: color, size: 18),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: event.image,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(color: AppColors.darkSurfaceLow),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.darkSurfaceLow,
            child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.darkTextSecondary,
                size: 56),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.darkBackground
                      .withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _badge(event.category,
              AppColors.lime.withValues(alpha: 0.15),
              AppColors.lime),
          if (event.isOnline)
            _badge(
                '🌐 Online',
                const Color(0xFF1D4ED8)
                    .withValues(alpha: 0.15),
                const Color(0xFF60A5FA)),
          if (event.isHappeningSoon && !_isExpired)
            _badge(
                '⚡ Soon',
                const Color(0xFFB45309)
                    .withValues(alpha: 0.15),
                const Color(0xFFFBBF24)),
          if (_isExpired)
            _badge(
                '⏰ Ended',
                AppColors.error.withValues(alpha: 0.15),
                AppColors.error),
          if (!event.isPublic)
            _badge('🔒 Private', AppColors.darkSurface,
                AppColors.darkTextSecondary),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg)),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Text(event.title,
          style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
              height: 1.25)),
    );
  }

  Widget _buildExpiredBanner() {
    final hoursAgo =
        DateTime.now().difference(event.date).inHours;
    final hoursLeft = (24 - hoursAgo).clamp(0, 24);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFB45309)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFB45309)
                  .withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.access_time_rounded,
              size: 18, color: Color(0xFFFBBF24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text('This event has ended',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFBBF24))),
                  const SizedBox(height: 2),
                  Text(
                    hoursLeft > 0
                        ? 'Auto-deleted in ${hoursLeft}h'
                        : 'Will be deleted very soon',
                    style: const TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.darkTextSecondary),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return _section(
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconCircle(Icons.calendar_today_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Date & Time'),
                    const SizedBox(height: 4),
                    Text(
                        DateFormatter.formatDateLong(
                            event.date),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText)),
                    const SizedBox(height: 2),
                    Text(
                        '${DateFormatter.formatTime(event.time)}  ·  ${DateFormatter.getRelativeDate(event.date)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color:
                                AppColors.darkTextSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isExpired
                            ? AppColors.error
                                .withValues(alpha: 0.1)
                            : AppColors.lime
                                .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                          DateFormatter.getTimeUntilEvent(
                              event.date, event.time),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _isExpired
                                  ? AppColors.error
                                  : AppColors.lime)),
                    ),
                  ]),
            ),
          ]),
    );
  }

  Widget _buildLocationSection() {
    return _section(
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconCircle(event.isOnline
                ? Icons.video_call_rounded
                : Icons.location_on_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(event.isOnline
                        ? 'Online Event'
                        : 'Location'),
                    const SizedBox(height: 4),
                    Text(event.location,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText)),
                  ]),
            ),
          ]),
    );
  }

  Widget _buildDescriptionSection() {
    return _section(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('About this event'),
            const SizedBox(height: 8),
            Text(
              event.description.isNotEmpty
                  ? event.description
                  : 'No description provided.',
              style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.darkTextSecondary),
            ),
          ]),
    );
  }

  Widget _buildTagsSection() {
    return _section(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Tags'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: event.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors
                                    .darkTextSecondary)),
                      ))
                  .toList(),
            ),
          ]),
    );
  }

  // ── Host section: loads avatar from Firestore ──────────────────
  Widget _buildHostSection() {
    final hostInitial = event.hostName.isNotEmpty
        ? event.hostName[0].toUpperCase()
        : '?';

    Widget avatar = CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.darkSurface,
      child: Text(hostInitial,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.lime)),
    );

    final resolved = _hostAvatarResolved;
    if (resolved != null && resolved.isNotEmpty) {
      if (resolved.startsWith('data:')) {
        try {
          final bytes =
              base64Decode(resolved.split(',').last);
          avatar = CircleAvatar(
            radius: 24,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      } else if (resolved.startsWith('http')) {
        avatar = CachedNetworkImage(
          imageUrl: resolved,
          imageBuilder: (_, p) =>
              CircleAvatar(radius: 24, backgroundImage: p),
          placeholder: (_, __) => avatar,
          errorWidget: (_, __, ___) => avatar,
        );
      }
    }

    return _section(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Hosted by'),
            const SizedBox(height: 12),
            Row(children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(event.hostName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText)),
                      const SizedBox(height: 2),
                      const Text('Event Organizer',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.darkTextSecondary)),
                    ]),
              ),
            ]),
          ]),
    );
  }

  // ── Stats: only Interested count (attendees removed) ──────────
  Widget _buildStatsSection() {
    return _section(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Event Stats'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _statCard(
                      icon: Icons.favorite_rounded,
                      label: 'Interested',
                      value: _likeCount.toString())),
            ]),
          ]),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Icon(icon, size: 20, color: AppColors.lime),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.darkTextSecondary)),
      ]),
    );
  }

  Widget _buildBottomBar(bool isCreator) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
            top: BorderSide(
                color: AppColors.darkOutline, width: 0.5)),
      ),
      child: Row(children: [
        // Interested toggle button
        Expanded(
          child: GestureDetector(
            onTap: _likeLoading ? null : _toggleInterested,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isLiked
                    ? AppColors.lime.withValues(alpha: 0.15)
                    : AppColors.darkBackground,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: _isLiked
                        ? AppColors.lime
                        : AppColors.darkOutline),
              ),
              child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    if (_likeLoading)
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  AppColors.darkTextSecondary))
                    else
                      AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(
                                scale: anim, child: child),
                        child: Icon(
                          _isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(_isLiked),
                          color: _isLiked
                              ? AppColors.lime
                              : AppColors.darkTextSecondary,
                          size: 22,
                        ),
                      ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration:
                          const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(
                              scale: anim, child: child),
                      child: Text(
                        _likeCount.toString(),
                        key: ValueKey(_likeCount),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _isLiked
                                ? AppColors.lime
                                : AppColors.darkTextSecondary),
                      ),
                    ),
                  ]),
            ),
          ),
        ),

        if (isCreator) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _confirmDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color:
                    AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: AppColors.error
                        .withValues(alpha: 0.4)),
              ),
              child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.error),
                    SizedBox(width: 6),
                    Text('Delete',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error)),
                  ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _section({required Widget child}) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: child);

  Widget _buildDivider() => const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.darkOutline,
      indent: 20,
      endIndent: 20);

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.darkTextSecondary));

  Widget _iconCircle(IconData icon) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: AppColors.lime.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: AppColors.lime, size: 20));
}
