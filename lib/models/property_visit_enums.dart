// File: lib/models/property_visit_enums.dart
// Purpose: Type-safe, reusable enums for site visit hourly time slots and lifecycle statuses.

/// Standard hourly visit time slots from 09:00 AM to 10:00 PM.
enum VisitTimeSlot {
  slot09To10('09:00 AM – 10:00 AM', 9, 10),
  slot10To11('10:00 AM – 11:00 AM', 10, 11),
  slot11To12('11:00 AM – 12:00 PM', 11, 12),
  slot12To01('12:00 PM – 01:00 PM', 12, 13),
  slot01To02('01:00 PM – 02:00 PM', 13, 14),
  slot02To03('02:00 PM – 03:00 PM', 14, 15),
  slot03To04('03:00 PM – 04:00 PM', 15, 16),
  slot04To05('04:00 PM – 05:00 PM', 16, 17),
  slot05To06('05:00 PM – 06:00 PM', 17, 18),
  slot06To07('06:00 PM – 07:00 PM', 18, 19),
  slot07To08('07:00 PM – 08:00 PM', 19, 20),
  slot08To09('08:00 PM – 09:00 PM', 20, 21),
  slot09To10Pm('09:00 PM – 10:00 PM', 21, 22);

  final String label;
  final int startHour;
  final int endHour;

  const VisitTimeSlot(this.label, this.startHour, this.endHour);

  /// All formatted label strings (e.g. `'09:00 AM – 10:00 AM'`)
  static List<String> get labels => values.map((e) => e.label).toList();

  /// Safely resolves a VisitTimeSlot from a string, tolerating en-dashes (`–`),
  /// hyphens (`-`), casing, and extra whitespace.
  static VisitTimeSlot? fromLabel(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final normalized = _normalize(text);
    for (final slot in values) {
      if (_normalize(slot.label) == normalized) {
        return slot;
      }
    }
    return null;
  }

  /// Checks whether a given string corresponds to a recognized hourly slot.
  static bool isValidSlot(String? text) => fromLabel(text) != null;

  static String _normalize(String input) {
    return input
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }
}

/// Lifecycle status for site visits in the CRM.
enum PropertyVisitStatus {
  pending('pending', 'status_pending'),
  confirmed('confirmed', 'status_confirmed'),
  rescheduled('rescheduled', 'status_rescheduled'),
  completed('completed', 'status_completed'),
  cancelled('cancelled', 'status_cancelled'),
  noShow('no_show', 'status_no_show'),
  unknown('unknown', 'status_unknown');

  final String dbValue;
  final String labelKey;

  const PropertyVisitStatus(this.dbValue, this.labelKey);

  static PropertyVisitStatus fromDbValue(String? value) {
    if (value == null) return PropertyVisitStatus.unknown;
    final clean = value.toLowerCase().trim();
    for (final s in values) {
      if (s.dbValue == clean) return s;
    }
    return PropertyVisitStatus.unknown;
  }
}
