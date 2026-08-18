// File: lib/core/utils/common_ext.dart
// Purpose: Centralized string and file extension helpers for file name extraction, type checking, labels, and formatting across The Realty Bazaar.

import 'package:intl/intl.dart';

extension FileStringExtension on String {
  /// Extracts file extension from URL or file path (e.g., 'social_leads.csv' -> 'csv', 'file.sql?v=1' -> 'sql')
  String get fileExtension {
    if (trim().isEmpty) return '';
    try {
      final uri = Uri.parse(trim());
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1).toLowerCase();
      }
    } catch (_) {}
    final lastDot = lastIndexOf('.');
    if (lastDot != -1 && lastDot < length - 1) {
      return substring(lastDot + 1).toLowerCase();
    }
    return '';
  }

  /// Extracts clean filename from URL or file path (e.g. 'https://.../social_leads_rows.csv' -> 'social_leads_rows.csv')
  String get fileNameFromUrl {
    if (trim().isEmpty) return 'File Attachment';
    try {
      final uri = Uri.parse(trim());
      final path = uri.path;
      final name = path.split('/').lastWhere((element) => element.isNotEmpty, orElse: () => '');
      if (name.isNotEmpty) {
        return Uri.decodeComponent(name);
      }
    } catch (_) {}
    final name = split('/').last;
    return name.isNotEmpty ? Uri.decodeComponent(name) : 'File Attachment';
  }

  /// Returns true if extension corresponds to an image
  bool get isImageUrl {
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg', 'bmp', 'heic'].contains(fileExtension);
  }

  /// Returns true if extension corresponds to a video
  bool get isVideoUrl {
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(fileExtension);
  }

  /// Returns true if extension corresponds to PDF
  bool get isPdfUrl => fileExtension == 'pdf';

  /// Returns true if extension corresponds to CSV or TSV
  bool get isCsvUrl => ['csv', 'tsv'].contains(fileExtension);

  /// Returns true if extension corresponds to SQL
  bool get isSqlUrl => fileExtension == 'sql';

  /// Returns true if extension corresponds to Excel / Spreadsheet
  bool get isExcelUrl => ['xls', 'xlsx', 'csv', 'ods'].contains(fileExtension);

  /// Returns true if extension corresponds to Word / Document
  bool get isDocUrl => ['doc', 'docx', 'txt', 'rtf', 'odt'].contains(fileExtension);

  /// Returns true if extension corresponds to Archive / Compressed
  bool get isArchiveUrl => ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(fileExtension);

  /// Returns true if URL or string is any document/file format
  bool get isDocumentUrl {
    if (isImageUrl || isVideoUrl) return false;
    return fileExtension.isNotEmpty || startsWith('http://') || startsWith('https://') || startsWith('/');
  }

  /// Returns user-friendly file category label (e.g., 'CSV Document', 'SQL Script', 'PDF Document')
  String get fileTypeLabel {
    final ext = fileExtension.toUpperCase();
    if (isCsvUrl) return 'CSV Document';
    if (isSqlUrl) return 'SQL Script';
    if (isPdfUrl) return 'PDF Document';
    if (isExcelUrl) return 'Excel Spreadsheet';
    if (isDocUrl) return 'Word Document';
    if (isArchiveUrl) return 'Archive ($ext)';
    if (isImageUrl) return 'Image ($ext)';
    if (isVideoUrl) return 'Video ($ext)';
    if (ext.isNotEmpty) return '$ext File';
    return 'Document';
  }

  /// Converts string to title case
  String toTitleCase() {
    if (trim().isEmpty) return this;
    final words = trim().split(RegExp(r'\s+'));
    return words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

extension DateTimeFormatterX on DateTime {
  String get formatMediumDate => DateFormat('dd MMM yyyy').format(this);
  String get formatTimeAmPm => DateFormat('hh:mm a').format(this);
  String get formatTimestamp => DateFormat('dd MMM yyyy, hh:mm a').format(this);
}
