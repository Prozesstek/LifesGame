import 'dart:math' as math;

import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:identity/identity.dart';

import '../achievements/achievements_controller.dart';
import '../achievements/achievements_screen.dart';
import '../character/character_screen.dart';
import '../gear/gear_controller.dart';
import '../gear/gear_icon.dart';
import '../habits/habits_controller.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'village_game.dart';
import 'village_map.dart';
import 'village_screen.dart';

/// Was das Haus zeigt — **abgeleitet**, nie gespeichert. Das Haus ist der
/// Ort, an dem man sieht, was man erreicht hat; die Zahlen dafür gibt es
/// alle schon.
class HouseView {
  const HouseView({
    required this.trophies,
    required this.trophyTotal,
    required this.titles,
    required this.titleTotal,
    required this.gearIcons,
    required this.chestsOpened,
    required this.chestGold,
    required this.treasures,
    required this.freezesFound,
  });

  /// Verdiente Errungenschaften — ein Pokal je Stück.
  final int trophies;
  final int trophyTotal;

  /// Die verdienten Titel, ein Banner je Titel.
  final List<String> titles;
  final int titleTotal;

  /// Die Bilder dessen, was am Ständer hängt: Waffe, Rüstung, Helm.
  final List<String> gearIcons;

  final int chestsOpened;
  final int chestGold;
  final int treasures;
  final int freezesFound;

  /// Welche Plätze der Ständer zeigt, in dieser Reihenfolge.
  static const List<GearSlot> standSlots = <GearSlot>[
    GearSlot.helm,
    GearSlot.ruestung,
    GearSlot.waffe,
  ];

  factory HouseView.from({
    required Set<String> earnedAchievements,
    required Set<String> earnedTitles,
    required Loadout loadout,
    required HabitTracker habits,
  }) {
    var schaetze = 0;
    for (final tag in habits.openedChests) {
      if (DailyChest.forDay(tag).tier == ChestTier.schatz) schaetze++;
    }
    return HouseView(
      trophies: earnedAchievements.length,
      trophyTotal: AchievementCatalog.all.length,
      titles: <String>[
        for (final t in TitleCatalog.forIds(earnedTitles)) t.label,
      ],
      titleTotal: TitleCatalog.all.length,
      gearIcons: <String>[
        for (final slot in standSlots)
          if (loadout.equippedIn(slot) case final item?)
            ?GearIcons.forItemId(item.id),
      ],
      chestsOpened: habits.openedChests.length,
      chestGold: habits.chestGold,
      treasures: schaetze,
      freezesFound: habits.chestFreezes,
    );
  }
}

final houseViewProvider = Provider<HouseView>((ref) {
  return HouseView.from(
    earnedAchievements: ref.watch(earnedAchievementIdsProvider),
    earnedTitles: ref.watch(earnedTitleIdsProvider),
    loadout: ref.watch(loadoutProvider),
    habits: ref.watch(habitTrackerProvider),
  );
});

/// **Das eigene Haus** — ein Raum, in dem man sieht, was man erreicht hat:
/// Pokale im Regal, Titel an der Wand, die Ausrüstung am Ständer, Gold
/// neben der Truhe. Alles wächst mit, ohne dass jemand es einräumt.
class HouseScreen extends ConsumerWidget {
  const HouseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ansicht = ref.watch(houseViewProvider);
    return WalkScreen(
      scene: VillageScene.haus,
      decorate: (spiel, canvas, ort, flaeche) =>
          paintHouse(spiel, canvas, ort, flaeche, ansicht),
      onEnter: (context, ort) async {
        switch (ort) {
          case VillagePlace.ausgang:
            Navigator.of(context).pop();
          case VillagePlace.trophaeen:
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AchievementsScreen(),
              ),
            );
          case VillagePlace.ruestung:
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CharacterScreen()),
            );
          case VillagePlace.titelwand:
            await _zeige(context, _Titel(ansicht: ansicht));
          case VillagePlace.truhe:
            await _zeige(context, _Schaetze(ansicht: ansicht));
          case _:
            break;
        }
      },
    );
  }

  static Future<void> _zeige(BuildContext context, Widget blatt) {
    return showDialog<void>(
      context: context,
      builder: (_) => HolzDialog(child: blatt),
    );
  }
}

