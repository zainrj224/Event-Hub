import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/widgets/event_card.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _subscription;
  List<Event> _myEvents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribe();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    _subscription = FirebaseFirestore.instance
        .collection('events')
        .where('hostId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              try {
                return EventModel.fromFirestore(doc).toEntity();
              } catch (_) {
                return null;
              }
            }).whereType<Event>().toList())
        .listen(
      (events) {
        events.sort((a, b) => a.date.compareTo(b.date));
        if (mounted) {
          setState(() {
            _myEvents = events;
            _loading = false;
            _error = null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = e.toString();
          });
        }
      },
    );
  }

  List<Event> get _upcoming =>
      _myEvents.where((e) => !e.hasStarted).toList();
  List<Event> get _past =>
      _myEvents.where((e) => e.hasStarted).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        title: const Text('My Events',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.darkText)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.lime,
          labelColor: AppColors.lime,
          unselectedLabelColor: AppColors.darkTextSecondary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.lime, strokeWidth: 2))
          : _error != null
              ? _buildError(_error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _EventsList(
                      events: _upcoming,
                      emptyTitle: 'No upcoming events',
                      emptySubtitle:
                          'Events you create will show up here.',
                      emptyIcon: Icons.event_note_rounded,
                    ),
                    _EventsList(
                      events: _past,
                      emptyTitle: 'No past events',
                      emptySubtitle:
                          'Events you have hosted will appear here once they end.',
                      emptyIcon: Icons.history_rounded,
                    ),
                  ],
                ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Something went wrong',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText)),
            const SizedBox(height: 6),
            Text(msg,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkTextSecondary),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _EventsList extends StatelessWidget {
  final List<Event> events;
  final String emptyTitle, emptySubtitle;
  final IconData emptyIcon;

  const _EventsList({
    required this.events,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon,
                  color: AppColors.lime, size: 36),
            ),
            const SizedBox(height: 16),
            Text(emptyTitle,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText)),
            const SizedBox(height: 6),
            Text(emptySubtitle,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkTextSecondary),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: events.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: EventCard(
          event: events[i],
          onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.eventDetail, arguments: events[i]),
        ),
      ),
    );
  }
}
