// File: lib/models/video_request_enums.dart
// Purpose: Type-safe enums representing video request statuses and approval statuses.

enum VideoRequestStatus {
  pending,
  assigned,
  inProgress,
  completed,
  cancelled,
  unknown;

  String get dbValue {
    switch (this) {
      case VideoRequestStatus.pending:
        return 'pending';
      case VideoRequestStatus.assigned:
        return 'assigned';
      case VideoRequestStatus.inProgress:
        return 'in_progress';
      case VideoRequestStatus.completed:
        return 'completed';
      case VideoRequestStatus.cancelled:
        return 'cancelled';
      case VideoRequestStatus.unknown:
        return 'unknown';
    }
  }

  static VideoRequestStatus fromDbValue(String? value) {
    if (value == null) return VideoRequestStatus.unknown;
    switch (value.toLowerCase().trim()) {
      case 'pending':
        return VideoRequestStatus.pending;
      case 'assigned':
        return VideoRequestStatus.assigned;
      case 'in_progress':
        return VideoRequestStatus.inProgress;
      case 'completed':
        return VideoRequestStatus.completed;
      case 'cancelled':
        return VideoRequestStatus.cancelled;
      default:
        return VideoRequestStatus.unknown;
    }
  }
}

enum VideoRequestApprovalStatus {
  pending,
  approved,
  rejected,
  unknown;

  String get dbValue {
    switch (this) {
      case VideoRequestApprovalStatus.pending:
        return 'pending';
      case VideoRequestApprovalStatus.approved:
        return 'approved';
      case VideoRequestApprovalStatus.rejected:
        return 'rejected';
      case VideoRequestApprovalStatus.unknown:
        return 'unknown';
    }
  }

  static VideoRequestApprovalStatus fromDbValue(String? value) {
    if (value == null) return VideoRequestApprovalStatus.unknown;
    switch (value.toLowerCase().trim()) {
      case 'pending':
        return VideoRequestApprovalStatus.pending;
      case 'approved':
        return VideoRequestApprovalStatus.approved;
      case 'rejected':
        return VideoRequestApprovalStatus.rejected;
      default:
        return VideoRequestApprovalStatus.unknown;
    }
  }
}
