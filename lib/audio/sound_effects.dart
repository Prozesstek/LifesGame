import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wofür es einen Klang gibt. **Eine Tabelle, eine Stelle** — wie
/// `MoveIcons` für die Bilder: Welche Datei zu welchem Anlass gehört,
/// steht in [SoundEffect.asset] und sonst nirgends.
enum SoundEffect {
  /// Ein Häkchen ist gesetzt — der häufigste Moment des Spiels, deshalb
  /// der kürzeste Klang.
  haekchen('Sound/Success.mp3'),

  /// Ein Häkchen hat einen ganzen Charakterpunkt gebracht. Seltener als
  /// ein Häkchen, deshalb ein grösserer Klang. **Vorerst dieselbe Datei
  /// wie die Lektion** — es gibt keine weitere; tauschen ist diese Zeile.
  statPunkt('Sound/Win.mp3'),

  /// Eine Lektion ist bestanden.
  lektion('Sound/Win.mp3'),

  /// Ein Kampf ist gewonnen.
  sieg('Sound/Win_2.mp3'),

  /// Eine Errungenschaft ist verdient — der seltenste Moment, deshalb
  /// der längste Klang.
  errungenschaft('Sound/Win_3.mp3');

  const SoundEffect(this.asset);

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
