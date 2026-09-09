import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/ui/palette.dart';

/// Ob jede Farbe auf ihrem Untergrund lesbar ist.
///
/// **Der Anlass ist ein Fehler, der eine Sitzung gekostet hat.** Beim
/// Wechsel auf Pergament wurde aus jedem hellen Text unsichtbarer Text —
/// und unsichtbar heißt: kein Absturz, keine Meldung, nichts im Log. Man
/// findet ihn nur, indem man hinsieht, und nur, wenn man den richtigen
/// Bildschirm erwischt.
///
/// Diese Prüfung nimmt das vorweg. Sie sagt nichts über Geschmack; sie
/// sagt, dass die Buchstaben da sind.
///
/// Gemessen wird der Kontrastwert nach WCAG — dasselbe Verhältnis, das
/// Browser und Prüfwerkzeuge benutzen. **4,5 für Text**, 3,0 für Flächen
/// und Ränder, die nur unterscheidbar sein müssen.
void main() {
  /// Das Verhältnis der Helligkeiten zweier Farben, heller zu dunkler.
  double kontrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  const fuerText = 4.5;
  const fuerFlaechen = 3.0;

  group('Auf Pergament', () {
    const grund = Palette.surface;

    test('Schrift ist gut lesbar', () {
      expect(kontrast(Palette.text, grund), greaterThanOrEqualTo(7));
      expect(kontrast(Palette.textDim, grund), greaterThanOrEqualTo(fuerText));
    });

    test('jede Bedeutung ist lesbar', () {
      for (final farbe in <Color>[
        Palette.accent,
        Palette.enemy,
        Palette.success,
        Palette.gold,
      ]) {
        expect(kontrast(farbe, grund), greaterThanOrEqualTo(fuerText));
      }
    });

    test('helle Schrift auf dem Akzent ebenfalls', () {
      // Der aktive Reiter im Laden und der Knopf für eine eigene
      // Gewohnheit sind gefüllt — dort steht Pergament auf Akzent.
      expect(
        kontrast(Palette.surface, Palette.accent),
        greaterThanOrEqualTo(fuerFlaechen),
      );
    });

    test('was nicht gilt, tritt zurück — aber bleibt sichtbar', () {
      // `muted` markiert Gesperrtes und Leeres. Es **soll** schwach sein;
      // ganz verschwinden darf es trotzdem nicht.
      final wert = kontrast(Palette.muted, grund);
      expect(wert, greaterThan(1.8));
      expect(
        wert,
        lessThan(fuerText),
        reason: 'Wäre es so kräftig wie normale Schrift, wäre es keins.',
      );
    });
  });

  group('Auf Leder', () {
    const grund = Palette.background;

    test('Schrift ist gut lesbar', () {
      expect(kontrast(Palette.textOnDark, grund), greaterThanOrEqualTo(7));
      expect(
        kontrast(Palette.textOnDarkDim, grund),
        greaterThanOrEqualTo(fuerText),
      );
    });

    test('jede Bedeutung hat ein lesbares Gegenstück', () {
      for (final farbe in <Color>[
        Palette.accentOnDark,
        Palette.enemyOnDark,
        Palette.successOnDark,
        Palette.goldOnDark,
      ]) {
        expect(kontrast(farbe, grund), greaterThanOrEqualTo(fuerText));
      }
    });

    test('die Zeitfenster heben sich von der Mulde ab', () {
      // Sie tragen keine Schrift, müssen aber im Eifer eines Kampfes
      // auseinanderzuhalten sein — von der Mulde und voneinander.
      expect(
        kontrast(Palette.timingGood, Palette.trackOnDark),
        greaterThanOrEqualTo(fuerFlaechen),
      );
      expect(
        kontrast(Palette.timingPerfect, Palette.trackOnDark),
        greaterThanOrEqualTo(fuerFlaechen),
      );
      expect(
        kontrast(Palette.timingPerfect, Palette.timingGood),
        greaterThan(1.4),
        reason: 'Ordentlich und perfekt dürfen nicht gleich aussehen.',
      );
    });
  });

  group('Die beiden Welten bleiben getrennt', () {
    test('kein Pergamentwert taugt als Schrift auf Leder', () {
      // Das ist keine Spitzfindigkeit, sondern genau die Verwechslung,
      // die den Fehler erzeugt: Wer im Kampf `Palette.text` nimmt statt
      // `Palette.textOnDark`, schreibt mit Tinte auf Leder.
      expect(
        kontrast(Palette.text, Palette.background),
        lessThan(fuerFlaechen),
      );
    });

    test('und umgekehrt', () {
      expect(
        kontrast(Palette.textOnDark, Palette.surface),
        lessThan(fuerFlaechen),
      );
    });
  });
}
