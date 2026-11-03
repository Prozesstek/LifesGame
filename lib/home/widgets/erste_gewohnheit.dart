import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../../habits/habits_controller.dart';
import '../../skills/gebiet_farbe.dart';
import '../../skills/gebiet_zeichen.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// Ein Vorschlag für die erste Gewohnheit.
class ErsterVorschlag {
  const ErsterVorschlag(this.name, this.area, {this.vorlageId});

  final String name;

  /// Das Gebiet ihres Skills (ADR-0085) — und damit ihr Kampfwert
  /// (ADR-0088). Bei einer Vorlage dasselbe wie im Katalog.
  final SkillArea area;

  /// Gesetzt, wenn der Vorschlag eine Vorlage aus dem Katalog startet
  /// statt eine eigene Gewohnheit anzulegen.
  final String? vorlageId;
}

/// **Die erste Frage** — steht in „Heute“, solange es keine Gewohnheit
/// gibt (ADR-0068).
///
/// **Eine Karte, kein Dialog.** Ein Dialog beim Start läge über einer
/// Startseite, die noch nichts zeigt, und wer ihn wegtippt, stünde vor
/// der leeren Seite. Die Karte *ist* die Seite, bis sie beantwortet ist.
///
/// **Ohne eigene Überschrift** (Issue #183): Die Frage stellt der Mentor
/// darüber; dasselbe zweimal zu lesen wäre einmal zu viel.
///
/// **Ein Tipp genügt.** Ein Vorschlag legt sofort an; nur wer etwas
/// Eigenes schreibt, wählt dazu sein Gebiet — der Kampfwert folgt
/// daraus (ADR-0088). Wann, an welchen Tagen
/// und was es danach gibt, fragt später die Kachel (ADR-0052) — am
/// Anfang zählt das erste Häkchen, nicht das Formular.
///
/// **Erst spricht der Mentor, dann fliegen die Zeilen nacheinander
/// herein** (Issue #183) — einmal, beim Erscheinen.
class ErsteGewohnheitKarte extends ConsumerStatefulWidget {
  const ErsteGewohnheitKarte({super.key});

  static const Key feldKey = ValueKey<String>('erste-gewohnheit-feld');
  static const Key losKey = ValueKey<String>('erste-gewohnheit-los');

  /// Die Zeile „Etwas Eigenes“ — ein Tipp öffnet das Feld.
  static const Key eigenesKey = ValueKey<String>('erste-gewohnheit-eigenes');

  /// **Zwei Vorschläge und das Eigene** (Issue #183): je einer in einer
  /// Zeile, groß genug zum Lesen. „Freund anrufen“ ist weg.
  ///
  /// Der erste ist die Startvorlage (ADR-0052): Sie kostet keinen Platz
  /// für eine eigene Gewohnheit und bringt ihren Timer mit.
  static final List<ErsterVorschlag> vorschlaege = <ErsterVorschlag>[
    ErsterVorschlag(
      HabitCatalog.starter.name,
      HabitCatalog.starter.area,
      vorlageId: HabitCatalog.starterId,
    ),
    const ErsterVorschlag('Spazieren gehen', SkillArea.koerper),
  ];

  /// So lang wie im Formular einer eigenen Gewohnheit.
  static const int maxNameLength = 60;

  /// Wie lange der Mentor allein steht, bevor die erste Zeile kommt —
  /// so lang, wie sein Kasten zum Hereinschieben braucht.
  static const Duration warten = Duration(milliseconds: 320);

  /// Abstand zwischen zwei Zeilen.
  static const Duration abstand = Duration(milliseconds: 140);

  /// Wie lange eine Zeile fliegt.
  static const Duration flug = Duration(milliseconds: 380);

  /// Wie lange das Hereinfliegen insgesamt dauert — die Vorschläge und
  /// danach das Eigene.
  static Duration get einflug => warten + abstand * vorschlaege.length + flug;

  @override
  ConsumerState<ErsteGewohnheitKarte> createState() =>
      _ErsteGewohnheitKarteState();
}

