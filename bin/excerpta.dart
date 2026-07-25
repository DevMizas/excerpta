import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

void main(List<String> arguments) async {
  final directoryPath = Directory.current.path;
  print('✂️ Excerpta - Analyzing code in: $directoryPath...\n');

  final collection = AnalysisContextCollection(
    includedPaths: [directoryPath],
  );

  final declarations = <String, DeclaredElement>{};
  final references = <String>{};

  for (final context in collection.contexts) {
    for (final filePath in context.contextRoot.analyzedFiles()) {
      if (filePath.endsWith('.g.dart') ||
          filePath.endsWith('.freezed.dart') ||
          filePath.contains('.dart_tool')) {
        continue;
      }

      if (filePath.endsWith('.dart')) {
        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          result.unit.visitChildren(
            MobxGetItUsageVisitor(
              filePath: filePath,
              onDeclarationFound: (name, path) {
                declarations[name] = DeclaredElement(name, path);
              },
              onReferenceFound: (name) {
                references.add(name);
              },
            ),
          );
        }
      }
    }
  }

  print('🛑 --- UNUSED CODE DETECTED --- 🛑\n');
  int unusedCount = 0;

  declarations.forEach((name, element) {
    if (_isFlutterOrMobxException(name)) return;

    if (!references.contains(name)) {
      print('❌ [Unused]: "$name" in ${element.path}');
      unusedCount++;
    }
  });

  if (unusedCount == 0) {
    print('✨ No dead code found! Your codebase is clean.');
  } else {
    print('\n📊 Total unused items found: $unusedCount');
  }
}

bool _isFlutterOrMobxException(String name) {
  const exceptions = {
    'main',
    'initState',
    'dispose',
    'build',
    'didChangeDependencies',
  };

  return exceptions.contains(name) || name.startsWith(r'_$');
}

class DeclaredElement {
  final String name;
  final String path;
  DeclaredElement(this.name, this.path);
}

class MobxGetItUsageVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final void Function(String name, String path) onDeclarationFound;
  final void Function(String name) onReferenceFound;

  MobxGetItUsageVisitor({
    required this.filePath,
    required this.onDeclarationFound,
    required this.onReferenceFound,
  });

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;

    if (className.startsWith('_') && className.endsWith('Base')) {
      final realClassName = className.substring(1, className.length - 4);
      onDeclarationFound(realClassName, filePath);
    } else {
      onDeclarationFound(className, filePath);
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    onReferenceFound(node.methodName.name);

    if (node.typeArguments != null) {
      for (final typeArg in node.typeArguments!.arguments) {
        onReferenceFound(typeArg.toString());
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name2.lexeme;
    onReferenceFound(typeName);

    super.visitInstanceCreationExpression(node);
  }
}
