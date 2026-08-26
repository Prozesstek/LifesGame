import 'package:combat/combat.dart';
import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Zeigt die Umgebung, die gerade auf dem Feld liegt.
///
/// **Warum es das braucht.** Statuseffekte hatten schon immer Chips mit
/// Restrunden am jeweiligen Kämpfer. Die Umgebung hatte nichts davon: Sie
/// stand einmal als Logzeile im Bild („Giftboden — 4 Runden") und war zwei
/// Zeilen später nicht mehr auffindbar. Eine Umgebung, die vier Runden
/// lang die eigene Heilung halbiert, muss ablesbar sein, solange sie wirkt.
///
/// **Reine Anzeige.** Was eine Umgebung tut, steht in `package:combat`;
/// hier wird nur gelesen, was dort liegt (ADR-0002).
class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({required this.environment, super.key});

  /// Die liegende Umgebung, oder `null` wenn keine liegt.
  final Environment? environment;

  /// Höhe des Bandes, wenn es steht. Draußen bekannt, damit die Kampffläche
  /// nicht springt, sobald eine Umgebung gelegt wird.
  static const double height = 26;

  @override
  Widget build(BuildContext context) {
    final active = environment;
    if (active == null) return const SizedBox(height: height);

    // Wem sie nützt, entscheidet die Logik über `owner` — hier wird das
    // nur eingefärbt.
    final mine = active.owner == Side.player;
    final accent = mine ? Palette.accent : Palette.enemy;

    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Palette.surfaceRaised,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: accent.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              // Beide Texte dürfen schrumpfen: Zwei Texte nebeneinander in
              // einer Row brauchen das, sonst bricht die Zeile bei großer
              // Schrift (siehe `docs/context/gotchas.md`).
              Flexible(
                child: Text(
                  active.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _restText(active.remainingTurns),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Palette.textDim),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _restText(int turns) {
    return turns == 1 ? 'noch 1 Runde' : 'noch $turns Runden';
  }
}