class _ErsteGewohnheitKarteState extends ConsumerState<ErsteGewohnheitKarte>
    with SingleTickerProviderStateMixin {
  final TextEditingController _name = TextEditingController();
  SkillArea _area = SkillArea.koerper;
  bool _eigenesOffen = false;

  // In `initState` angelegt, nicht faul (`gotchas.md`).
  late final AnimationController _einflug;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _einflug = AnimationController(
      vsync: this,
      duration: ErsteGewohnheitKarte.einflug,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_einflug.isAnimating || _einflug.value > 0) return;
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (ruhig) {
      _einflug.value = 1;
    } else {
      _einflug.forward();
    }
  }

  @override
  void dispose() {
    _einflug.dispose();
    _name.dispose();
    super.dispose();
  }

  void _nimm(ErsterVorschlag vorschlag) {
    final habits = ref.read(habitTrackerProvider.notifier);
    final vorlage = vorschlag.vorlageId;
    if (vorlage != null) {
      habits.activate(vorlage);
      return;
    }
    _lege(vorschlag.name, vorschlag.area);
  }

  void _lege(String name, SkillArea area) {
    if (name.trim().isEmpty) return;
    final angelegt = ref
        .read(habitTrackerProvider.notifier)
        .addCustom(name: name, area: area, difficulty: HabitDifficulty.mittel);
    if (angelegt != null || !mounted) return;

    // Kann nur ein Stand treffen, der schon eigene Gewohnheiten hat und
    // trotzdem hier landet — dann lieber ein Satz als ein toter Knopf.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kein Platz für eine eigene Gewohnheit.')),
    );
  }

  /// Die [nr]-te Zeile, wie sie hereinfliegt: von unten, aufblendend.
  Widget _fliegt(int nr, Widget child) {
    final gesamt = ErsteGewohnheitKarte.einflug.inMicroseconds;
    final beginn =
        (ErsteGewohnheitKarte.warten + ErsteGewohnheitKarte.abstand * nr)
            .inMicroseconds /
        gesamt;
    final ende = beginn + ErsteGewohnheitKarte.flug.inMicroseconds / gesamt;
    final t = CurvedAnimation(
      parent: _einflug,
      curve: Interval(beginn, ende.clamp(0.0, 1.0), curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: t,
      builder: (context, kind) => Opacity(
        opacity: t.value.clamp(0.0, 1.0),
        child: FractionalTranslation(
          translation: Offset(0, 0.8 * (1 - t.value)),
          child: kind,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vorschlaege = ErsteGewohnheitKarte.vorschlaege;

    return HolzKarte(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (i, vorschlag) in vorschlaege.indexed) ...<Widget>[
            _fliegt(
              i,
              _VorschlagZeile(
                icon: gebietZeichen(vorschlag.area),
                farbe: GebietFarbe.pergament(vorschlag.area),
                name: vorschlag.name,
                semantik: '${vorschlag.name}, ${vorschlag.area.label}',
                onTap: () => _nimm(vorschlag),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _fliegt(
            vorschlaege.length,
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _eigenesOffen ? _eigenesFeld() : _eigenesZeile(),
            ),
          ),
        ],
      ),
    );
  }

  /// **„Etwas Eigenes“ sieht aus wie die Vorschläge** (Issue #183): eine
  /// Zeile mit grünem Plus, damit man sieht, dass sie sich antippen
  /// lässt. Erst der Tipp öffnet das Feld.
  Widget _eigenesZeile() {
    return _VorschlagZeile(
      key: ErsteGewohnheitKarte.eigenesKey,
      icon: Icons.edit_rounded,
      farbe: Palette.textDim,
      name: 'Etwas Eigenes',
      semantik: 'Etwas Eigenes',
      onTap: () => setState(() => _eigenesOffen = true),
    );
  }

  Widget _eigenesFeld() {
    final bereit = _name.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: ErsteGewohnheitKarte.feldKey,
          controller: _name,
          autofocus: true,
          maxLength: ErsteGewohnheitKarte.maxNameLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _lege(_name.text, _area),
          style: const TextStyle(fontSize: 18, color: Palette.text),
          decoration: InputDecoration(
            hintText: 'Wie heißt sie?',
            hintStyle: const TextStyle(fontSize: 18, color: Palette.muted),
            filled: true,
            fillColor: Palette.surfaceRaised,
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.edit_rounded, size: 24, color: Palette.textDim),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_VorschlagZeile.rund),
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        // Wohin das Eigene gehört, und der Knopf — erst wenn etwas im
        // Feld steht. Vorher wären es vier Zeichen ohne Bezug.
        if (bereit) ...<Widget>[
          const SizedBox(height: 8),
          // Nur das Gebiet (ADR-0085); was es im Kampf stärkt, folgt
          // daraus (ADR-0088) und erklärt der Mentor am Ende.
          Row(
            children: <Widget>[
              for (final area in SkillArea.values)
                _Wahl(
                  key: ValueKey<String>('erste-gewohnheit-${area.name}'),
                  icon: gebietZeichen(area),
                  farbe: GebietFarbe.pergament(area),
                  label: '${area.label}, stärkt ${area.kampfwert.label}',
                  gewaehlt: area == _area,
                  onTap: () => setState(() => _area = area),
                ),
              const Spacer(),
              // Grün wie die Plus-Zeichen darüber (Issue #183).
              IconButton(
                key: ErsteGewohnheitKarte.losKey,
                onPressed: () => _lege(_name.text, _area),
                iconSize: 40,
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: Palette.success,
                  semanticLabel: 'Anlegen',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Eine Zeile zum Antippen: das Zeichen links in seiner Farbe, der Name
/// groß, rechts das grüne Plus (Issue #183). Das Zeichen des Kampfwerts
/// steht hier nicht mehr — welcher Wert folgt, erklärt der Mentor am
/// Ende des Tutorials.
class _VorschlagZeile extends StatelessWidget {
  const _VorschlagZeile({
    required this.icon,
    required this.farbe,
    required this.name,
    required this.semantik,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color farbe;
  final String name;
  final String semantik;
  final VoidCallback onTap;

  static const double rund = 10;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantik,
      excludeSemantics: true,
      child: Druck(
        child: Material(
          color: Palette.surfaceRaised,
          borderRadius: BorderRadius.circular(rund),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(rund),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(rund),
                border: Border.all(color: farbe.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 24, color: farbe),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Palette.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.add_circle_rounded,
                    size: 28,
                    color: Palette.success,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ein Gebiet als Kreis zum Antippen.
class _Wahl extends StatelessWidget {
  const _Wahl({
    required this.label,
    required this.gewaehlt,
    required this.onTap,
    required this.icon,
    required this.farbe,
    super.key,
  });

  /// Nur für den Vorleser — zu sehen ist das Zeichen.
  final String label;
  final bool gewaehlt;
  final VoidCallback onTap;
  final IconData icon;

  /// Die Farbe des Gebiets (ADR-0090): das Zeichen immer, der Rand, wenn
  /// gewählt.
  final Color farbe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        selected: gewaehlt,
        label: label,
        excludeSemantics: true,
        child: Druck(
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gewaehlt ? Palette.surfaceRaised : null,
                border: Border.all(
                  color: gewaehlt ? farbe : Palette.muted,
                  width: gewaehlt ? 2 : 1,
                ),
              ),
              child: Icon(icon, size: 18, color: farbe),
            ),
          ),
        ),
      ),
    );
  }
}
