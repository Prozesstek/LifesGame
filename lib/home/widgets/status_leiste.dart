import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../ui/druck.dart';
import '../../ui/gold_icon.dart';
import '../../ui/holz.dart';
import '../../ui/level_abzeichen.dart';
import '../../ui/palette.dart';

/// Level, Fortschritt und Gold in einer Zeile auf der Startseite.
///
/// **Bis zum 28.09. stand hier eine Karte unter der Figur** (`LevelCard`),
/// mit „Level 12“, „340 Gold“ und einem Satz unter dem Balken. Die Figur
/// ist seitdem im Ausrüstungs-Bildschirm, und die Zahlen sind auf ihre
/// Zeichen geschrumpft: das Abzeichen für das Level, die Münze für das
/// Gold. „Heute“ bekommt den Platz.
///
/// **Der Satz unter dem Balken kommt nur auf Tipp.** Wie viel Erfahrung
/// bis zum nächsten Level fehlt, braucht man selten, und dann genügt ein
/// Tipp auf den Balken.
class StatusLeiste extends StatefulWidget {
  const StatusLeiste({required this.level, required this.gold, super.key});

  final PlayerLevel level;
  final int gold;

  @override
  State<StatusLeiste> createState() => _StatusLeisteState();
}

class _StatusLeisteState extends State<StatusLeiste> {
  bool _offen = false;

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              LevelAbzeichen(level: level.level),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Erfahrung bis zum nächsten Level',
                  child: Druck(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _offen = !_offen),
                      // Etwas Luft über und unter dem Balken, damit er
                      // sich treffen lässt; er selbst ist nur 12 hoch.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: HolzBalken(
                          value: level.ratio,
                          color: Palette.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const GoldIcon(),
              const SizedBox(width: 5),
              // Die Zahl schrumpft nicht, der Balken gibt nach — ein
              // Goldbetrag mit Auslassungspunkten wäre keine Zahl mehr.
              Text(
                '${widget.gold}',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Palette.gold,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.topCenter,
            child: _offen
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      level.isMaxLevel
                          ? 'Höchste Stufe erreicht'
                          : '${level.xpIntoLevel} von ${level.xpForLevel} '
                                'Erfahrung bis Level ${level.level + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Palette.textDim,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
