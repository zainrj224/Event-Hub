import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final placeholder = Container(
      color: AppColors.darkSurfaceLow,
      child: const Center(
        child: Icon(Icons.image_outlined,
            color: AppColors.darkTextSecondary, size: 32),
      ),
    );

    Widget imageWidget;
    if (event.image.startsWith('data:')) {
      try {
        final bytes = base64Decode(event.image.split(',').last);
        imageWidget = Image.memory(bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
            errorBuilder: (_, __, ___) => placeholder);
      } catch (_) {
        imageWidget = placeholder;
      }
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: event.image,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.darkSurfaceLow),
        errorWidget: (_, __, ___) => placeholder,
      );
    }

    return Stack(
      children: [
        SizedBox(height: 180, width: double.infinity, child: imageWidget),
        // Dark gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),
        // Category badge
        Positioned(
          top: 12,
          left: 12,
          child: Row(
            children: [
              _Badge(label: event.category),
              if (event.isOnline) ...[
                const SizedBox(width: 6),
                _Badge(label: '🌐 Online', isOnline: true),
              ],
            ],
          ),
        ),
        // Bookmark icon
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + time
          _InfoRow(
            icon: Icons.access_time_rounded,
            text: DateFormatter.formatDateTime(event.date, event.time),
          ),
          const SizedBox(height: 4),
          // Location
          _InfoRow(
            icon: Icons.location_on_outlined,
            text: event.location,
            expandable: true,
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
              height: 1.3,
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Interested count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.lime.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  size: 13, color: AppColors.lime),
              const SizedBox(width: 5),
              Text(
                '${event.interested} interested',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lime,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // View button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.lime,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'View Event',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool isOnline;
  const _Badge({required this.label, this.isOnline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.lime.withValues(alpha: 0.9)
            : AppColors.darkBackground.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOnline ? AppColors.primary : AppColors.darkText,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool expandable;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.expandable = false,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.darkTextSecondary),
        const SizedBox(width: 5),
        expandable ? Expanded(child: textWidget) : Flexible(child: textWidget),
      ],
    );
  }
}
