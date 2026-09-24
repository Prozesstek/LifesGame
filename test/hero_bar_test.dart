import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/ui/palette.dart';

/// Der Balken über dem Helden in der Grube. Gezeichnet wird in Flame und
/// damit ungeprüft; die Regel für die Farbe steht als Funktion da.
void main() {
  test('bei vollem Leben grün', () {
    expect(ActionGame.heroBarColor(1), Palette.successOnDark);
  });

  test('knapp über einem Drittel noch grün', () {
    expect(ActionGame.heroBarColor(0.34), Palette.successOnDark);
  });

  test('ab einem Drittel golden — nie rot, das gehört dem Wächter', () {
    expect(ActionGame.heroBarColor(ActionGame.lowHpShare), Palette.goldOnDark);
    expect(ActionGame.heroBarColor(0.05), Palette.goldOnDark);
    expect(ActionGame.heroBarColor(0.05), isNot(Palette.enemyOnDark));
  });
}
