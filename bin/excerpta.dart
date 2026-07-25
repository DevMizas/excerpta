import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// The main entry point for the Excerpta CLI executable.
///
/// Scans the current working directory for Dart and Flutter code, parses ASTs,
/// and outputs declarations that are never referenced across the codebase.
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

/// Checks whether a given symbol [name] is a framework lifecycle method
/// or a MobX generated artifact that should be ignored.
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

/// Represents a declared code element found during AST analysis.
class DeclaredElement {
  /// The name of the declared class, function, or symbol.
  final String name;

  /// The file path where this declaration was found.
  final String path;

  /// Creates a new [DeclaredElement] with its [name] and [path].
  DeclaredElement(this.name, this.path);
}

/// An AST visitor that identifies declarations and references,
/// with native support for MobX store names and GetIt generics.
class MobxGetItUsageVisitor extends RecursiveAstVisitor<void> {
  /// The path of the file being visited.
  final String filePath;

  /// Callback triggered when a declaration (e.g., class) is identified.
  final void Function(String name, String path) onDeclarationFound;

  /// Callback triggered when a reference/usage of a symbol is identified.
  final void Function(String name) onReferenceFound;

  /// Creates a [MobxGetItUsageVisitor] with callbacks for found declarations and references.
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