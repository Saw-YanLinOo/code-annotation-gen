import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:const_annotation/const_annotation.dart';
import 'package:source_gen/source_gen.dart';

class ConstGenerator extends GeneratorForAnnotation<ConstAnnotation> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is TopLevelVariableElement) {
      final variableName = capitalizeFirstLetter(element.name);

      final variableValue =
          element.computeConstantValue()?.toStringValue() ?? "";

      final jsonMap = json.decode(variableValue) as Map<String, dynamic>;

      final buffer = StringBuffer()..writeln();
      final generatedClasses = <String>{};

      _generateClass(buffer, variableName, jsonMap, generatedClasses);

      return buffer.toString();
    }
  }
}

String capitalizeFirstLetter(String s) {
  if (s.isEmpty) {
    return s;
  } else {
    final firstLetter = s.substring(0, 1).toUpperCase();
    final restOfString = s.substring(1);
    return firstLetter + restOfString;
  }
}

void _generateClass(
  StringBuffer buffer,
  String className,
  Map<String, dynamic> jsonMap,
  Set<String> generatedClasses,
) {
  if (generatedClasses.contains(className)) return;

  generatedClasses.add(className);

  buffer.writeln('class $className {');

  jsonMap.forEach((key, dynamic value) {
    final type = _getType(value, key);
    buffer.writeln('  final $type? $key;');
  });

  // Unnamed constructor
  buffer
    ..writeln()
    ..writeln('  $className({')
    ..writeAll(jsonMap.entries.map((e) => 'this.${e.key}, '))
    ..writeln('});')
    ..writeln()

    // fromJson factory method
    ..writeln()
    ..writeln('  factory $className.fromJson(Map<String, dynamic> json) {')
    ..writeln('    return $className(')
    ..writeAll(
      jsonMap.entries.map((e) {
        final type = _getType(e.value, e.key);
        if (type.startsWith('List<')) {
          return "      ${e.key}: (json['${e.key}'] as List<dynamic>?)?.map((e) => ${type.substring(5, type.length - 1)}.fromJson(e as Map<String, dynamic>)).toList(),";
        } else if (e.value is Map) {
          return "      ${e.key}: json['${e.key}'] !=null ? ${_getType(e.value, e.key)}.fromJson(json['${e.key}'] as Map<String, dynamic>) : null,";
        } else {
          return "      ${e.key}: json['${e.key}'] != null ? json['${e.key}'] as ${_getType(e.value, e.key)}? : null,";
        }
      }),
    )
    ..writeln('    );')
    ..writeln('  }')

    // toJson method
    ..writeln()
    ..writeln('  Map<String, dynamic> toJson() {')
    ..writeln('    return {')
    ..writeAll(
      jsonMap.entries.map((e) {
        final type = _getType(e.value, e.key);
        if (type.startsWith('List<')) {
          return "      '${e.key}': ${e.key}?.map((e) => e.toJson()).toList(),";
        } else if (e.value is Map) {
          return "      '${e.key}': ${e.key}?.toJson(),";
        } else {
          return "      '${e.key}': ${e.key},";
        }
      }),
    )
    ..writeln('    };')
    ..writeln('  }')
    ..writeln('}');

  jsonMap.forEach((key, dynamic value) {
    if (value is Map<String, dynamic>) {
      _generateClass(buffer, _getType(value, key), value, generatedClasses);
    } else if (value is List) {
      if (value.isNotEmpty && value.first is Map) {
        _generateClass(
          buffer,
          _getType(value.first, key),
          value.first as Map<String, dynamic>,
          generatedClasses,
        );
      }
      for (final element in value) {
        if (element is Map<String, dynamic>) {
          _generateClass(
            buffer,
            _getType(element, key),
            element,
            generatedClasses,
          );
        }
      }
    }
  });
}

String _getType(dynamic value, String key) {
  if (value is int) {
    return 'int';
  } else if (value is double) {
    return 'double';
  } else if (value is String) {
    return 'String';
  } else if (value is bool) {
    return 'bool';
  } else if (value is List) {
    if (value.isEmpty) {
      return 'List<dynamic>';
    } else {
      return 'List<${_getType(value.first, key)}>';
    }
  } else if (value is Map) {
    return _capitalize(key);
  } else {
    return 'dynamic';
  }
}

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
