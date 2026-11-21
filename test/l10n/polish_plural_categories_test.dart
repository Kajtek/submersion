// pre-push: scans lib/l10n/arb/
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:submersion/l10n/arb/app_localizations.dart';

import '../helpers/icu_plural_branches.dart';

/// Polish has four CLDR plural categories, and the counted noun changes form
/// across them: one (1 nurkowanie), few (2 to 4, 22 to 24: nurkowania), many
/// (5 to 21, 25 and up: nurkowań) and other (fractions). A plural that gives
/// only `=1` and `other`, as the English template does, falls back to `other`
/// for every count above one without an error, so either 2 or 5 takes the
/// wrong noun form.
void main() {
  test('every Polish plural gives the one, few, many and other forms', () {
    final arb =
        jsonDecode(
              File(
                p.join('lib', 'l10n', 'arb', 'app_pl.arb'),
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    final offenders = <String>[];
    arb.forEach((key, value) {
      if (key.startsWith('@') || value is! String) return;
      forEachPluralArgument(value, (argument, branches) {
        final missing = [
          if (!branches.containsKey('one') && !branches.containsKey('=1'))
            'one',
          for (final category in const ['few', 'many', 'other'])
            if (!branches.containsKey(category)) category,
        ];
        if (missing.isNotEmpty) {
          offenders.add('$key [$argument] lacks ${missing.join(', ')}');
        }
      });
    });

    expect(
      offenders,
      isEmpty,
      reason:
          '${offenders.length} plural(s) in app_pl.arb miss Polish plural '
          'categories, so their counts fall back to `other` and take the '
          'wrong noun form.\n'
          '${offenders.take(20).join('\n')}'
          '${offenders.length > 20 ? '\n...and ${offenders.length - 20} more' : ''}',
    );
  });

  test('the counted noun agrees with its count', () {
    final pl = lookupAppLocalizations(const Locale('pl'));

    expect(pl.buddies_label_diveCount(1), '1 nurkowanie');
    expect(pl.buddies_label_diveCount(2), '2 nurkowania');
    expect(pl.buddies_label_diveCount(5), '5 nurkowań');
    expect(pl.buddies_label_diveCount(12), '12 nurkowań');
    expect(pl.buddies_label_diveCount(22), '22 nurkowania');
    expect(pl.buddies_label_diveCount(0), '0 nurkowań');
  });
}
