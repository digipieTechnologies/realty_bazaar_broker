import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'property_model.dart';
import 'property_visit_history_model.dart';

class PropertyVisitModel extends Equatable {
  static const String tableName = 'property_visits';

  final String? id;
  final BrokerModel? brokerId;
  final PropertyModel? propertyId;
  final String clientName;
  final String clientPhone;
  final String phoneCountryCode;
  final String phoneCountryIso;
  final DateTime? visitDate;
  final String timeSlot;
  final String status;
  final String? notes;
  final int rescheduleCount;
  final String? rescheduleReason;
  final String? cancelledReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PropertyVisitHistoryModel> history;

  const PropertyVisitModel({
    this.id,
    this.brokerId,
    this.propertyId,
    this.clientName = '',
    this.clientPhone = '',
    this.phoneCountryCode = '91',
    this.phoneCountryIso = 'IN',
    this.visitDate,
    this.timeSlot = '',
    this.status = 'pending',
    this.notes,
    this.rescheduleCount = 0,
    this.rescheduleReason,
    this.cancelledReason,
    this.createdAt,
    this.updatedAt,
    this.history = const [],
  });

  // Backward compatibility & convenience getters
  String get contactNumber {
    final code = phoneCountryCode.isNotEmpty ? phoneCountryCode : '91';
    return '+$code $clientPhone';
  }

  String get whatsappNumber => clientPhone;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isRescheduled => status.toLowerCase() == 'rescheduled';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isNoShow => status.toLowerCase() == 'no_show';

  PropertyModel? get property => propertyId;
  BrokerModel? get broker => brokerId;

  String buildWhatsappUrl() {
    final cleanPhone = (phoneCountryCode.isNotEmpty ? phoneCountryCode : '91') +
        clientPhone.replaceAll(RegExp(r'\D'), '');
    final propName = property?.propertyTitle ?? '';
    final address = property?.address?.fullAddress ?? '';

    final StringBuffer msgBuffer = StringBuffer();
    msgBuffer.writeln('Hello ${clientName.isNotEmpty ? clientName : 'there'},');
    
    if (isPending) {
      msgBuffer.writeln('We have received your site visit request!');
    } else if (isConfirmed) {
      msgBuffer.writeln('Your site visit has been confirmed!');
    } else if (isRescheduled) {
      msgBuffer.writeln('Your site visit has been rescheduled.');
    } else {
      msgBuffer.writeln('Regarding your site visit request:');
    }

    if (visitDate != null) {
      final dateStr = '${visitDate!.day.toString().padLeft(2, '0')}/${visitDate!.month.toString().padLeft(2, '0')}/${visitDate!.year}';
      msgBuffer.writeln('\n📅 Date: $dateStr');
    }
    if (timeSlot.isNotEmpty) {
      msgBuffer.writeln('⏰ Time Slot: $timeSlot');
    }

    if (propName.isNotEmpty) {
      msgBuffer.writeln('📌 Property: $propName');
      if (address.isNotEmpty) {
        msgBuffer.writeln('📍 Location: $address');
      }
    }

    msgBuffer.writeln('\nPlease let us know if you need any directions or have questions.');
    final encoded = Uri.encodeComponent(msgBuffer.toString());
    return 'https://wa.me/$cleanPhone?text=$encoded';
  }

  static PropertyVisitModel fromJson(dynamic json) {
    if (json is! Map) {
      return PropertyVisitModel(id: json?.toString());
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString())?.toLocal();
    }

    BrokerModel? parsedBroker;
    if (json['broker'] != null) {
      parsedBroker = BrokerModel.fromJson(json['broker']);
    } else if (json['brokers'] != null) {
      parsedBroker = BrokerModel.fromJson(json['brokers']);
    } else if (json['broker_id'] is Map) {
      parsedBroker = BrokerModel.fromJson(json['broker_id']);
    }

    PropertyModel? parsedProperty;
    if (json['property'] != null) {
      parsedProperty = PropertyModel.fromJson(json['property']);
    } else if (json['properties'] != null) {
      parsedProperty = PropertyModel.fromJson(json['properties']);
    } else if (json['property_id'] is Map) {
      parsedProperty = PropertyModel.fromJson(json['property_id']);
    }

    List<PropertyVisitHistoryModel> parsedHistory = [];
    if (json['history'] is List) {
      parsedHistory = (json['history'] as List)
          .map((h) => PropertyVisitHistoryModel.fromJson(h))
          .toList();
    }

    return PropertyVisitModel(
      id: json['id']?.toString(),
      brokerId: parsedBroker,
      propertyId: parsedProperty,
      clientName: json['client_name']?.toString() ?? '',
      clientPhone: json['client_phone']?.toString() ?? '',
      phoneCountryCode: json['phone_country_code']?.toString() ?? '91',
      phoneCountryIso: json['phone_country_iso']?.toString() ?? 'IN',
      visitDate: parseDate(json['visit_date']),
      timeSlot: json['time_slot']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      rescheduleCount: int.tryParse(json['reschedule_count']?.toString() ?? '0') ?? 0,
      rescheduleReason: json['reschedule_reason']?.toString(),
      cancelledReason: json['cancelled_reason']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      history: parsedHistory,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    if (brokerId?.id != null) data['broker_id'] = brokerId!.id;
    if (propertyId?.id != null) data['property_id'] = propertyId!.id;
    data['client_name'] = clientName;
    data['client_phone'] = clientPhone;
    data['phone_country_code'] = phoneCountryCode;
    data['phone_country_iso'] = phoneCountryIso;
    if (visitDate != null) {
      data['visit_date'] = visitDate!.toIso8601String().split('T').first;
    }
    data['time_slot'] = timeSlot;
    data['status'] = status;
    data['notes'] = notes;
    data['reschedule_count'] = rescheduleCount;
    data['reschedule_reason'] = rescheduleReason;
    data['cancelled_reason'] = cancelledReason;
    if (createdAt != null) data['created_at'] = createdAt!.toUtc().toIso8601String();
    if (updatedAt != null) data['updated_at'] = updatedAt!.toUtc().toIso8601String();
    return data;
  }

  PropertyVisitModel copyWith({
    String? id,
    BrokerModel? brokerId,
    PropertyModel? propertyId,
    String? clientName,
    String? clientPhone,
    String? phoneCountryCode,
    String? phoneCountryIso,
    DateTime? visitDate,
    String? timeSlot,
    String? status,
    String? notes,
    int? rescheduleCount,
    String? rescheduleReason,
    String? cancelledReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PropertyVisitHistoryModel>? history,
  }) {
    return PropertyVisitModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      propertyId: propertyId ?? this.propertyId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneCountryIso: phoneCountryIso ?? this.phoneCountryIso,
      visitDate: visitDate ?? this.visitDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
    id,
    brokerId,
    propertyId,
    clientName,
    clientPhone,
    phoneCountryCode,
    phoneCountryIso,
    visitDate,
    timeSlot,
    status,
    notes,
    rescheduleCount,
    rescheduleReason,
    cancelledReason,
    createdAt,
    updatedAt,
    history,
  ];
}
