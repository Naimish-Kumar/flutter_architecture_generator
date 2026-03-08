import 'dart:io';
import 'package:path/path.dart' as p;
import '../templates/theme_templates.dart';
import '../utils/pubspec_helper.dart';
import 'base_generator.dart';

/// A generator that scaffolds a premium design system and ThemeData.
class ThemeGenerator {
  /// Generates the theme files in the project's core directory.
  static Future<void> generate({String? baseDir}) async {
    final root = baseDir ?? Directory.current.path;
    final themeDir = p.join(root, 'lib', 'core', 'theme');

    // 1. Add google_fonts dependency
    PubspecHelper.addCustomDependencies({
      'google_fonts': '^6.2.1',
    }, baseDir: root);

    // 2. Create directory
    Directory(themeDir).createSync(recursive: true);

    // 3. Generate AppColors
    BaseGenerator.writeFile(
      p.join(themeDir, 'app_colors.dart'),
      ThemeTemplates.appColorsContent(),
    );

    // 4. Generate AppTheme
    BaseGenerator.writeFile(
      p.join(themeDir, 'app_theme.dart'),
      ThemeTemplates.appThemeContent(),
    );
  }
}
