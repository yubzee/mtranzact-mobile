import 'dart:math' as math;

/// A utility class for evaluating mathematical formulas with variable substitution
/// Supports:
/// - Basic arithmetic: +, -, *, /, ()
/// - Field references: {field_name}
/// - Aggregate functions: SUM({field}), AVG({field}), MIN({field}), MAX({field}), COUNT({field})
class FormulaEvaluator {
  /// Evaluate a formula with a single row of data
  /// Example: evaluateFormula("({qty} * {price}) + {tax}", {"qty": 2, "price": 10, "tax": 1.5}) => 21.5
  /// Also supports: "(qty * price) + tax" without braces
  static double evaluateFormula(String formula, Map<String, dynamic> data) {
    if (formula.isEmpty) return 0.0;

    try {
      // Replace field references with actual values
      String expression = formula;

      // First, find all field references {field_name} with braces and replace with values
      final fieldPattern = RegExp(r'\{([^}]+)\}');
      var matches = fieldPattern.allMatches(expression);

      for (final match in matches) {
        final fieldName = match.group(1);
        if (fieldName != null && data.containsKey(fieldName)) {
          final value = _convertToDouble(data[fieldName]);
          expression = expression.replaceAll('{$fieldName}', value.toString());
        } else {
          // Field not found, replace with 0
          expression = expression.replaceAll('{$fieldName}', '0');
        }
      }

      // Second, find all word-based field references (without braces) and replace
      // This pattern matches words that are field names in the data
      for (final fieldName in data.keys) {
        // Use word boundary to match whole words only
        final wordPattern = RegExp('\\b$fieldName\\b');
        if (wordPattern.hasMatch(expression)) {
          final value = _convertToDouble(data[fieldName]);
          expression = expression.replaceAll(wordPattern, value.toString());
        }
      }

      // Evaluate the mathematical expression
      return _evaluate(expression);
    } catch (e) {
      return 0.0;
    }
  }

  /// Evaluate a formula with aggregate functions (SUM, AVG, etc.) over multiple rows
  /// Example: evaluateAggregateFormula("SUM({qty})", [{"qty": 2}, {"qty": 3}]) => 5.0
  /// Also supports: "SUM(qty)" and "COUNT(*)"
  static double evaluateAggregateFormula(
      String formula, List<Map<String, dynamic>> rows) {
    if (formula.isEmpty || rows.isEmpty) return 0.0;

    try {
      String expression = formula;

      // Handle aggregate functions with braces: SUM({field})
      final aggregatePattern = RegExp(r'(SUM|AVG|MIN|MAX|COUNT)\(\{([^}]+)\}\)',
          caseSensitive: false);
      var matches = aggregatePattern.allMatches(expression);

      for (final match in matches) {
        final function = match.group(1)?.toUpperCase();
        final fieldName = match.group(2);

        if (function != null && fieldName != null) {
          final values =
              rows.map((row) => _convertToDouble(row[fieldName])).toList();

          double result = 0.0;
          switch (function) {
            case 'SUM':
              result = values.fold(0.0, (sum, val) => sum + val);
              break;
            case 'AVG':
              result = values.isEmpty
                  ? 0.0
                  : values.fold(0.0, (sum, val) => sum + val) / values.length;
              break;
            case 'MIN':
              result = values.isEmpty ? 0.0 : values.reduce(math.min);
              break;
            case 'MAX':
              result = values.isEmpty ? 0.0 : values.reduce(math.max);
              break;
            case 'COUNT':
              result = values.length.toDouble();
              break;
          }

          expression =
              expression.replaceAll(match.group(0)!, result.toString());
        }
      }

      // Handle aggregate functions without braces: SUM(field) or COUNT(*)
      final simpleAggregatePattern =
          RegExp(r'(SUM|AVG|MIN|MAX|COUNT)\(([^)]+)\)', caseSensitive: false);
      matches = simpleAggregatePattern.allMatches(expression);

      for (final match in matches) {
        final function = match.group(1)?.toUpperCase();
        final fieldName = match.group(2)?.trim();

        if (function != null && fieldName != null) {
          double result = 0.0;

          if (function == 'COUNT' && fieldName == '*') {
            result = rows.length.toDouble();
          } else {
            final values =
                rows.map((row) => _convertToDouble(row[fieldName])).toList();

            switch (function) {
              case 'SUM':
                result = values.fold(0.0, (sum, val) => sum + val);
                break;
              case 'AVG':
                result = values.isEmpty
                    ? 0.0
                    : values.fold(0.0, (sum, val) => sum + val) / values.length;
                break;
              case 'MIN':
                result = values.isEmpty ? 0.0 : values.reduce(math.min);
                break;
              case 'MAX':
                result = values.isEmpty ? 0.0 : values.reduce(math.max);
                break;
              case 'COUNT':
                result = values.length.toDouble();
                break;
            }
          }

          expression =
              expression.replaceAll(match.group(0)!, result.toString());
        }
      }

      // Now evaluate any remaining mathematical operations
      return _evaluate(expression);
    } catch (e) {
      return 0.0;
    }
  }

  /// Convert any value to double
  static double _convertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  /// Simple mathematical expression evaluator
  /// Supports +, -, *, /, (), with proper operator precedence
  static double _evaluate(String expression) {
    expression = expression.replaceAll(' ', '');
    if (expression.isEmpty) return 0.0;

    return _parseExpression(expression);
  }

  static double _parseExpression(String expr) {
    // Handle addition and subtraction (lowest precedence)
    int level = 0;
    for (int i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == ')') level++;
      if (expr[i] == '(') level--;

      if (level == 0 && (expr[i] == '+' || expr[i] == '-')) {
        if (i > 0) {
          // Make sure it's not a unary operator
          final left = _parseExpression(expr.substring(0, i));
          final right = _parseExpression(expr.substring(i + 1));
          return expr[i] == '+' ? left + right : left - right;
        }
      }
    }

    // Handle multiplication and division (higher precedence)
    level = 0;
    for (int i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == ')') level++;
      if (expr[i] == '(') level--;

      if (level == 0 && (expr[i] == '*' || expr[i] == '/')) {
        final left = _parseExpression(expr.substring(0, i));
        final right = _parseExpression(expr.substring(i + 1));
        return expr[i] == '*' ? left * right : left / right;
      }
    }

    // Handle parentheses
    if (expr.startsWith('(') && expr.endsWith(')')) {
      return _parseExpression(expr.substring(1, expr.length - 1));
    }

    // Handle negative numbers
    if (expr.startsWith('-')) {
      return -_parseExpression(expr.substring(1));
    }

    // Parse as number
    return double.tryParse(expr) ?? 0.0;
  }

  /// Helper method to get all field references in a formula
  static List<String> getFieldReferences(String formula) {
    final fieldPattern = RegExp(r'\{([^}]+)\}');
    final matches = fieldPattern.allMatches(formula);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Check if formula contains aggregate functions
  static bool hasAggregateFunction(String formula) {
    final aggregatePattern =
        RegExp(r'(SUM|AVG|MIN|MAX|COUNT)\(', caseSensitive: false);
    return aggregatePattern.hasMatch(formula);
  }
}
