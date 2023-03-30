library const_generation;

import 'package:const_generation/src/const_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

Builder generateCopyExtension(BuilderOptions options) => SharedPartBuilder(
      [ConstGenerator()],
      'const_generator',
    );
