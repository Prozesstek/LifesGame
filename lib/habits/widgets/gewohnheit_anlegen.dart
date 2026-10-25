import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../skills/gebiet_zeichen.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../stat_icon.dart';
import 'anlegen_ergebnis.dart';
import 'anlegen_teile.dart';
import 'cue_dialog.dart';
import 'weekday_picker.dart';

export 'anlegen_ergebnis.dart';

enum _Schritt { art, name, gebiet, grad, ziel, wann, tage, danach }

/// **Eine neue Gewohnheit, eine Frage nach der anderen** (ADR-0089).
///
/// Bis dahin stand alles auf einem Blatt — Name, Wert, Gebiet,
/// Schwierigkeit, Ziel, Priorität, Warum —, und danach kam ein Dialog mit
/// Auslöser, Kopplung, Wochentagen und Belohnung. Jetzt fragt jedes Blatt
/// eine Sache; eine Wahl führt mit einem Tipp weiter, ein Feld mit
/// „Weiter“. Was bei einer Vorlage schon feststeht, wird nicht gefragt.
///
/// **Weg sind „Warum?“ und „Wie wichtig?“**: Das eine wurde nirgends
/// angezeigt, das andere sortierte nur die Liste, die längst nach
/// Offenem, Stapeln und „Morgen zuerst“ sortiert. Und **der Kampfwert**:
/// Den bestimmt das Gebiet (ADR-0088).
class GewohnheitAnlegen extends StatefulWidget {
  const GewohnheitAnlegen({
    required this.vorlagen,
    required this.ruhende,
    required this.eigeneFrei,
    required this.listeVoll,
    required this.ankerFuer,
    required this.hatAusloeser,
    required this.tageFuer,
    super.key,
  });

  static const Key eigeneKey = ValueKey<String>('anlegen-eigene');
  static const Key vorlageKey = ValueKey<String>('anlegen-vorlage');
  static const Key weiterKey = ValueKey<String>('anlegen-weiter');
  static const Key ohneKey = ValueKey<String>('anlegen-ohne');
  static const Key zurueckKey = AnlegenKopf.zurueckKey;
  static const Key nameKey = ValueKey<String>('anlegen-name');
  static const Key mengeKey = ValueKey<String>('anlegen-menge');
  static const Key minutenKey = ValueKey<String>('anlegen-minuten');

  static Key vorlageEintrag(String habitId) {
    return ValueKey<String>('anlegen-vorlage-$habitId');
  }

  static Key gebietKey(SkillArea area) {
    return ValueKey<String>('anlegen-gebiet-${area.name}');
  }

  static Key gradKey(HabitDifficulty grad) {
    return ValueKey<String>('anlegen-grad-${grad.name}');
  }

  static Key zielKey(ZielArt ziel) =>
      ValueKey<String>('anlegen-ziel-${ziel.name}');

  /// Freigeschaltete Vorlagen, die gerade nicht laufen.
  final List<HabitTemplate> vorlagen;

  /// Eigene, die gerade nicht laufen.
  final List<CustomHabit> ruhende;

  /// Wie viele eigene sich noch anlegen lassen.
  final int eigeneFrei;

  /// Ob die Tagesliste voll ist. Eine eigene lässt sich dann trotzdem
  /// anlegen — sie wartet unter „Deine“.
  final bool listeVoll;

  /// Woran sich koppeln lässt; null fragt für eine, die es noch nicht
  /// gibt.
  final List<Habit> Function(String? habitId) ankerFuer;

  /// Ob eine pausierte schon einen Auslöser oder Anker hat — dann wird
  /// nicht noch einmal gefragt.
  final bool Function(String habitId) hatAusloeser;

  /// Welche Tage eine pausierte zuletzt hatte.
  final Set<int> Function(String habitId) tageFuer;

