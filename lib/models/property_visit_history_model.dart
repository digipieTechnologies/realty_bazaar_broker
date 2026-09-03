import 'package:equatable/equatable.dart';

class PropertyVisitHistoryModel extends Equatable {
  static const String tableName = 'property_visit_history';

  final String? id;
  final String? visitId;
  final String action;
  final String? previousStatus;
  final String? newStatus;
  final DateTime? previousVisitDate;
  final DateTime? newVisitDate;
  final String? previousTimeSlot;
  final String? newTimeSlot;
  final String? reason;
  final String? notes;
  final String? changedByUserId;
  final DateTime? createdAt;

  const PropertyVisitHistoryModel({
    this.id,
    this.visitId,
    this.action = 'created',
    this.previousStatus,
    this.newStatus,
    this.previousVisitDate,
    this.newVisitDate,
    this.previousTimeSlot,
    this.newTimeSlot,
    this.reason,
    this.notes,
    this.changedByUserId,
    this.createdAt,
  });

  static PropertyVisitHistoryModel fromJson(dynamic json) {
    if (json is! Map) {
      return PropertyVisitHistoryModel(id: json?.toString());
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString())?.toLocal();
    }

    return PropertyVisitHistoryModel(
      id: json['id']?.toString(),
      visitId: json['visit_id']?.toString(),
      action: json['action']?.toString() ?? 'created',
      previousStatus: json['previous_status']?.toString(),
      newStatus: json['new_status']?.toString(),
      previousVisitDate: parseDate(json['previous_visit_date']),
      newVisitDate: parseDate(json['new_visit_date']),
      previousTimeSlot: json['previous_time_slot']?.toString(),
      newTimeSlot: json['new_time_slot']?.toString(),
      reason: json['reason']?.toString(),
      notes: json['notes']?.toString(),
      changedByUserId: json['changed_by_user_id']?.toString(),
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    if (visitId != null) data['visit_id'] = visitId;
    data['action'] = action;
    if (previousStatus != null) data['previous_status'] = previousStatus;
    if (newStatus != null) data['new_status'] = newStatus;
    if (previousVisitDate != null) {
      data['previous_visit_date'] = previousVisitDate!.toIso8601String().split('T').first;
    }
    if (newVisitDate != null) {
      data['new_visit_date'] = newVisitDate!.toIso8601String().split('T').first;
    }
    if (previousTimeSlot != null) data['previous_time_slot'] = previousTimeSlot;
    if (newTimeSlot != null) data['new_time_slot'] = newTimeSlot;
    if (reason != null) data['reason'] = reason;
    if (notes != null) data['notes'] = notes;
    if (changedByUserId != null) data['changed_by_user_id'] = changedByUserId;
    if (createdAt != null) data['created_at'] = createdAt!.toUtc().toIso8601String();
    return data;
  }

  @override
  List<Object?> get props => [
    id,
    visitId,
    action,
    previousStatus,
    newStatus,
    previousVisitDate,
    newVisitDate,
    previousTimeSlot,
    newTimeSlot,
    reason,
    notes,
    changedByUserId,
    createdAt,
  ];
}
