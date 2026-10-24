import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/abilities_screen.dart';
import '../gear/equipment_screen.dart';
import '../character/character_screen.dart';
import '../dev/dev_controller.dart';
import '../dev/dev_screen.dart';
import '../combat/ladder_screen.dart';
import '../gear/shop_screen.dart';
import '../habits/habits_controller.dart';
import '../habits/habits_screen.dart';
import '../progression/level_provider.dart';
import '../statistik/statistik_screen.dart';
import '../theory/skill_tree_screen.dart';
import '../ui/aufstieg.dart';
import '../ui/palette.dart';
import 'erster_start.dart';
import 'erster_start_provider.dart';
import 'widgets/erste_gewohnheit.dart';
import 'widgets/hub_circle.dart';
import 'widgets/status_leiste.dart';
import 'widgets/today_card.dart';
import '../ui/druck.dart';
import '../ui/holz.dart';
import '../lagerfeuer/am_feuer_provider.dart';
import '../lagerfeuer/lagerfeuer_screen.dart';
import '../lagerfeuer/widgets/lagerfeuer_karte.dart';
import '../mentor/mentor.dart';
import '../mentor/mentor_kasten.dart';
import '../mentor/zeigefinger.dart';
import '../haustier/widgets/haustier_karte.dart';
import '../haustier/haustier_controller.dart';
import '../skills/widgets/gebiet_frage_karte.dart';

