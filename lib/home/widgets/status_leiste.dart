import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../ui/aufstieg.dart';
import '../../ui/beute_flug.dart';
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
///
/// **Sie zeigt, was angekommen ist** (18.10.). Ein Häkchen wirft Münzen
/// zur Goldzahl und Funken zum Balken (`BeuteFlug`); was noch fliegt,
/// zieht sie ab, und so steigen Zahl und Balken mit jedem Stück, das
/// ankommt. Deshalb nimmt sie die Erfahrung und schlägt das Level selbst
/// nach — wie `playerLevelProvider`, nur ohne das, was noch unterwegs ist.
class StatusLeiste extends StatefulWidget {
  const StatusLeiste({required this.xp, required this.gold, super.key});

  /// Die ganze Erfahrung, wie `effectiveXpProvider` sie nennt.
  final int xp;
  final int gold;

  @override
  State<StatusLeiste> createState() => _StatusLeisteState();
}

class _StatusLeisteState extends State<StatusLeiste> {
  bool _offen = false;

  @override
  Widget build(BuildContext context) {
    final host = AufstiegHost.maybeOf(context);
    if (host == null) {
      return _leiste(LevelCurve.levelFor(widget.xp), widget.gold);
    }
    final gold = host.unterwegs(FlugZiel.gold);
    final xp = host.unterwegs(FlugZiel.erfahrung);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[gold, xp]),
      builder: (context, _) => _leiste(
        LevelCurve.levelFor(widget.xp - xp.value),
        widget.gold - gold.value,
      ),
    );
  }

  Widget _leiste(PlayerLevel level, int gold) {
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
                        // Ein breiter Balken springt kaum — ein Hauch
                        // reicht, damit man das Ankommen sieht.
                        child: FlugZielMarke(
                          ziel: FlugZiel.erfahrung,
                          staerke: 0.04,
                          child: HolzBalken(
                            value: level.ratio,
                            color: Palette.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FlugZielMarke(
                ziel: FlugZiel.gold,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const GoldIcon(),
                    const SizedBox(width: 5),
                    // Die Zahl schrumpft nicht, der Balken gibt nach —
                    // ein Goldbetrag mit Auslassungspunkten wäre keine
                    // Zahl mehr.
                    Text(
                      '$gold',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Palette.gold,
                      ),
                    ),
                  ],
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
