// File: lib/models/notification_enums.dart
// Purpose: Strictly scoped NotificationType enum (video_request, lead).

enum NotificationType {
  videoRequest('video_request'),
  lead('lead');

  final String dbValue;
  const NotificationType(this.dbValue);

  static NotificationType fromDbValue(String? value) {
    switch (value) {
      case 'video_request':
        return NotificationType.videoRequest;
      case 'lead':
      default:
        return NotificationType.lead;
    }
  }
}
