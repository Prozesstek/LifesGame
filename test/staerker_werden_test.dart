import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/staerker_werden.dart';

/// Die drei Tipps nach einer Niederlage (ADR-0083): aus dem eigenen
/// Stand, immer drei, nie zwei in denselben Bereich.
void main() {
  List<StaerkerWeg> wege(StaerkerStand stand) =>
      StaerkerWerden.tipps(stand).map((t) => t.weg).toList();

  test('immer drei, auch aus einem leeren Stand', () {
    final tipps = StaerkerWerden.tipps(const StaerkerStand());
    expect(tipps, hasLength(StaerkerWerden.anzahl));
    expect(tipps.map((t) => t.weg).toSet(), hasLength(3));
  });

  test('was sofort und umsonst hilft, steht vorn', () {
    expect(
      wege(
        const StaerkerStand(
          leerePlaetze: 1,
          ungenutzteFaehigkeiten: 1,
          besseresImRucksack: 2,
          freiePunkte: 3,
          offeneHaekchen: 2,
          besseresImLaden: 1,
        ),
      ),
      <StaerkerWeg>[
        StaerkerWeg.faehigkeiten,
        StaerkerWeg.ausruestung,
        StaerkerWeg.baum,
      ],
    );
  });

  test('ein leerer Platz ohne Fähigkeit dafür ist kein Tipp', () {
    expect(
      wege(const StaerkerStand(leerePlaetze: 2)),
      isNot(contains(StaerkerWeg.faehigkeiten)),
    );
  });

  test('wer in Form ist, wird nicht zu Häkchen geschickt, die fehlen', () {
    final tipps = StaerkerWerden.tipps(
      const StaerkerStand(offeneHaekchen: 2, inForm: true),
    );
    expect(tipps.any((t) => t.satz.contains('bis In Form')), isFalse);
  });

  test('die Zahl steht im Satz, in Einzahl und Mehrzahl', () {
    String satz(StaerkerStand s) => StaerkerWerden.tipps(s).first.satz;
    expect(
      satz(const StaerkerStand(freiePunkte: 1)),
      'Ein Theoriepunkt ist frei.',
    );
    expect(
      satz(const StaerkerStand(freiePunkte: 4)),
      '4 Theoriepunkte sind frei.',
    );
    expect(
      satz(const StaerkerStand(offeneHaekchen: 3)),
      'Noch 3 Häkchen bis In Form.',
    );
  });

  test('aufgefüllt wird ohne Doppel', () {
    final tipps = StaerkerWerden.tipps(const StaerkerStand(freiePunkte: 2));
    expect(tipps.first.satz, '2 Theoriepunkte sind frei.');
    expect(tipps.where((t) => t.weg == StaerkerWeg.baum), hasLength(1));
    expect(tipps, hasLength(3));
  });
}
