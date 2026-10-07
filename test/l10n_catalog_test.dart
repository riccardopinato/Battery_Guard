import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all ARB catalogs expose the same message keys', () {
    const languages = ['en', 'it', 'es', 'fr', 'de', 'pt'];

    Set<String> readKeys(String language) {
      final raw = File('lib/l10n/app_$language.arb').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.keys.where((key) => !key.startsWith('@')).toSet();
    }

    final english = readKeys('en');
    expect(english, isNotEmpty);

    for (final language in languages.skip(1)) {
      expect(
        readKeys(language),
        english,
        reason: 'Localization catalog mismatch for $language',
      );
    }
  });
}