/// Startbildschirm — „Heute“ in der Mitte, die Bereiche darum herum.
///
/// **Bis Issue #35 war das eine Liste aus fünf Kacheln.** Sie hat
/// funktioniert und nichts erzählt: Ein Habit-Tracker, dessen Startseite
/// aussieht wie ein Einstellungsmenü, muss seine eigene Aussage jeden Tag
/// aufs Neue behaupten. Seitdem liegen die Bereiche als Kreise um die
/// Mitte. Dort stand bis zum 28.09. der Charakter; jetzt steht dort, was
/// heute zu tun ist, und die Figur ist in der Ausrüstung.
///
/// **Die Kreise kommen nach und nach** (ADR-0068). Bis dahin standen
/// alle sieben vom ersten Start an da, der Kampf gesperrt; ein neuer
/// Spieler sah zwölf Systeme, bevor er eine Gewohnheit hatte. Jetzt
/// fragt die Seite zuerst nach einer, und jeder Bereich erscheint, wenn
/// es dort etwas zu tun gibt. Was als Nächstes dran ist, leuchtet. Wer
/// was sieht, rechnet [ErsterStart] aus dem Stand.
///
/// **Seit ADR-0079 sagt der Mentor dazu, was dran ist** — unten oder
/// oben in einem Kasten, gegenüber dem Kreis, auf den er zeigt.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _maxWidth = 560;

  /// Das Buch auf dem Theorie-Kreis — Frederiks Zeichnung, 64 × 64.
  static const String theorySymbol = 'assets/UI/Buch.png';

  /// Der Stern auf dem Fähigkeiten-Kreis (ADR-0049).
  ///
  /// **Eine vorhandene Zeichnung statt eines Systemzeichens**, wie das
  /// Buch auf der Theorie. Sternenfall ist die einzige legendäre
  /// Fähigkeit und die einzige, deren Bild mittig und ringsum gleich ist
  /// — auf einem runden Knopf sitzt das, ohne zu kippen.
  static const String abilitySymbol = 'assets/Faehigkeiten/Sternenfall.png';

  /// Der Harnisch auf dem Ausrüstungs-Kreis (ADR-0057), aus demselben
  /// Grund wie der Stern: eine vorhandene Zeichnung, mittig und
  /// symmetrisch, die auf den ersten Blick „Ausrüstung“ sagt.
  static const String gearSymbol = 'assets/Ruestung/Plattenharnisch.png';

  /// Wie gross die Kreise der unteren Reihe sind. **Kleiner als oben**,
  /// weil dort seit ADR-0057 vier stehen: Laden, Fähigkeiten,
  /// Ausrüstung, Charakter. Bei 72 Punkten bräuchten sie mit Namen 352
  /// Punkte Breite, ein Handy hat nach Rand und Holzrahmen 331.
  static const double bottomCircleSize = 64;

  /// Wie hoch die untere Reihe samt Namen, Rand und Holzrahmen steht —
  /// so viel lässt der Kasten des Mentors frei (ADR-0079).
  static const double untereReihe =
      bottomCircleSize + 20 + HubCircle.labelHeight + HolzGruppe.hoeheDazu;

  /// Dasselbe für die obere Reihe: Steht der Kasten oben, beginnt er
  /// unter dem Rahmen.
  static const double obereReihe =
      HubCircle.diameter + 20 + HubCircle.labelHeight + HolzGruppe.hoeheDazu;

  /// **Der Berg hinter der Startseite** (23.10.2026, Frederiks Bild).
  static const String hintergrund = 'assets/UI/Berg.jpg';

  /// Wie stark das Leder über dem Berg liegt — 0 der Berg in voller
  /// Farbe, 1 nur Leder. Eine Spur, damit Holz und Pergament davor
  /// stehen und nicht darin verschwimmen.
  static const double bergSchleier = 0.25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(effectiveXpProvider);
    final gold = ref.watch(goldProvider);

    final tracker = ref.watch(habitTrackerProvider);
    final today = ref.watch(todayProvider);
    final heute = HubProgress(
      done: tracker.completedOn(today),
      // Was heute fällig ist, nicht was läuft (ADR-0064).
      total: tracker.dailyListOn(today).length,
    );

    final start = ref.watch(ersterStartProvider);
    final hatTier = ref.watch(haustierProvider).art != null;
    final zeigtTier = hatTier && !start.fragtNachGewohnheit;

    // Ein Kreis an seinem Platz: versteckt, bis er dran ist.
    Widget kreis(Bereich bereich, Widget Function(bool leuchtet) bauen) {
      return Aufgedeckt(
        sichtbar: start.zeigt(bereich),
        child: bauen(start.leuchtet == bereich),
      );
    }

    return Scaffold(
      // Über „Heute" steigen die Zahlen eines Häkchens auf, wie auf dem
      // Gewohnheiten-Bildschirm (`AufstiegHost.maybeOf`).
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.background,
          image: DecorationImage(
            image: const AssetImage(hintergrund),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Palette.background.withValues(alpha: bergSchleier),
              BlendMode.srcATop,
            ),
          ),
        ),
        child: AufstiegHost(
          child: MentorFlaeche(
            ort: MentorOrt.start,
            obenFrei: obereReihe,
            untenFrei: untereReihe,
            // **Die Kreise rahmen den Bildschirm** (23.10.2026): oben und
            // unten je ein Holzrahmen, bündig am Rand; dazwischen Level,
            // Gold und „Heute“ vor dem Berg.
            child: Column(
              children: <Widget>[
                _Leiste(
                  oben: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      HubCircle(
                        icon: Icons.check_circle_outline,
                        label: 'Gewohnheiten',
                        image: HubCircleImage.plain,
                        progress: heute,
                        onTap: () => _open(context, const HabitsScreen()),
                      ),
                      kreis(
                        Bereich.theorie,
                        (leuchtet) => HubCircle(
                          icon: Icons.account_tree_outlined,
                          label: 'Theorie',
                          image: HubCircleImage.plain,
                          symbol: theorySymbol,
                          leuchtet: leuchtet,
                          onTap: () => _open(context, const SkillTreeScreen()),
                        ),
                      ),
                      // **Nie gesperrt** (ADR-0068): Stufe 1 ist mit der
                      // Waffe allein schlagbar, und wer zuerst kämpft,
                      // weiß danach, wofür er liest.
                      kreis(
                        Bereich.kampf,
                        (leuchtet) => HubCircle(
                          icon: Icons.sports_martial_arts,
                          label: 'Kampf',
                          image: HubCircleImage.plain,
                          leuchtet: leuchtet,
                          onTap: () => _open(context, const LadderScreen()),
                        ),
                      ),
                      // **Die Statistik** (ADR-0087) oben, neben dem, was
                      // sie zählt — mit dem ersten Häkchen.
                      kreis(
                        Bereich.statistik,
                        (_) => HubCircle(
                          icon: Icons.insights,
                          label: 'Statistik',
                          image: HubCircleImage.plain,
                          onTap: () => _open(context, const StatistikScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _maxWidth),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Column(
                            children: <Widget>[
                              // **Level und Gold oben rechts** (22.10.2026),
                              // der Ring um das Abzeichen ist der
                              // Erfahrungsbalken — seit dem 23.10. unter
                              // dem oberen Rahmen.
                              // **Das Haustier links daneben** (24.10.2026),
                              // ohne Rahmen — erst, wenn es geschlüpft ist.
                              StatusLeiste(
                                xp: xp,
                                gold: gold,
                                links: zeigtTier ? const HaustierKarte() : null,
                              ),
                              const SizedBox(height: 8),
                              // **Heute** (ADR-0053) bekommt, was übrig
                              // bleibt. Eine lange Liste rollt, statt
                              // überzulaufen. Darunter das **Lagerfeuer**
                              // (ADR-0076) mit Truhe, Tagesaufgaben und
                              // Rückfrage.
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      // **Einmal** (ADR-0085): Eigene Gewohnheiten
                                      // von vor den Skills fragen nach ihrem
                                      // Gebiet. Sonst steht hier nichts.
                                      if (tracker
                                          .customWithoutArea
                                          .isNotEmpty) ...<Widget>[
                                        const GebietFrageKarte(),
                                        const SizedBox(height: 10),
                                      ],
                                      // **Die Wahl des Eis** (ADR-0086) — über
                                      // „Heute“. Erst wenn es eine Gewohnheit
                                      // gibt: Vorher fragt die Startseite nach
                                      // ihr, und das Ei wartet. Ist es gewählt,
                                      // steht das Tier oben in der Leiste.
                                      if (!start.fragtNachGewohnheit &&
                                          !hatTier) ...<Widget>[
                                        const HaustierKarte(),
                                        const SizedBox(height: 10),
                                      ],
                                      // Ohne Gewohnheit ist „Heute“ die erste
                                      // Frage, keine leere Liste.
                                      if (start.fragtNachGewohnheit)
                                        const Zeigefinger(
                                          schritt: Schritt.gewohnheit,
                                          child: ErsteGewohnheitKarte(),
                                        )
                                      else
                                        const Zeigefinger(
                                          schritt: Schritt.abhaken,
                                          child: TodayCard(),
                                        ),
                                      // **Das Lagerfeuer** (ADR-0076) direkt darunter:
                                      // Truhe und Tagesaufgaben standen hier bis zum
                                      // 18.10. als zwei Karten, jetzt warten sie dort,
                                      // zusammen mit der Rückfrage.
                                      if (start.zeigtTagesaufgaben) ...<Widget>[
                                        const SizedBox(height: 10),
                                        LagerfeuerKarte(
                                          amFeuer: ref.watch(amFeuerProvider),
                                          onOpen: () => _open(
                                            context,
                                            const LagerfeuerScreen(),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _Leiste(
                  oben: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      kreis(
                        Bereich.laden,
                        (_) => HubCircle(
                          icon: Icons.storefront_outlined,
                          label: 'Laden',
                          image: HubCircleImage.plain,
                          size: bottomCircleSize,
                          onTap: () => _open(context, const ShopScreen()),
                        ),
                      ),
                      kreis(
                        Bereich.faehigkeiten,
                        (leuchtet) => HubCircle(
                          icon: Icons.auto_awesome,
                          label: 'Fähigkeiten',
                          image: HubCircleImage.plain,
                          size: bottomCircleSize,
                          symbol: abilitySymbol,
                          leuchtet: leuchtet,
                          onTap: () => _open(context, const AbilitiesScreen()),
                        ),
                      ),
                      kreis(
                        Bereich.ausruestung,
                        (_) => HubCircle(
                          icon: Icons.shield_outlined,
                          label: 'Ausrüstung',
                          image: HubCircleImage.plain,
                          size: bottomCircleSize,
                          symbol: gearSymbol,
                          onTap: () => _open(context, const EquipmentScreen()),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Nur im Debug-Build. Im Release ist der Zweig
                          // samt Bildschirm gar nicht erst im Bündel
                          // (ADR-0021), und an dieser Stelle steht dann
                          // nichts.
                          if (devModeAvailable) const _DevKnopf(),
                          kreis(
                            Bereich.charakter,
                            (_) => HubCircle(
                              icon: Icons.person_outline,
                              label: 'Charakter',
                              size: bottomCircleSize,
                              // Die einzige Flaeche, die ihr Zeichen
                              // selbst mitbringt.
                              image: HubCircleImage.character,
                              onTap: () =>
                                  _open(context, const CharacterScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

/// Ein Holzrahmen über die ganze Breite, **bündig** am oberen oder
/// unteren Rand (23.10.2026). Hinter Statusleiste und Gestenleiste des
/// Handys liegt nur Holz; die Kreise rücken davon weg ([SafeArea]).
class _Leiste extends StatelessWidget {
  const _Leiste({required this.oben, required this.child});

  final bool oben;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HolzGruppe(
      child: SafeArea(
        top: oben,
        bottom: !oben,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: HomeScreen._maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Ein Kreis, der erst erscheint, wenn er dran ist (ADR-0068).
///
/// **Der Platz bleibt frei, auch wenn nichts zu sehen ist.** Die Kreise
/// springen sonst bei jedem neuen um; so wächst jeder an seiner Stelle
/// heran. Solange er versteckt ist, nimmt er keinen Tipp an und steht
/// für den Vorleser nicht da.
class Aufgedeckt extends StatelessWidget {
  const Aufgedeckt({required this.sichtbar, required this.child, super.key});

  final bool sichtbar;
  final Widget child;

  static const Duration dauer = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !sichtbar,
      child: ExcludeSemantics(
        excluding: !sichtbar,
        child: AnimatedOpacity(
          opacity: sichtbar ? 1 : 0,
          duration: dauer,
          child: AnimatedScale(
            scale: sichtbar ? 1 : 0.6,
            duration: dauer,
            curve: Curves.easeOutBack,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Der kleine Knopf über dem Charakterkreis.
///
/// Er sitzt bewusst abseits der fünf Bereiche und ist kleiner als sie:
/// Der Entwicklermodus ist kein Teil des Spiels, sondern ein Werkzeug —
/// und er arbeitet auf einem eigenen Spielstand (ADR-0021).
class _DevKnopf extends ConsumerWidget {
  const _DevKnopf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 4),
      child: Tooltip(
        message: 'Entwicklermodus — ${ref.watch(activeSlotProvider).label}',
        child: Druck(
          child: InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const DevScreen())),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Palette.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Palette.muted),
              ),
              child: const Icon(
                Icons.science_outlined,
                size: 17,
                color: Palette.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
