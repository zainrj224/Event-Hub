import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/cache/cached_firestore.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/events/domain/entities/event_entity.dart';
import '../../../../features/events/data/models/event_model.dart';
import '../../../../features/events/presentation/widgets/event_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCategory = 'All';
  StreamSubscription<List<Event>>? _subscription;
  List<Event> _events = [];
  bool _initialLoading = true;
  String? _error;

  final List<String> _categories = [
    'All',
    'Music',
    'Tech',
    'Sports',
    'Art',
    'Food',
    'Business',
    'Education'
  ];

  @override
  void initState() {
    super.initState();
    _subscribe('All');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe(String category) {
    _subscription?.cancel();

    CachedFirestore.instance.fetchEvents(
      category: category,
      onCached: (cached) {
        if (!mounted) return;
        if (cached != null && cached.isNotEmpty) {
          final events = cached
              .map((m) {
                try {
                  return EventModel.fromMap(m).toEntity();
                } catch (_) {
                  return null;
                }
              })
              .whereType<Event>()
              .toList();
          if (mounted)
            setState(() {
              _events = events;
              _initialLoading = false;
            });
        }
      },
      onFresh: (fresh) {
        if (!mounted) return;
        final events = fresh
            .map((m) {
              try {
                return EventModel.fromMap(m).toEntity();
              } catch (_) {
                return null;
              }
            })
            .whereType<Event>()
            .toList();
        if (mounted)
          setState(() {
            _events = events;
            _initialLoading = false;
            _error = null;
          });
      },
      onError: (e) {
        if (!mounted) return;
        if (_events.isEmpty) {
          setState(() {
            _initialLoading = false;
            _error = e.toString();
          });
        }
      },
    );

    Query<Map<String, dynamic>> query;
    if (category == 'All') {
      query = FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(50);
    } else {
      query = FirebaseFirestore.instance
          .collection('events')
          .where('category', isEqualTo: category)
          .limit(50);
    }

    _subscription = query.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) {
            try {
              return EventModel.fromFirestore(doc).toEntity();
            } catch (_) {
              return null;
            }
          })
          .whereType<Event>()
          .toList();
      if (category != 'All')
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).listen(
      (events) {
        if (mounted)
          setState(() {
            _events = events;
            _initialLoading = false;
            _error = null;
          });
        CacheService.instance
            .setEvents(category, events.map((e) => _eventToMap(e)).toList());
      },
      onError: (e) {
        if (mounted && _events.isEmpty) {
          setState(() {
            _initialLoading = false;
            _error = e.toString();
          });
        }
      },
    );
  }

  Map<String, dynamic> _eventToMap(Event e) => {
        'id': e.id,
        'title': e.title,
        'description': e.description,
        'date': e.date.toIso8601String(),
        'time': e.time,
        'location': e.location,
        'category': e.category,
        'image': e.image,
        'hostId': e.hostId,
        'hostName': e.hostName,
        'hostAvatar': e.hostAvatar,
        'interested': e.interested,
        'isOnline': e.isOnline,
        'isPublic': e.isPublic,
        'tags': e.tags,
        'createdAt': e.createdAt.toIso8601String(),
      };

  void _onCategoryTap(String cat) {
    if (cat == _selectedCategory) return;
    setState(() => _selectedCategory = cat);
    _subscribe(cat);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    _UserAvatar(user: user),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Event Hub',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.darkTextSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category chips ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => _onCategoryTap(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.lime : AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Events ──────────────────────────────────────────────────
            if (_initialLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.lime,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Something went wrong',
                  subtitle: _error!,
                ),
              )
            else if (_events.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'No events yet',
                  subtitle: _selectedCategory == 'All'
                      ? 'Be the first to create one!'
                      : 'No $_selectedCategory events found.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EventCard(
                        event: _events[index],
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.eventDetail,
                          arguments: _events[index],
                        ),
                      ),
                    ),
                    childCount: _events.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final User? user;
  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.darkSurface,
        backgroundImage:
            user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        child: user?.photoURL == null
            ? Text(
                (user?.displayName?.isNotEmpty == true
                        ? user!.displayName![0]
                        : user?.email?[0] ?? 'U')
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              )
            : null,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: AppColors.darkTextSecondary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              )),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkTextSecondary,
              ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