  /// Öffnet das Blatt. Null, wenn abgebrochen wurde.
  static Future<Angelegt?> show(
    BuildContext context, {
    required List<HabitTemplate> vorlagen,
    required List<CustomHabit> ruhende,
    required int eigeneFrei,
    required bool listeVoll,
    required List<Habit> Function(String? habitId) ankerFuer,
    required bool Function(String habitId) hatAusloeser,
    required Set<int> Function(String habitId) tageFuer,
  }) {
    return showModalBottomSheet<Angelegt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => HolzBlatt(
        child: GewohnheitAnlegen(
          vorlagen: vorlagen,
          ruhende: ruhende,
          eigeneFrei: eigeneFrei,
          listeVoll: listeVoll,
          ankerFuer: ankerFuer,
          hatAusloeser: hatAusloeser,
          tageFuer: tageFuer,
        ),
      ),
    );
  }

  @override
  State<GewohnheitAnlegen> createState() => _GewohnheitAnlegenState();
}

class _GewohnheitAnlegenState extends State<GewohnheitAnlegen> {
  final _name = TextEditingController();
  final _menge = TextEditingController(text: '5');
  final _einheit = TextEditingController(text: 'Mal');
  final _minuten = TextEditingController(text: '10');
  final _ausloeser = TextEditingController();
  final _belohnung = TextEditingController();

  _Schritt _schritt = _Schritt.art;
  bool _vorlagenOffen = false;
  String? _hinweis;

  /// Die gewählte Vorlage oder pausierte eigene — null für eine neue.
  Habit? _vorlage;

