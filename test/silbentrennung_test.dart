import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/theory/silbentrennung.dart';

/// Die Silbentrennung trennt deutsche Wörter dort, wo man es im Buch
/// erwartet — mit den echten Mustern aus `assets/Silbentrennung/`.
void main() {
  final trennung = Silbentrennung.aus(
    File(Silbentrennung.pfad).readAsStringSync(),
  );

  String sichtbar(String wort) =>
      trennung.trenne(wort).replaceAll(Silbentrennung.weich, '-');

  test('trennt typische Wörter des Lernbuchs an Silben', () {
    expect(sichtbar('Anpassung'), 'An-pas-sung');
    expect(sichtbar('Überlastung'), 'Über-las-tung');
    expect(sichtbar('Wiederholungen'), 'Wie-der-ho-lun-gen');
  });

  test('Satzzeichen bleiben außen, kurze Wörter bleiben ganz', () {
    expect(sichtbar('Anpassung.'), 'An-pas-sung.');
    expect(sichtbar('„Muskeln“'), '„Mus-keln“');
    expect(trennung.trenne('Last'), 'Last');
    expect(trennung.trenne('Kraft-Training'), 'Kraft-Training');
  });

  test('nie weniger als zwei Buchstaben vor oder nach dem Strich', () {
    for (final wort in <String>['Abenteuer', 'Ereignisse', 'Ausdauer']) {
      final teile = sichtbar(wort).split('-');
      expect(teile.first.length, greaterThanOrEqualTo(2), reason: wort);
      expect(teile.last.length, greaterThanOrEqualTo(2), reason: wort);
    }
  });
}
