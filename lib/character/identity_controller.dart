import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity/identity.dart';

import '../achievements/achievements_controller.dart';
import '../save/save_providers.dart';

/// Bindeglied zwischen Identität und Oberfläche.
///
/// Enthält bewusst **keine** Regeln: Welche Titel es gibt, was sie kosten
/// und ab wann sie verdient sind, steht in `package:identity`. Dieser
/// Controller reicht durch und hält den laufenden Zustand (ADR-0013).
class IdentityController extends Notifier<Identity> {
  @override
  Identity build() => ref.watch(savedGameProvider).identity;

  void setName(String name) {
    state = state.withName(name);
  }

  /// Wählt einen Titel oder legt ihn ab (null).
  ///
  /// Ob er verdient ist, prüft die Oberfläche, bevor sie ihn überhaupt
  /// anbietet — und `Identity.titleFor` ein zweites Mal beim Anzeigen. Der
  /// Controller entscheidet das nicht, sonst stünde die Bedingung an einer
  /// dritten Stelle.
  void chooseTitle(String? titleId) {
    state = state.withTitle(titleId);
  }
}

final identityProvider = NotifierProvider<IdentityController, Identity>(
  IdentityController.new,
);

/// Alle Titel, die der Spieler tragen darf.
///
/// **Seit ADR-0033 kommt die Bedingung aus den Errungenschaften.** Hier
/// stand bis dahin `titleStatsProvider`, der drei Zahlen zusammensetzte
/// und sie an `package:identity` weiterreichte; dort wurde entschieden,
/// was verdient ist. Jetzt entscheidet das der Errungenschaftskatalog,
/// und `identity` kennt nur noch den Wortlaut.
///
/// Der Grund steht in `gotchas.md`: „30 Tage am Stück" hätte sonst an
/// zwei Stellen gestanden — als Titel und als Errungenschaft.
final earnedTitlesProvider = Provider<List<CharacterTitle>>((ref) {
  return TitleCatalog.forIds(ref.watch(earnedTitleIdsProvider));
});
