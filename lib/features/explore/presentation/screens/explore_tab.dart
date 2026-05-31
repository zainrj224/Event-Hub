import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../features/events/data/models/event_model.dart';
import '../../../../features/events/domain/entities/event_entity.dart';
import '../../../../features/events/presentation/widgets/event_card.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Event>> _searchStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .orderBy('title')
        .snapshots()
        .map((snap) {
      final events = snap.docs
          .map((doc) => EventModel.fromFirestore(doc).toEntity())
          .toList();
      if (_query.isEmpty) return events;
      final q = _query.toLowerCase();
      return events
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find events that match your vibe',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                      color: AppColors.darkText, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search events, places, categories…',
                    hintStyle: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.darkTextSecondary, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.darkTextSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.lime, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Results ───────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Event>>(
                stream: _searchStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.lime, strokeWidth: 2),
                    );
                  }
                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.search_off_rounded,
                                size: 30,
                                color: AppColors.darkTextSecondary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _query.isEmpty
                                ? 'No events found'
                                : 'No results for "$_query"',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 16),
                    itemBuilder: (_, i) => EventCard(
                      event: events[i],
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.eventDetail,
                        arguments: events[i],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
