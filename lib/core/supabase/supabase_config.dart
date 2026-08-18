// File: lib/core/supabase/supabase_config.dart
// Purpose: Entry point for Supabase client interactions.

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  /// Global single source of truth for the Supabase Client.
  /// Used for database, real-time, and authentication operations.
  static SupabaseClient get client => Supabase.instance.client;
}
