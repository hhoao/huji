import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/shortcuts/command_scope.dart';

void main() {
  group('isPrecisionEditRoute', () {
    test('matches desktop precision-edit paths', () {
      expect(isPrecisionEditRoute('/clip/abc-123/edit'), isTrue);
      expect(isPrecisionEditRoute('/clip/foo%20bar/edit'), isTrue);
    });

    test('rejects other routes', () {
      expect(isPrecisionEditRoute(null), isFalse);
      expect(isPrecisionEditRoute(''), isFalse);
      expect(isPrecisionEditRoute('/'), isFalse);
      expect(isPrecisionEditRoute('/clip/new'), isFalse);
      expect(isPrecisionEditRoute('/clip/id/preview'), isFalse);
      expect(isPrecisionEditRoute('/clip/id/edit/extra'), isFalse);
    });
  });

  group('commandScopeMatches', () {
    test('global scope always matches', () {
      expect(commandScopeMatches(CommandScope.global, '/'), isTrue);
      expect(commandScopeMatches(CommandScope.global, null), isTrue);
    });

    test('precision edit scope only matches edit route', () {
      expect(
        commandScopeMatches(CommandScope.precisionEdit, '/clip/x/edit'),
        isTrue,
      );
      expect(commandScopeMatches(CommandScope.precisionEdit, '/'), isFalse);
    });
  });
}
