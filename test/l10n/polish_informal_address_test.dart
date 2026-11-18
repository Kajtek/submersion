// pre-push: scans lib/l10n/arb/
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The Polish UI addresses the diver informally, as German does since
/// #4331: "ty" in the second person, never "Pan", "Pani" or "Państwo".
///
/// Polish capitalises "Twój", "Ciebie" and their forms in letters as a
/// courtesy, which in an app reads as the formal register too, so in the
/// middle of a sentence they stay lowercase. At the start of a sentence the
/// capital is ordinary, so those positions are not checked.
void main() {
  final arb =
      json.decode(
            File(p.join('lib', 'l10n', 'arb', 'app_pl.arb')).readAsStringSync(),
          )
          as Map<String, dynamic>;

  final formal = RegExp(
    r'(?<!\p{L})(Pan|Pani|Pana|Panu|Panią|Państwo|Państwa|Państwu)(?!\p{L})',
    unicode: true,
  );
  final capitalisedYou = RegExp(
    r'(?<!\p{L})(Twój|Twoja|Twoje|Twojego|Twojej|Twoich|Twoim|Twoją|Twoimi|Ty|Ciebie|Cię|Ci|Tobie|Tobą)(?!\p{L})',
    unicode: true,
  );

  /// Characters after which a new sentence (or a plural branch, or a quoted
  /// phrase) begins, so a capital there says nothing about the register.
  const sentenceStarts = {'.', '!', '?', ':', '\n', '{', '"'};

  bool atSentenceStart(String value, int index) {
    final before = value.substring(0, index).trimRight();
    if (before.isEmpty) return true;
    return sentenceStarts.contains(before[before.length - 1]);
  }

  test('no Polish string addresses the diver formally', () {
    final offenders = [
      for (final MapEntry(:key, :value) in arb.entries)
        if (!key.startsWith('@') && value is String && formal.hasMatch(value))
          '$key = $value',
    ];
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('"you" is lowercase in the middle of a Polish sentence', () {
    final offenders = <String>[];
    arb.forEach((key, value) {
      if (key.startsWith('@') || value is! String) return;
      for (final match in capitalisedYou.allMatches(value)) {
        if (!atSentenceStart(value, match.start)) {
          offenders.add('$key = $value');
          break;
        }
      }
    });
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