/// Zeichnet, was in den Dingen des Hauses liegt.
void paintHouse(
  VillageGame spiel,
  Canvas canvas,
  VillagePlace ort,
  Rect flaeche,
  HouseView ansicht,
) {
  const t = VillageMap.tileSize;
  // Die Gegenstände stehen in der oberen Reihe ihrer Fläche; die untere
  // ist der Platz davor.
  final oben = Rect.fromLTWH(
    flaeche.left,
    flaeche.top,
    flaeche.width,
    flaeche.height - t,
  );
  switch (ort) {
    case VillagePlace.trophaeen:
      _pokale(canvas, oben, ansicht.trophies);
      _zahl(canvas, oben, '${ansicht.trophies}/${ansicht.trophyTotal}');
    case VillagePlace.titelwand:
      _banner(canvas, oben, ansicht.titles.length);
      _zahl(canvas, oben, '${ansicht.titles.length}/${ansicht.titleTotal}');
    case VillagePlace.ruestung:
      _staender(spiel, canvas, oben, ansicht.gearIcons);
    case VillagePlace.truhe:
      _gold(canvas, oben, ansicht.chestGold, ansicht.treasures > 0);
    case _:
      break;
  }
}

const Color _goldFarbe = Color(0xFFE0B03C);
const Color _goldDunkel = Color(0xFFA67A1E);
const Color _kontur = Color(0xFF281A0E);

