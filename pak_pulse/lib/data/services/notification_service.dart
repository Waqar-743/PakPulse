import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/crisis.dart';
import '../models/user_location.dart';

/// A single notification surfaced to the user — typically a verified crisis
/// near their stored location.
class CrisisNotification {
  final String id;
  final Crisis crisis;
  final DateTime createdAt;
  final double distanceKm;
  bool isRead;

  CrisisNotification({
    required this.id,
    required this.crisis,
    required this.createdAt,
    required this.distanceKm,
    this.isRead = false,
  });
}

/// In-app notification store. Deliberately stays on-device — no Firebase,
/// no SMTP, no card. Mobile push / email can be layered on later by adding
/// a listener that forwards entries to flutter_local_notifications or mailto.
class NotificationStore extends StateNotifier<List<CrisisNotification>> {
  NotificationStore() : super(const []);

  void push(CrisisNotification n) {
    state = [n, ...state];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) (n..isRead = true) else n,
    ];
  }

  void clear() => state = const [];

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationStoreProvider =
    StateNotifierProvider<NotificationStore, List<CrisisNotification>>(
        (_) => NotificationStore());

/// Haversine distance in kilometres between two lat/lng points.
double distanceKm({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const earthRadiusKm = 6371.0;
  double toRad(double deg) => deg * math.pi / 180.0;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final sinDLat = math.sin(dLat / 2);
  final sinDLng = math.sin(dLng / 2);
  final h = sinDLat * sinDLat +
      math.cos(toRad(lat1)) * math.cos(toRad(lat2)) * sinDLng * sinDLng;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusKm * c;
}

bool isNearUser({
  required Crisis crisis,
  required UserLocation? user,
  double radiusKm = 5.0,
}) {
  if (user == null) return false;
  final d = distanceKm(
    lat1: user.lat,
    lng1: user.lng,
    lat2: crisis.lat,
    lng2: crisis.lng,
  );
  return d <= radiusKm;
}
