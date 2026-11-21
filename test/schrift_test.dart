import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/main.dart';
import 'package:lifes_game/theory/widgets/buch_stil.dart';
import 'package:lifes_game/ui/menue_leiste.dart';
import 'package:lifes_game/ui/schrift.dart';

void main() {
  test('die App spricht Alegreya Sans, Lernbuch und Titel nicht', () {
    final theme = LifesGameApp.theme();
    expect(theme.textTheme.bodyMedium?.fontFamily, Schrift.app);
    expect(theme.textTheme.titleMedium?.fontFamily, Schrift.app);
    expect(MenueLeiste.titel.fontFamily, isNot(Schrift.app));
    expect(BuchStil.fliessSchrift, isNot(Schrift.app));
  });

  test('jede Datei der Schrift liegt im Repo und steht in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: ${Schrift.app}'));
    for (final datei in <String>[
      'AlegreyaSans-Regular.ttf',
      'AlegreyaSans-Italic.ttf',
      'AlegreyaSans-Medium.ttf',
      'AlegreyaSans-Bold.ttf',
      'OFL-AlegreyaSans.txt',
    ]) {
      expect(File('assets/fonts/$datei').existsSync(), isTrue, reason: datei);
      if (datei.endsWith('.ttf')) {
        expect(pubspec, contains('assets/fonts/$datei'), reason: datei);
      }
    }
  });
}
