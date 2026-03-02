/// Input validation utilities.
///
/// Validates feature, model, page, and widget names to ensure they
/// produce valid Dart identifiers and file names.
library;

/// Provides name validation for code generation inputs.
class ValidationUtils {
  /// Dart reserved keywords that cannot be used as identifiers.
  static const _reservedKeywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'of',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'type',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };

  /// Validates a name for use as a feature, model, page, widget, or service.
  ///
  /// Returns `null` if the name is valid, or a descriptive error message
  /// if the name is invalid.
  static String? validateName(String name, String type) {
    if (name.isEmpty) {
      return '$type name cannot be empty.';
    }

    if (name.length > 100) {
      return '$type name is too long (max 100 characters).';
    }

    // Check for invalid characters (only letters, numbers, underscores allowed)
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
      return '$type name "$name" contains invalid characters.\n'
          'Only letters, numbers, and underscores are allowed.\n'
          'The name must start with a letter or underscore.';
    }

    // Check for reserved keywords (case-insensitive check on lowercase)
    if (_reservedKeywords.contains(name.toLowerCase())) {
      return '$type name "$name" is a Dart reserved keyword.\n'
          'Please choose a different name.';
    }

    return null;
  }
}
