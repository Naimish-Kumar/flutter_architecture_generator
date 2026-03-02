/// String utility functions for name conversion.
///
/// Provides conversions between naming conventions used in Dart:
/// snake_case, PascalCase, and camelCase.
class StringUtils {
  /// Converts a string to snake_case.
  ///
  /// Handles acronyms correctly:
  /// - `'UserProfile'` → `'user_profile'`
  /// - `'HTMLParser'` → `'html_parser'`
  /// - `'getHTTPResponse'` → `'get_http_response'`
  static String toSnakeCase(String name) {
    if (name.isEmpty) return '';
    return name
        // Handle transitions like HTTPResponse → HTTP_Response
        .replaceAllMapped(
            RegExp(r'([A-Z]+)([A-Z][a-z])'), (m) => '${m[1]}_${m[2]}')
        // Handle transitions like myVariable → my_Variable
        .replaceAllMapped(RegExp(r'([a-z\d])([A-Z])'), (m) => '${m[1]}_${m[2]}')
        .toLowerCase()
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_'), '');
  }

  /// Converts a string to PascalCase.
  ///
  /// Example: `'user_profile'` → `'UserProfile'`
  static String toPascalCase(String name) {
    final snake = toSnakeCase(name);
    return snake
        .split('_')
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join('');
  }

  /// Converts a string to camelCase.
  ///
  /// Example: `'user_profile'` → `'userProfile'`
  static String toCamelCase(String name) {
    final pascal = toPascalCase(name);
    if (pascal.isEmpty) return '';
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}