/// Ein Pokal je Errungenschaft, auf dem Brett — so viele, wie passen, der
/// Rest als Zahl.
void _pokale(Canvas canvas, Rect brett, int anzahl) {
  const breite = 13.0;
  final platz = (brett.width / breite).floor();
  final gezeigt = math.min(anzahl, platz);
  final fuss = brett.top + 21;
  for (var i = 0; i < gezeigt; i++) {
    final x = brett.left + 3 + i * breite;
    final gold = Paint()..color = i.isEven ? _goldFarbe : _goldDunkel;
    final pfad = Path()
      ..moveTo(x, fuss - 14)
      ..lineTo(x + 9, fuss - 14)
      ..lineTo(x + 7, fuss - 7)
      ..lineTo(x + 2, fuss - 7)
      ..close();
    canvas.drawPath(pfad, gold);
    canvas.drawRect(Rect.fromLTWH(x + 3.5, fuss - 7, 2, 4), gold);
    canvas.drawRect(Rect.fromLTWH(x + 1.5, fuss - 3, 6, 2), gold);
    canvas.drawPath(
      pfad,
      Paint()
        ..color = _kontur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// Ein Banner je Titel, an der Leiste.
void _banner(Canvas canvas, Rect leiste, int anzahl) {
  const farben = <Color>[
    Color(0xFF9E3E30),
    Color(0xFF465890),
    Color(0xFF3F7A3A),
    Color(0xFF7A4E9E),
    Color(0xFFB07A2A),
  ];
  const breite = 16.0;
  final platz = (leiste.width / breite).floor();
  for (var i = 0; i < math.min(anzahl, platz); i++) {
    final x = leiste.left + 4 + i * breite;
    final y = leiste.top + 8;
    final pfad = Path()
      ..moveTo(x, y)
      ..lineTo(x + 11, y)
      ..lineTo(x + 11, y + 18)
      ..lineTo(x + 5.5, y + 14)
      ..lineTo(x, y + 18)
      ..close();
    canvas.drawPath(pfad, Paint()..color = farben[i % farben.length]);
    canvas.drawPath(
      pfad,
      Paint()
        ..color = _kontur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(Offset(x + 5.5, y + 7), 2, Paint()..color = _goldFarbe);
  }
}

/// Die angelegte Ausrüstung am Ständer, von oben nach unten.
void _staender(
  VillageGame spiel,
  Canvas canvas,
  Rect staender,
  List<String> bilder,
) {
  const seite = 22.0;
  for (var i = 0; i < bilder.length; i++) {
    final bild = spiel.image(bilder[i]);
    if (bild == null) continue;
    final ziel = Rect.fromCenter(
      center: Offset(staender.center.dx, staender.top + 12 + i * 17),
      width: seite,
      height: seite,
    );
    VillageGame.drawImage(canvas, bild, ziel);
  }
}

/// Ein Goldhaufen neben der Truhe, der mit dem Gold aus Tagestruhen
/// wächst; ein Schatz funkelt.
void _gold(Canvas canvas, Rect truhe, int gold, bool schatz) {
  if (gold <= 0) return;
  // Wurzel, damit der Haufen früh sichtbar wird und spät nicht platzt.
  final muenzen = math.min(18, math.sqrt(gold).ceil());
  final boden = truhe.bottom - 1;
  final gelb = Paint()..color = _goldFarbe;
  final dunkel = Paint()..color = _goldDunkel;
  for (var i = 0; i < muenzen; i++) {
    final reihe = (math.sqrt(i * 2)).floor();
    final x = truhe.left - 6 + (i * 5) % 16 + reihe;
    final y = boden - reihe * 3;
    canvas.drawOval(Rect.fromLTWH(x, y - 3, 7, 3.5), i.isEven ? gelb : dunkel);
  }
  if (schatz) {
    final funkeln = Paint()
      ..color = const Color(0xFFFFF4C0)
      ..strokeWidth = 1.5;
    final m = Offset(truhe.right - 2, truhe.top + 2);
    canvas.drawLine(m.translate(-4, 0), m.translate(4, 0), funkeln);
    canvas.drawLine(m.translate(0, -4), m.translate(0, 4), funkeln);
  }
}

/// Eine kleine Zahl unter dem Gegenstand: wie viel davon es schon gibt.
void _zahl(Canvas canvas, Rect ding, String text) {
  final maler = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Palette.textOnDark,
        shadows: <Shadow>[Shadow(color: Color(0xDD1A0E05), blurRadius: 2)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  maler.paint(
    canvas,
    Offset(ding.right - maler.width - 2, ding.bottom - maler.height + 12),
  );
}

class _Titel extends StatelessWidget {
  const _Titel({required this.ansicht});

  final HouseView ansicht;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surface,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      title: Text('Titel · ${ansicht.titles.length} von ${ansicht.titleTotal}'),
      content: ansicht.titles.isEmpty
          ? const Text(
              'Noch kein Titel. Titel kommen aus Errungenschaften — die '
              'Wand wartet.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final titel in ansicht.titles)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.flag, size: 18, color: Palette.accent),
                        const SizedBox(width: 8),
                        Flexible(child: Text(titel)),
                      ],
                    ),
                  ),
              ],
            ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schön'),
        ),
      ],
    );
  }
}

class _Schaetze extends StatelessWidget {
  const _Schaetze({required this.ansicht});

  final HouseView ansicht;

  @override
  Widget build(BuildContext context) {
    final a = ansicht;
    final zeilen = <(IconData, String)>[
      (Icons.inventory_2, '${a.chestsOpened} Tagestruhen geöffnet'),
      (Icons.monetization_on, '${a.chestGold} Gold daraus'),
      if (a.treasures > 0)
        (
          Icons.auto_awesome,
          a.treasures == 1 ? 'Ein Schatz!' : '${a.treasures} Schätze!',
        ),
      if (a.freezesFound > 0)
        (Icons.ac_unit, '${a.freezesFound} Streak-Eis gefunden'),
    ];
    return AlertDialog(
      backgroundColor: Palette.surface,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      title: const Text('Deine Schätze'),
      content: a.chestsOpened == 0
          ? const Text(
              'Noch leer. Jeder Tag, an dem alles erledigt ist, bringt eine '
              'Tagestruhe — ihr Gold landet hier.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final (zeichen, text) in zeilen)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: <Widget>[
                        Icon(zeichen, size: 18, color: Palette.gold),
                        const SizedBox(width: 8),
                        Flexible(child: Text(text)),
                      ],
                    ),
                  ),
              ],
            ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schön'),
        ),
      ],
    );
  }
}
