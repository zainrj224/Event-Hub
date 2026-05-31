import 'package:equatable/equatable.dart';

/// Domain entity for Event
class Event extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String image;
  final String location;
  final DateTime date;
  final String time;
  final bool isOnline;
  final int interested;
  final bool isPublic;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.image,
    required this.location,
    required this.date,
    required this.time,
    this.isOnline = false,
    this.interested = 0,
    this.isPublic = true,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? image,
    String? location,
    DateTime? date,
    String? time,
    bool? isOnline,
    int? interested,
    bool? isPublic,
    String? hostId,
    String? hostName,
    String? hostAvatar,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      isOnline: isOnline ?? this.isOnline,
      interested: interested ?? this.interested,
      isPublic: isPublic ?? this.isPublic,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDate =>
      '${date.day}/${date.month}/${date.year}';

  bool get hasStarted {
    final now = DateTime.now();
    return date.isBefore(now) || date.isAtSameMomentAs(now);
  }

  bool get isHappeningSoon {
    final now = DateTime.now();
    final difference = date.difference(now);
    return difference.inHours <= 24 && difference.inHours >= 0;
  }

  @override
  List<Object?> get props => [
        id, title, description, category, image, location,
        date, time, isOnline, interested, isPublic,
        hostId, hostName, hostAvatar, tags, createdAt, updatedAt,
      ];
}
