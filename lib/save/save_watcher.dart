import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/abilities_controller.dart';
import '../character/identity_controller.dart';
import '../dev/dev_controller.dart';
import '../gear/gear_controller.dart';
import '../habits/habits_controller.dart';
import '../theory/theory_controller.dart';
import 'save_data.dart';
import 'save_providers.dart';

/// Schreibt den Spielstand, sobald sich etwas daran ändert.
///
/// **Warum an einer Stelle und nicht in den Controllern.** Würde jeder
/// Controller selbst speichern, müsste jeder von ihnen den Speicher kennen,
/// und jeder neue Bereich brächte eine weitere Stelle mit, an der man das
/// Speichern vergessen kann. Hier gibt es genau eine — und wer einen
/// vierten Bereich hinzufügt, sieht in [build] sofort, wo er ihn eintragen
/// muss.
///
/// Der Preis dafür ist, dass dieses Widget im Baum hängen muss. Deshalb
/// sitzt es direkt unter dem `ProviderScope` in `main.dart`.
class SaveWatcher extends ConsumerWidget {
  const SaveWatcher({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sechs Bereiche, sechs Zeilen. Kommt ein siebter dazu, gehört er hier
    // dazu — sonst überlebt er keinen Neustart.
    ref.listen(theoryProgressProvider, (_, _) => _save(ref));
    ref.listen(habitTrackerProvider, (_, _) => _save(ref));
    ref.listen(loadoutProvider, (_, _) => _save(ref));
    ref.listen(identityProvider, (_, _) => _save(ref));
    ref.listen(chosenAbilitiesProvider, (_, _) => _save(ref));
    ref.listen(devGrantsProvider, (_, _) => _save(ref));

    return child;
  }

  void _save(WidgetRef ref) {
    final data = SaveData(
      theory: ref.read(theoryProgressProvider),
      habits: ref.read(habitTrackerProvider),
      loadout: ref.read(loadoutProvider),
      identity: ref.read(identityProvider),
      abilities: ref.read(chosenAbilitiesProvider),
      grants: ref.read(devGrantsProvider),
    );

    // Bewusst nicht abgewartet: Ein Häkchen soll sofort sichtbar sein und
    // nicht auf die Platte warten. Ein Fehler wird gemeldet, nicht
    // verschluckt — stillschweigend verlorener Fortschritt wäre das
    // Schlimmste, was diese Schicht anrichten kann.
    unawaited(
      ref.read(saveStoreProvider).write(data).catchError((Object error) {
        debugPrint('Spielstand konnte nicht gespeichert werden: $error');
      }),
    );
  }
}