  SkillArea? _gebiet;
  HabitDifficulty _grad = HabitDifficulty.mittel;
  ZielArt? _ziel;
  Set<int> _tage = <int>{...Wochentage.alle};
  String? _anker;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    // Satz oder Anker: Wer tippt, löst die Kopplung.
    _ausloeser.addListener(() {
      if (_anker != null && _ausloeser.text.isNotEmpty) {
        setState(() => _anker = null);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _menge.dispose();
    _einheit.dispose();
    _minuten.dispose();
    _ausloeser.dispose();
    _belohnung.dispose();
    super.dispose();
  }

  /// Die Blätter, die dieser Weg hat — er ändert sich mit der ersten
  /// Wahl.
  List<_Schritt> get _weg {
    if (_vorlage case final vorlage?) {
      return <_Schritt>[
        _Schritt.art,
        if (!widget.hatAusloeser(vorlage.id)) ..._einrichten,
      ];
    }
    return <_Schritt>[
      _Schritt.art,
      _Schritt.name,
      _Schritt.gebiet,
      _Schritt.grad,
      _Schritt.ziel,
      if (!widget.listeVoll) ..._einrichten,
    ];
  }

  static const List<_Schritt> _einrichten = <_Schritt>[
    _Schritt.wann,
    _Schritt.tage,
    _Schritt.danach,
  ];

  bool get _istLetzter => _weg.last == _schritt;

  void _weiter() {
    final weg = _weg;
    final i = weg.indexOf(_schritt);
    if (i + 1 >= weg.length) {
      _fertig();
      return;
    }
    setState(() {
      _schritt = weg[i + 1];
      _hinweis = null;
    });
  }

  void _zurueck() {
    final weg = _weg;
    final i = weg.indexOf(_schritt);
    if (i <= 0) return;
    setState(() {
      _schritt = weg[i - 1];
      _hinweis = null;
    });
  }

  HabitGoal? get _goal {
    return switch (_ziel) {
      null || ZielArt.keins => null,
      ZielArt.menge => HabitGoal.menge(
        target: int.tryParse(_menge.text.trim()) ?? 1,
        unit: _einheit.text,
      ),
      ZielArt.zeit => HabitGoal.zeit(
        target: int.tryParse(_minuten.text.trim()) ?? 1,
      ),
    };
  }

  void _fertig() {
    final einrichtung = _weg.contains(_Schritt.wann)
        ? Einrichtung(
            weekdays: _tage,
            cue: _anker == null ? _ausloeser.text.trim() : '',
            anchorId: _anker,
            treat: _belohnung.text.trim(),
          )
        : null;
    Navigator.of(context).pop(switch (_vorlage) {
      final Habit vorlage => VorlageGestartet(
        vorlage.id,
        einrichtung: einrichtung,
      ),
      null => EigeneAngelegt(
        name: _name.text.trim(),
        area: _gebiet ?? SkillArea.koerper,
        difficulty: _grad,
        goal: _goal,
        einrichtung: einrichtung,
      ),
    });
  }

  void _waehleEigene() {
    if (widget.eigeneFrei <= 0) {
      setState(
        () => _hinweis =
            'Kein Platz frei. Jede freigeschaltete Vorlage gibt einen '
            'Platz für eine eigene.',
      );
      return;
    }
    setState(() => _vorlage = null);
    _weiter();
  }

  void _waehleVorlage(Habit habit) {
    if (widget.listeVoll) {
      setState(() => _hinweis = 'Die Liste ist voll. Stoppe erst eine andere.');
      return;
    }
    setState(() {
      _vorlage = habit;
      _tage = widget.tageFuer(habit.id);
    });
    _weiter();
  }

  /// Der Name, um den es geht — klein über der Frage, ab dem zweiten
  /// Blatt.
  String? get _worum {
    if (_vorlage case final vorlage?) return vorlage.name;
    final name = _name.text.trim();
    return _schritt == _Schritt.name || name.isEmpty ? null : name;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sonst verdeckt die Tastatur genau das Feld, in das getippt wird.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        // Kopf und Knöpfe stehen fest, nur die Frage rollt: „Weiter“
        // rutschte sonst unter den Rand, sobald Vorschläge und
        // Kopplungen ein Blatt lang machen.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnlegenKopf(
                weg: _weg.length,
                wo: _weg.indexOf(_schritt),
                onZurueck: _zurueck,
              ),
              const SizedBox(height: 10),
              Flexible(child: SingleChildScrollView(child: _frageUndInhalt())),
              if (_knoepfe() case final knoepfe?) ...<Widget>[
                const SizedBox(height: 14),
                knoepfe,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _frageUndInhalt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_worum case final worum?) ...<Widget>[
          Text(
            '„$worum“',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Palette.muted),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          _frage,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Palette.text,
          ),
        ),
        if (_unterzeile case final zeile?) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            zeile,
            style: const TextStyle(fontSize: 12, color: Palette.textDim),
          ),
        ],
        const SizedBox(height: 16),
        // Ein neues Blatt gleitet herein, statt hart zu wechseln.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (kind, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(animation),
              child: kind,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey<_Schritt>(_schritt),
            child: _inhalt(),
          ),
        ),
        if (_hinweis case final hinweis?) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            hinweis,
            style: const TextStyle(fontSize: 12, color: Palette.enemy),
          ),
        ],
      ],
    );
  }

  String get _frage => switch (_schritt) {
    _Schritt.art => 'Neue Gewohnheit',
    _Schritt.name => 'Was willst du tun?',
    _Schritt.gebiet => 'Wo zahlt es ein?',
    _Schritt.grad => 'Wie schwer fällt es dir?',
    _Schritt.ziel => 'Wie misst du es?',
    _Schritt.wann => 'Wann machst du das?',
    _Schritt.tage => 'An welchen Tagen?',
    _Schritt.danach => 'Und danach gönnst du dir?',
  };

  String? get _unterzeile => switch (_schritt) {
    _Schritt.gebiet => 'Dort wächst ihr Skill, und im Kampf ein Wert.',
    _Schritt.grad => 'Ändert nur die Erfahrung, nicht das Gold.',
    _Schritt.wann => 'Häng es an etwas, das du ohnehin tust.',
    _Schritt.danach => 'Etwas Kleines, das du sofort einlösen kannst.',
    _ => null,
  };

  Widget _inhalt() {
    return switch (_schritt) {
      _Schritt.art => _art(),
      _Schritt.name => AnlegenFeld(
        key: GewohnheitAnlegen.nameKey,
        controller: _name,
        hint: 'Zehn Liegestütze',
        maxLength: 60,
        autofocus: true,
        onSubmitted: _name.text.trim().isEmpty ? null : _weiter,
      ),
      _Schritt.gebiet => _gebiete(),
      _Schritt.grad => _grade(),
      _Schritt.ziel => _ziele(),
      _Schritt.wann => _wann(),
      _Schritt.tage => WeekdayPicker(
        selected: _tage,
        onChanged: (tage) => setState(() => _tage = tage),
      ),
      _Schritt.danach => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AnlegenFeld(
            key: cueTreatFieldKey,
            controller: _belohnung,
            hint: 'Eine Tasse Tee',
            maxLength: HabitTracker.maxCueLength,
            onSubmitted: _weiter,
          ),
          const SizedBox(height: 8),
          AnlegenVorschlaege(
            vorschlaege: treatSuggestions,
            onGewaehlt: (v) => setState(() => _belohnung.text = v),
          ),
        ],
      ),
    };
  }

  /// Unten: „Weiter“ oder „Fertig“, wo es ein Feld gibt; daneben
  /// „Ohne“, wo die Frage freiwillig ist. Eine reine Wahl braucht keinen
  /// Knopf — ein Tipp führt weiter.
  Widget? _knoepfe() {
    final freiwillig = switch (_schritt) {
      _Schritt.wann || _Schritt.danach => true,
      _ => false,
    };
    final mitKnopf = switch (_schritt) {
      _Schritt.name ||
      _Schritt.wann ||
      _Schritt.tage ||
      _Schritt.danach => true,
      _Schritt.ziel => _ziel == ZielArt.menge || _ziel == ZielArt.zeit,
      _Schritt.art || _Schritt.gebiet || _Schritt.grad => false,
    };
    if (!mitKnopf) return null;
    final bereit = _schritt != _Schritt.name || _name.text.trim().isNotEmpty;

    return Row(
      children: <Widget>[
        if (freiwillig)
          TextButton(
            key: GewohnheitAnlegen.ohneKey,
            onPressed: () {
              if (_schritt == _Schritt.wann) {
                _ausloeser.clear();
                setState(() => _anker = null);
              } else {
                _belohnung.clear();
              }
              _weiter();
            },
            child: const Text('Ohne'),
          ),
        const Spacer(),
        FilledButton(
          key: GewohnheitAnlegen.weiterKey,
          onPressed: bereit ? _weiter : null,
          child: Text(_istLetzter ? 'Fertig' : 'Weiter'),
        ),
      ],
    );
  }

  Widget _art() {
    final offen = _vorlagenOffen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AnlegenWahl(
          key: GewohnheitAnlegen.eigeneKey,
          icon: Icons.edit_rounded,
          titel: 'Eigene erstellen',
          zeile: '${widget.eigeneFrei} frei',
          aus: widget.eigeneFrei <= 0,
          onTap: _waehleEigene,
        ),
        const SizedBox(height: 10),
        AnlegenWahl(
          key: GewohnheitAnlegen.vorlageKey,
          icon: Icons.auto_stories_rounded,
          titel: 'Vorlage',
          zeile: '${widget.vorlagen.length + widget.ruhende.length} da',
          gewaehlt: offen,
          ende: AnimatedRotation(
            turns: offen ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more_rounded, color: Palette.text),
          ),
          onTap: () => setState(() => _vorlagenOffen = !offen),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: offen
              ? _vorlagenListe()
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _vorlagenListe() {
    if (widget.vorlagen.isEmpty && widget.ruhende.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(8, 12, 8, 0),
        child: Text(
          'Gerade keine. Neue Vorlagen schaltet der Wissensbaum frei.',
          style: TextStyle(fontSize: 12, color: Palette.textDim),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.ruhende.isNotEmpty) ...<Widget>[
            const AnlegenGruppe('Deine'),
            for (final habit in widget.ruhende) _eintrag(habit),
          ],
          if (widget.vorlagen.isNotEmpty) ...<Widget>[
            const AnlegenGruppe('Von der App'),
            for (final habit in widget.vorlagen) _eintrag(habit),
          ],
        ],
      ),
    );
  }

  Widget _eintrag(Habit habit) {
    return Opacity(
      opacity: widget.listeVoll ? 0.5 : 1,
      child: Druck(
        child: InkWell(
          key: GewohnheitAnlegen.vorlageEintrag(habit.id),
          onTap: () => _waehleVorlage(habit),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: <Widget>[
                StatIcon(habit.stat, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(fontSize: 14, color: Palette.text),
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Palette.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gebiete() {
    Widget kachel(SkillArea area) {
      return Expanded(
        child: AnlegenWahl(
          key: GewohnheitAnlegen.gebietKey(area),
          gewaehlt: _gebiet == area,
          senkrecht: true,
          icon: gebietZeichen(area),
          titel: area.label,
          // Was es im Kampf stärkt, folgt aus dem Gebiet (ADR-0088).
          unten: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              StatIcon(area.kampfwert, size: 14),
              const SizedBox(width: 4),
              Text(
                area.kampfwert.label,
                style: const TextStyle(fontSize: 12, color: Palette.textDim),
              ),
            ],
          ),
          onTap: () {
            setState(() => _gebiet = area);
            _weiter();
          },
        ),
      );
    }

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            kachel(SkillArea.koerper),
            const SizedBox(width: 10),
            kachel(SkillArea.geist),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            kachel(SkillArea.wissenschaft),
            const SizedBox(width: 10),
            kachel(SkillArea.gesellschaft),
          ],
        ),
      ],
    );
  }

  Widget _grade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final grad in HabitDifficulty.values) ...<Widget>[
          AnlegenWahl(
            key: GewohnheitAnlegen.gradKey(grad),
            gewaehlt: _grad == grad,
            icon: switch (grad) {
              HabitDifficulty.leicht => Icons.sentiment_satisfied_rounded,
              HabitDifficulty.mittel => Icons.sentiment_neutral_rounded,
              HabitDifficulty.schwer => Icons.local_fire_department_rounded,
            },
            titel: grad.label,
            zeile: _erfahrung(grad),
            onTap: () {
              setState(() => _grad = grad);
              _weiter();
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// „+30 % Erfahrung“ statt „×1,3“ — niemand soll rechnen müssen.
  static String _erfahrung(HabitDifficulty grad) {
    final prozent = ((grad.xpFactor - 1) * 100).round();
    if (prozent == 0) return 'Erfahrung wie üblich';
    return '${prozent > 0 ? '+' : '−'}${prozent.abs()} % Erfahrung';
  }

  Widget _ziele() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ziel in ZielArt.values) ...<Widget>[
          AnlegenWahl(
            key: GewohnheitAnlegen.zielKey(ziel),
            gewaehlt: _ziel == ziel,
            icon: ziel.icon,
            titel: ziel.label,
            onTap: () {
              setState(() => _ziel = ziel);
              if (ziel == ZielArt.keins) _weiter();
            },
          ),
          const SizedBox(height: 8),
        ],
        if (_ziel == ZielArt.menge)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: AnlegenFeld(
                  key: GewohnheitAnlegen.mengeKey,
                  controller: _menge,
                  hint: '5',
                  label: 'Wie viele?',
                  zahl: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AnlegenFeld(
                  controller: _einheit,
                  hint: 'Gläser',
                  label: 'Wovon?',
                  maxLength: 20,
                ),
              ),
            ],
          ),
        if (_ziel == ZielArt.zeit)
          AnlegenFeld(
            key: GewohnheitAnlegen.minutenKey,
            controller: _minuten,
            hint: '10',
            label: 'Wie viele Minuten?',
            zahl: true,
          ),
      ],
    );
  }

  Widget _wann() {
    final anker = widget.ankerFuer(_vorlage?.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AnlegenFeld(
          key: cueFieldKey,
          controller: _ausloeser,
          hint: 'Nach dem Zähneputzen',
          maxLength: HabitTracker.maxCueLength,
          onSubmitted: _weiter,
        ),
        const SizedBox(height: 8),
        AnlegenVorschlaege(
          vorschlaege: cueSuggestions,
          onGewaehlt: (v) => setState(() => _ausloeser.text = v),
        ),
        if (anker.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          const Text(
            'Oder direkt nach:',
            style: TextStyle(fontSize: 13, color: Palette.textDim),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final habit in anker)
                Druck(
                  child: ChoiceChip(
                    key: cueAnchorKey(habit.id),
                    showCheckmark: false,
                    selectedColor: Palette.accent,
                    avatar: Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: _anker == habit.id
                          ? Palette.surface
                          : Palette.textDim,
                    ),
                    label: Text(
                      habit.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _anker == habit.id
                            ? Palette.surface
                            : Palette.text,
                      ),
                    ),
                    selected: _anker == habit.id,
                    onSelected: (_) => setState(() {
                      _anker = _anker == habit.id ? null : habit.id;
                      if (_anker != null) _ausloeser.clear();
                    }),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
