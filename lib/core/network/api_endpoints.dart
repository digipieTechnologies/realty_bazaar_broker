// File: lib/core/network/api_endpoints.dart
// Purpose: Definition of API endpoints paths.

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (read from config in practice, default placeholder here)
  static const String baseUrl = 'https://api.brokerflow.example.com/v1';

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Leads endpoints (placeholder examples)
  static const String leadsList = '/leads';
  static const String leadDetails = '/leads/'; // Append ID
}
