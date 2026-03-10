/// Templates for generating API integration code.
class ApiTemplates {
  /// Returns the content for an API entity.
  static String entityContent({
    required String className,
    required String fields,
    required String constructor,
  }) {
    return '''
class $className {
$fields

  const $className({
$constructor
  });
}
''';
  }

  /// Returns the content for an API model.
  static String modelContent({
    required String className,
    required String fileName,
    required String packageName,
    required String snakeFeature,
    required String fields,
    required String constructor,
    String? superName,
    String? superConstructor,
  }) {
    final extendsClause = superName != null ? ' extends $superName' : '';
    final superCall =
        superConstructor != null ? ' : super(\n$superConstructor\n  )' : '';
    final entityImport = superName != null
        ? "import 'package:$packageName/features/$snakeFeature/domain/entities/${fileName}_entity.dart';\n"
        : '';

    return '''
import 'package:json_annotation/json_annotation.dart';
$entityImport
part '${fileName}_model.g.dart';

@JsonSerializable()
class ${className}Model$extendsClause {
$fields

  const ${className}Model({
$constructor
  })$superCall;

  factory ${className}Model.fromJson(Map<String, dynamic> json) =>
      _\$${className}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\$${className}ModelToJson(this);
}
''';
  }

  /// Returns the content for an API service.
  static String serviceContent({
    required String className,
    required String fileName,
    required String packageName,
    required String url,
    required String returnType,
    required String fromJsonCall,
    String method = 'GET',
  }) {
    final dioMethod = method.toLowerCase();
    final hasData = ['post', 'put', 'patch', 'delete'].contains(dioMethod);
    final params = [
      if (hasData) 'dynamic data',
      'Map<String, dynamic>? queryParameters',
    ].join(', ');

    final dioArgs = [
      if (hasData) 'data: data',
      'queryParameters: queryParameters',
    ].join(',\n        ');

    return '''
import 'package:dio/dio.dart';
import 'package:$packageName/core/network/api_client.dart';
import '../models/${fileName}_model.dart';

class ${className}Service {
  final ApiClient _client;

  ${className}Service(this._client);

  /// Executes the $method request for $className.
  Future<$returnType> get${className}Data({$params}) async {
    try {
      final response = await _client.dio.$dioMethod(
        '$url',
        $dioArgs
      );
      return $fromJsonCall;
    } catch (e) {
      rethrow;
    }
  }
}
''';
  }

  /// Returns the content for an API repository interface.
  static String repositoryInterfaceContent({
    required String className,
    required String fileName,
    required String returnType,
    String method = 'GET',
  }) {
    final hasData =
        ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method.toUpperCase());
    final params = [
      if (hasData) 'dynamic data',
      'Map<String, dynamic>? queryParameters',
    ].map((e) => '$e,').join(' ');

    return '''
import '../entities/${fileName}_entity.dart';

abstract class I${className}Repository {
  Future<$returnType> get${className}Data({$params});
}
''';
  }

  /// Returns the content for an API repository implementation.
  static String repositoryImplContent({
    required String className,
    required String fileName,
    required String returnType,
    bool isClean = true,
    String method = 'GET',
  }) {
    final hasData =
        ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method.toUpperCase());
    final params = [
      if (hasData) 'dynamic data',
      'Map<String, dynamic>? queryParameters',
    ].map((e) => '$e,').join(' ');

    final args = [
      if (hasData) 'data: data',
      'queryParameters: queryParameters',
    ].join(', ');

    if (isClean) {
      return '''
import '../../domain/repositories/${fileName}_repository.dart';
import '../../domain/entities/${fileName}_entity.dart';
import '../services/${fileName}_service.dart';

class ${className}RepositoryImpl implements I${className}Repository {
  final ${className}Service _service;

  ${className}RepositoryImpl(this._service);

  @override
  Future<$returnType> get${className}Data({$params}) async {
    return await _service.get${className}Data($args);
  }
}
''';
    } else {
      return '''
import '../services/${fileName}_service.dart';
import '../models/${fileName}_model.dart';

class ${className}Repository {
  final ${className}Service _service;

  ${className}Repository(this._service);

  Future<$returnType> get${className}Data({$params}) async {
    return await _service.get${className}Data($args);
  }
}
''';
    }
  }

  /// Returns the content for an API use case.
  static String useCaseContent({
    required String className,
    required String fileName,
    required String returnType,
    required String packageName,
    required String snakeFeature,
    String method = 'GET',
  }) {
    final hasData =
        ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method.toUpperCase());
    final params = [
      if (hasData) 'dynamic data',
      'Map<String, dynamic>? queryParameters',
    ].map((e) => '$e,').join(' ');

    final args = [
      if (hasData) 'data: data',
      'queryParameters: queryParameters',
    ].join(', ');

    return '''
import 'package:$packageName/features/$snakeFeature/domain/repositories/${fileName}_repository.dart';
import 'package:$packageName/features/$snakeFeature/domain/entities/${fileName}_entity.dart';

class Get${className}UseCase {
  final I${className}Repository _repository;

  Get${className}UseCase(this._repository);

  Future<$returnType> execute({$params}) async {
    return await _repository.get${className}Data($args);
  }
}
''';
  }

  /// Returns the content for an API service unit test.
  static String serviceTestContent({
    required String className,
    required String fileName,
    required String packageName,
    required String snakeFeature,
    bool isClean = true,
  }) {
    final servicePath = isClean ? 'data/services' : 'services';
    final modelPath = isClean ? 'data/models' : 'models';
    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:$packageName/core/network/api_client.dart';
import 'package:$packageName/features/$snakeFeature/$servicePath/${fileName}_service.dart';
import 'package:$packageName/features/$snakeFeature/$modelPath/${fileName}_model.dart';

@GenerateMocks([ApiClient])
void main() {
  late ${className}Service service;
  late MockApiClient mockClient;
  late Dio mockDio;

  setUp(() {
    mockClient = MockApiClient();
    mockDio = Dio(); // You might want to mock Dio specifically if needed
    service = ${className}Service(mockClient);
  });

  group('get${className}Data', () {
    test('should return data when status code is 200', () async {
      // TODO: Implement test
    });
  });
}
''';
  }

  /// Returns the content for an API repository unit test.
  static String repositoryTestContent({
    required String className,
    required String fileName,
    required String packageName,
    required String snakeFeature,
    bool isClean = true,
  }) {
    final repoSuffix = isClean ? 'Impl' : '';
    final servicePath = isClean ? 'data/services' : 'services';
    final serviceImport =
        "import 'package:$packageName/features/$snakeFeature/$servicePath/${fileName}_service.dart';";

    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
$serviceImport
import 'package:$packageName/features/$snakeFeature/${isClean ? "data/repositories" : "repositories"}/${fileName}_repository$repoSuffix.dart';

@GenerateMocks([${className}Service])
void main() {
  late ${className}Repository$repoSuffix repository;
  late Mock${className}Service mockService;

  setUp(() {
    mockService = Mock${className}Service();
    repository = ${className}Repository$repoSuffix(mockService);
  });

  group('get${className}Data', () {
    test('should return data from service', () async {
      // TODO: Implement test
    });
  });
}
''';
  }
}
