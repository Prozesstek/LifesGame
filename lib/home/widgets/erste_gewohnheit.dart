import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../../habits/habits_controller.dart';
import '../../skills/gebiet_farbe.dart';
import '../../skills/gebiet_zeichen.dart';
import '../../ui/der_reihe_nach.dart';
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
/// **Ein Tipp genügt.** Ein Vorschlag legt sofort an. Wer etwas
/// Eigenes schreibt, wird danach gefragt, zu welchem Gebiet es gehört
/// (06.11.2026): vier große Kacheln mit Namen, ein Tipp legt an; der
/// Kampfwert folgt daraus (ADR-0088). Bis dahin standen vier kleine
/// Kreise ohne Namen unter dem Feld, daneben ein Haken. Wann, an welchen Tagen
/// und was es danach gibt, fragt später die Kachel (ADR-0052) — am
/// Anfang zählt das erste Häkchen, nicht das Formular.
///
/// **Erst spricht der Mentor, dann fliegen die Zeilen nacheinander
/// herein** (Issue #183) — einmal, beim Erscheinen.
class ErsteGewohnheitKarte extends ConsumerStatefulWidget {
  const ErsteGewohnheitKarte({super.key});

  static const Key feldKey = ValueKey<String>('erste-gewohnheit-feld');

  /// „Weiter“ unter dem Namen — führt zur Frage nach dem Gebiet.
  static const Key weiterKey = ValueKey<String>('erste-gewohnheit-weiter');

  /// Zurück vom Namen zu den Vorschlägen.
  static const Key zurAuswahlKey = ValueKey<String>(
    'erste-gewohnheit-zur-auswahl',
  );

  /// Zurück von der Frage nach dem Gebiet zum Namen.
  static const Key zurueckKey = ValueKey<String>('erste-gewohnheit-zurueck');

  /// Die Kachel eines Gebiets; ein Tipp legt an.
  static Key gebietKey(SkillArea area) =>
      ValueKey<String>('erste-gewohnheit-${area.name}');

  /// Die Frage über den vier Gebieten — **in Alltagssprache** (06.11.2026):
  /// Am Anfang weiß niemand, was ein Gebiet im Spiel tut.
  /// Mit dem eigenen Namen darin: „Wobei hilft dir „Gitarre üben“?“.
  static String gebietFrageFuer(String name) => 'Wobei hilft dir „$name“?';

  /// Was unter jedem Gebiet steht: Dinge, die man kennt. Sie erklären das
  /// Gebiet nebenbei; was es im Kampf bringt, sagt der Mentor am Ende.
  static const Map<SkillArea, String> beispiele = <SkillArea, String>{
    SkillArea.koerper: 'Sport, Schlaf, Essen',
    SkillArea.geist: 'Lesen, Meditieren, Tagebuch',
    SkillArea.wissenschaft: 'Lernen, Sprachen, Forschen',
    SkillArea.gesellschaft: 'Freunde, Familie, Helfen',
  };

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
  static const Duration warten = DerReiheNach.mentor;

  /// Abstand zwischen zwei Zeilen.
  static const Duration abstand = DerReiheNach.abstand;

