class StringUtils {
  static String toSnakeCase(String name) {
    return name
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'_+'), '_');
  }

  static String toPascalCase(String name) {
    final snake = toSnakeCase(name);
    return snake
        .split('_')
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join('');
  }

  static String toCamelCase(String name) {
    final pascal = toPascalCase(name);
    if (pascal.isEmpty) return '';
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}
