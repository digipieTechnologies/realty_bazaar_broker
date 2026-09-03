// File: lib/models/chat_enums.dart
// Purpose: Type-safe PostgreSQL and Flutter enums for generic chat features across all modules.

enum ChatMessageMessageType {
  text('text'),
  document('document'),
  location('location');

  final String dbValue;

  const ChatMessageMessageType(this.dbValue);

  static ChatMessageMessageType fromDbValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'location':
        return ChatMessageMessageType.location;
      case 'document':
      case 'image':
      case 'file':
        return ChatMessageMessageType.document;
      case 'text':
      default:
        return ChatMessageMessageType.text;
    }
  }
}
