import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wofür es einen Klang gibt. **Eine Tabelle, eine Stelle** — wie
/// `MoveIcons` für die Bilder: Welche Datei zu welchem Anlass gehört,
/// steht in [SoundEffect.asset] und sonst nirgends.
enum SoundEffect {
  // --- Das Häkchen ---
  //
  // **Die Tonleiter des Tages** (`tool/haekchen_klaenge.py`): Jedes
  // Häkchen eines Tages klingt eine Stufe höher als das davor, das letzte
  // Fällige löst den Akkord auf. Welche Stufe dran ist, sagt
  // `HaekchenMoment.klang`. Gerechnet, nicht aufgenommen — Platzhalter.

  /// Das erste Häkchen des Tages.
  ton1('Sound/Ton1.wav'),
  ton2('Sound/Ton2.wav'),
  ton3('Sound/Ton3.wav'),
  ton4('Sound/Ton4.wav'),

  /// Das fünfte — mehr Gewohnheiten laufen nicht
  /// (`HabitRewards.maxActiveHabits`).
  ton5('Sound/Ton5.wav'),

  /// Das letzte Fällige des Tages ist abgehakt.
  tagGeschafft('Sound/TagGeschafft.wav'),

  /// Das erste Häkchen des Tages zündet die Flamme der Tageskette. Liegt
  /// über dem Ton des Häkchens, deshalb ein Fauchen und kein Ton.
  kette('Sound/Kette.wav'),

  /// Ein Häkchen hat einen ganzen Charakterpunkt gebracht. Seltener als
  /// ein Häkchen, deshalb ein grösserer Klang. **Vorerst dieselbe Datei
  /// wie die Lektion** — es gibt keine weitere; tauschen ist diese Zeile.
  statPunkt('Sound/Win.mp3'),

  /// Eine Rückfrage ist richtig beantwortet. **Bis zum 18.10. auch der
  /// Klang jedes Häkchens**; der hat jetzt seine Leiter.
  richtig('Sound/Success.mp3'),

  /// Eine Antwort war falsch — auf einer Seite oder in der Rückfrage.
  /// Zwei weiche Schläge abwärts, die nicht strafen
  /// (`tool/lern_klaenge.py`). Eine richtige Antwort auf einer Seite
  /// klettert stattdessen die [tonleiter] hinauf (`AntwortKlang`).
  falsch('Sound/Falsch.wav'),

  /// Ein Blatt im Wissensbaum wird umgeschlagen — Papier raschelt und
  /// klappt (`tool/lern_klaenge.py`).
  blaettern('Sound/Blaettern.wav'),

  /// Eine Lektion ist bestanden.
  lektion('Sound/Win.mp3'),

  /// Ein Kampf ist gewonnen.
  sieg('Sound/Win_2.mp3'),

  /// Eine Errungenschaft ist verdient — der seltenste Moment, deshalb
  /// der längste Klang.
  errungenschaft('Sound/Win_3.mp3'),

  /// Die Beute des Wächters springt auf (ADR-0048). **Vorerst dieselbe
  /// Datei wie die Lektion**; ab Selten klingt stattdessen die
  /// Errungenschaft.
  beute('Sound/Win.mp3'),

  // --- Die Grube ---
  //
  // Diese fünf sind **gerechnet, nicht aufgenommen**
  // (`tool/kampf_klaenge.py`) — Platzhalter, die dem Projekt gehören.
  // Wann welcher fällt, steht in `ActionGame`; wie dicht sie aufeinander
  // folgen dürfen, in `KampfKlang`.

  /// Der Held trifft einen Gegner. Der häufigste Klang der Grube,
  /// deshalb der kürzeste und leiseste.
  treffer('Sound/Treffer.wav'),

  /// Der Held wird getroffen.
  getroffen('Sound/Getroffen.wav'),

  /// Ein Gegner fällt.
  gefallen('Sound/Gefallen.wav'),

  /// Eine Fähigkeit aus einem Platz wird gewirkt.
  faehigkeit('Sound/Faehigkeit.wav'),

  /// Der Wächter oder ein Wächterauge kündigt einen Angriff an.
  ankuendigung('Sound/Ankuendigung.wav'),

  // Seit dem Goldregen: was beim Helden ankommt (`BeuteRegen`).

  /// Eine Münze kommt beim Helden an. Im Brunnen des Wächters dutzendfach
  /// — `KampfKlang` hält sie auseinander, so wird es ein Rasseln.
  muenze('Sound/Muenze.wav'),

  /// Ein Funke Erfahrung kommt an. Leiser als die Münze.
  funke('Sound/Funke.wav'),

  /// Ein Level mitten im Lauf.
  aufstieg('Sound/Aufstieg.wav'),

  // Seit der Beute in der Grube (ADR-0083).

  /// Der Held sammelt einen Fund ein.
  fund('Sound/Fund.wav'),

  /// Etwas Legendäres fällt — der einzige lange Klang der Grube.
  legendaer('Sound/Legendaer.wav');

  const SoundEffect(this.asset);

  /// Die Leiter von unten nach oben.
  static const List<SoundEffect> tonleiter = <SoundEffect>[
    ton1,
    ton2,
    ton3,
    ton4,
    ton5,
  ];

  /// Pfad unter `assets/`, so wie `AssetSource` ihn erwartet.
  final String asset;
}

/// Spielt Klänge ab — oder eben nicht.
abstract interface class SoundPlayer {
  void play(SoundEffect effect);
}

/// Spielt nichts. **Der Standard**, damit Tests und jeder Aufbau ohne
/// `main.dart` still bleiben: Ein echter Player ruft einen Plattformkanal,
/// den es im Widget-Test nicht gibt.
class SilentSoundPlayer implements SoundPlayer {
  const SilentSoundPlayer();

  @override
  void play(SoundEffect effect) {}
}

/// Spielt die Dateien aus `assets/Sound/`.
///
/// **Ein Player je Klang.** Mit einem gemeinsamen schnitte ein Häkchen
/// die Fanfare einer Errungenschaft ab, die im selben Augenblick kommt.
class AssetSoundPlayer implements SoundPlayer {
  final Map<SoundEffect, AudioPlayer> _players = <SoundEffect, AudioPlayer>{};

  @override
  void play(SoundEffect effect) {
    final player = _players.putIfAbsent(effect, AudioPlayer.new);
    // **Ein fehlender Klang hält nichts auf.** Das Spiel funktioniert
    // ohne Ton vollständig; ein Fehler beim Abspielen wird gemeldet,
    // aber nie bis zum Bildschirm durchgereicht.
    unawaited(
      player
          .play(AssetSource(effect.asset))
          .catchError(
            (Object fehler) => debugPrint('Klang ${effect.name}: $fehler'),
          ),
    );
  }
}

/// Der Anschluss. In `main.dart` wird er durch [AssetSoundPlayer] ersetzt.
final soundPlayerProvider = Provider<SoundPlayer>(
  (ref) => const SilentSoundPlayer(),
);