  /// Wie lange eine Zeile fliegt.
  static const Duration flug = DerReiheNach.flug;

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
  _Stufe _stufe = _Stufe.auswahl;

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
      curve: Interval(beginn, ende.clamp(0.0, 1.0), curve: Curves.easeOut),
    );
    // **Nur Deckkraft, kein Weg** (08.11.2026): Jede Zeile blendet an
    // ihrem Platz ein.
    return FadeTransition(opacity: t, child: child);
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
          // **Wer etwas Eigenes schreibt, sieht nur noch seine Frage**
          // (06.11.2026): Die Vorschläge klappen weg, bis er zurückgeht.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _stufe != _Stufe.auswahl
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final (i, vorschlag)
                          in vorschlaege.indexed) ...<Widget>[
                        _fliegt(
                          i,
                          _VorschlagZeile(
                            icon: gebietZeichen(vorschlag.area),
                            farbe: GebietFarbe.pergament(vorschlag.area),
                            name: vorschlag.name,
                            semantik:
                                '${vorschlag.name}, ${vorschlag.area.label}',
                            onTap: () => _nimm(vorschlag),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
          _fliegt(
            vorschlaege.length,
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: switch (_stufe) {
                _Stufe.auswahl => _eigenesZeile(),
                _Stufe.name => _eigenesFeld(),
                _Stufe.gebiet => _gebietFrage(),
              },
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
      onTap: () => setState(() => _stufe = _Stufe.name),
    );
  }

  /// Ein Pfeil zurück, ohne Wort (ADR-0060).
  Widget _zurueck({
    required Key key,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Druck(
        child: InkWell(
          key: key,
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 24,
              color: Palette.textDim,
            ),
          ),
        ),
      ),
    );
  }

  void _zumGebiet() {
    if (_name.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _stufe = _Stufe.gebiet);
  }

  Widget _eigenesFeld() {
    final bereit = _name.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Zurück zu den Vorschlägen; was im Feld steht, bleibt.
        Align(
          alignment: Alignment.centerLeft,
          child: _zurueck(
            key: ErsteGewohnheitKarte.zurAuswahlKey,
            label: 'Zurück zu den Vorschlägen',
            onTap: () => setState(() => _stufe = _Stufe.auswahl),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          key: ErsteGewohnheitKarte.feldKey,
          controller: _name,
          autofocus: true,
          maxLength: ErsteGewohnheitKarte.maxNameLength,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _zumGebiet(),
          style: const TextStyle(fontSize: 18, color: Palette.text),
          decoration: InputDecoration(
            // Ein Beispiel statt einer zweiten Frage: Gefragt hat der
            // Mentor schon („Was willst du jeden Tag tun?“).
            hintText: 'z. B. Gitarre üben',
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
        const SizedBox(height: 10),
        // Die Planke über das Theme, wie überall; grau, solange das Feld
        // leer ist.
        FilledButton(
          key: ErsteGewohnheitKarte.weiterKey,
          onPressed: bereit ? _zumGebiet : null,
          child: const Text('Weiter'),
        ),
      ],
    );
  }

  /// **Die Frage nach dem Gebiet** (06.11.2026): vier Kacheln mit
  /// Zeichen und Namen in ihrer Farbe (ADR-0090). Ein Tipp legt an — ein
  /// Knopf zum Bestätigen wäre ein Schritt ohne Entscheidung. Was das
  /// Gebiet im Kampf stärkt (ADR-0088), erklärt der Mentor am Ende.
  Widget _gebietFrage() {
    final name = _name.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            _zurueck(
              key: ErsteGewohnheitKarte.zurueckKey,
              label: 'Zurück zum Namen',
              onTap: () => setState(() => _stufe = _Stufe.name),
            ),
            const SizedBox(width: 6),
            // Ein Name darf 60 Zeichen haben: höchstens drei Zeilen, dann
            // Auslassung — die Kacheln darunter rücken nur nach unten.
            Expanded(
              child: Text(
                ErsteGewohnheitKarte.gebietFrageFuer(name),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Palette.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final reihe in <List<SkillArea>>[
          SkillArea.values.sublist(0, 2),
          SkillArea.values.sublist(2),
        ]) ...<Widget>[
          Row(
            children: <Widget>[
              for (final (i, area) in reihe.indexed) ...<Widget>[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _GebietKachel(
                    key: ErsteGewohnheitKarte.gebietKey(area),
                    area: area,
                    onTap: () => _lege(name, area),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Wo die Karte gerade steht.
enum _Stufe { auswahl, name, gebiet }

/// Ein Gebiet als große Kachel: Zeichen und Name in seiner Farbe.
class _GebietKachel extends StatelessWidget {
  const _GebietKachel({required this.area, required this.onTap, super.key});

  final SkillArea area;
  final VoidCallback onTap;

  /// Zwei Zeilen zu 12 Punkten bei Zeilenhöhe 1,3.
  static const double _beispielHoehe = 2 * 12 * 1.3;

  @override
  Widget build(BuildContext context) {
    final farbe = GebietFarbe.pergament(area);
    final beispiel = ErsteGewohnheitKarte.beispiele[area] ?? '';
    return Semantics(
      button: true,
      label: '${area.label}: $beispiel',
      excludeSemantics: true,
      child: Druck(
        child: Material(
          color: Palette.surfaceRaised,
          borderRadius: BorderRadius.circular(_VorschlagZeile.rund),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_VorschlagZeile.rund),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_VorschlagZeile.rund),
                border: Border.all(color: farbe, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(gebietZeichen(area), size: 32, color: farbe),
                  const SizedBox(height: 6),
                  Text(
                    area.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: farbe,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Immer Platz für zwei Zeilen, damit alle vier Kacheln
                  // gleich hoch sind, ob ein Beispiel umbricht oder nicht.
                  SizedBox(
                    height: _beispielHoehe,
                    child: Center(
                      child: Text(
                        beispiel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Palette.textDim,
                        ),
                      ),
                    ),
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
