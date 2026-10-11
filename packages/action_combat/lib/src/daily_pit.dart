import 'balance.dart';
import 'level_builder.dart';
import 'stage.dart';
import 'stats.dart';
import 'world.dart';

/// Womit der Einheitsheld an einem Wochentag hinabsteigt (ADR-0072).
class DailyLoadout {
  const DailyLoadout({
    required this.weaponMoveId,
    required this.abilityIds,
    required this.stage,
  });

  /// Der Waffenzug — dieselbe Id wie in `PitWeapons`.
  final String weaponMoveId;

  /// Die drei Plätze, in der Reihenfolge der Knöpfe.
  final List<String> abilityIds;

  /// Die Stufe, auf der dieser Satz so schwer ist wie die anderen sechs.
  final int stage;
}

/// **Die Tagesgrube** — dieselbe Grube für alle, ein Versuch am Tag
/// (ADR-0072).
///
/// Drei Dinge machen sie für alle gleich, und jedes steht hier:
///
/// - **die Karte**: Der Startwert kommt aus dem Datum ([seedFor]), und aus
///   ihm folgen Karte, Wächter und Besetzung (`LevelBuilder`).
/// - **der Held**: für alle derselbe (`PitPower.dailyHero`). Stärker macht
///   nur, ob man heute in Form ist.
/// - **die Ausstattung**: je Wochentag ein fester Satz aus Waffe und drei
///   Fähigkeiten ([loadouts]).
///
/// Sie zahlt weder Erfahrung noch Gold und lässt nichts fallen: Kein
/// Kampf wird zur Dauerquelle (ADR-0032), und Schlüssel kommen nie aus
/// dem Spielen (ADR-0048). Was sie bringt, steht in [DailyPitRewards].
abstract final class DailyPit {
  /// Der Tag der ersten Tagesgrube, in Tagen seit dem 1.1.1970: der
  /// 11.10.2026. An ihm hängt nur die laufende Nummer.
  static const int firstDay = 20737;

  /// Die laufende Nummer — „Tagesgrube #12“. Ein Tag davor ist die erste.
  static int numberFor(int dayNumber) {
    final nummer = dayNumber - firstDay + 1;
    return nummer < 1 ? 1 : nummer;
  }

  /// Der Wochentag zu [dayNumber]: 0 ist Montag, 6 ist Sonntag. Der
  /// 1.1.1970 war ein Donnerstag.
  static int weekdayOf(int dayNumber) => (dayNumber + 3) % 7;

  /// **Sieben Sätze, Montag bis Sonntag.** Jeder trägt eine Waffe, etwas
  /// zum Zuschlagen, etwas für die Traube und etwas, das am Leben hält —
  /// zusammen alle neunzehn Fähigkeiten, zwei davon doppelt.
  ///
  /// **Die Stufe ist gemessen, nicht geschätzt** (`dart run
  /// tool/tagesgrube_sim.dart`): Sie ist die, auf der der Bot mit diesem
  /// Satz ohne Form etwa jeden zweiten Lauf gewinnt und in Form fast
  /// jeden. So ist ein Dienstag anders als ein Mittwoch, aber nicht
  /// schwerer. Wer einen Satz ändert, misst seine Stufe neu.
  static const List<DailyLoadout> loadouts = <DailyLoadout>[
    // Montag: was jeder kennt — der Bogen und die drei ersten aus dem Baum.
    DailyLoadout(
      weaponMoveId: 'basic_attack',
      abilityIds: <String>['funkenstoss', 'steinhaut', 'bluetentau'],
      stage: 12,
    ),
    // Dienstag: mitten hinein — der Zweihänder trifft alle.
    DailyLoadout(
      weaponMoveId: 'greatsword_cleave',
      abilityIds: <String>['klingenwirbel', 'wurzelgriff', 'mend'],
      stage: 12,
    ),
    // Mittwoch: auf Abstand.
    DailyLoadout(
      weaponMoveId: 'longbow_volley',
      abilityIds: <String>['donnerkeil', 'frostnebel', 'aurastrom'],
      stage: 12,
    ),
    // Donnerstag: zehren — Gift am Boden, Leben aus dem Treffer.
    DailyLoadout(
      weaponMoveId: 'staff_gather',
      abilityIds: <String>['seelenraub', 'giftmoor', 'breath'],
      stage: 12,
    ),
    // Freitag: zwei Stiche, ein Sturm, und wer zuschlägt, trifft sich.
    DailyLoadout(
      weaponMoveId: 'dagger_double',
      abilityIds: <String>['poison_strike', 'sandsturm', 'prisma_barriere'],
      stage: 11,
    ),
    // Samstag: Wucht.
    DailyLoadout(
      weaponMoveId: 'mace_bash',
      abilityIds: <String>['heavy_attack', 'vulkanbruch', 'steinhaut'],
      stage: 13,
    ),
    // Sonntag: das Seltene — Sonnenklinge und Sternenfall.
    DailyLoadout(
      weaponMoveId: 'sunblade_flare',
      abilityIds: <String>['sternenfall', 'zeitdehnung', 'bluetentau'],
      stage: 13,
    ),
  ];

  /// Der Satz des Tages [dayNumber].
  static DailyLoadout loadoutFor(int dayNumber) {
    return loadouts[weekdayOf(dayNumber)];
  }

  /// Der Startwert des Tages — für alle derselbe.
  ///
  /// **Ganzzahlig und unter 2⁵³** (Park–Miller): Im Browser rechnet Dart
  /// mit Gleitkommazahlen, und ein Startwert, der dort anders herauskäme,
  /// wäre eine andere Grube.
  static int seedFor(int dayNumber) {
    const m = 2147483647;
    var zustand = (dayNumber.abs() * 7919 + 104729) % m;
    if (zustand == 0) zustand = 1;
    // Die ersten Würfe aufeinanderfolgender Tage liegen dicht beieinander.
    for (var i = 0; i < 3; i++) {
      zustand = (zustand * 48271) % m;
    }
    return zustand % (1 << 30);
  }

  /// Die Welt des Tages [dayNumber]: Karte, Held und Ausstattung.
  ///
  /// Ohne Topf — sie zahlt weder Erfahrung noch Gold.
  static ActionWorld worldFor(int dayNumber, {required bool inForm}) {
    final satz = loadoutFor(dayNumber);
    final stage = PitStage(satz.stage);
    final seed = seedFor(dayNumber);
    return ActionWorld(
      level: LevelBuilder.build(stage: stage, seed: seed),
      heroStats: PitPower.dailyHero(inForm: inForm),
      stage: stage,
      abilityIds: satz.abilityIds,
      weaponMoveId: satz.weaponMoveId,
      seed: seed,
    );
  }
}

/// Was die Tagesgrube einbringt: **nur Ruhm** (ADR-0072).
///
/// Ruhm ist ein Stand zum Vergleichen, kein Zahlungsmittel (ADR-0033) —
/// deshalb darf er aus einem Kampf kommen, der jeden Tag wiederkehrt.
/// Auch wer verliert oder abbricht, ist angetreten.
abstract final class DailyPitRewards {
  static const int fameForAttempt = 1;
  static const int fameForWin = 3;
  static const int fameForWinInForm = 5;

  static int fameFor(DailyRun run) {
    if (!run.won) return fameForAttempt;
    return run.condition == DailyCondition.inForm
        ? fameForWinInForm
        : fameForWin;
  }
}

/// In welcher Verfassung jemand hinabsteigt.
///
/// **Ja oder nein, nicht je Häkchen**: Wer eine Gewohnheit hat und sie
/// erledigt, ist so sehr in Form wie jemand mit fünf. Ein Ruhetag — nichts
/// fällig — ist nicht in Form (ADR-0064), aber er hat einen eigenen Namen:
/// Geplante Ruhe ist kein Versäumnis.
enum DailyCondition {
  inForm('f'),
  ohneForm('o'),
  ruhetag('r');

  const DailyCondition(this.code);

  final String code;

  static DailyCondition? ofCode(Object? code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// Wie ein Versuch ausging.
enum DailyOutcome {
  sieg('s'),
  gefallen('g'),
  zeitAus('z'),

  /// Begonnen und nie beendet. **So steht jeder Versuch da, sobald er
  /// beginnt** — schliesst jemand die App mitten im Lauf, bleibt es dabei.
  abgebrochen('a');

  const DailyOutcome(this.code);

  final String code;

  static DailyOutcome? ofCode(Object? code) {
    for (final o in values) {
      if (o.code == code) return o;
    }
    return null;
  }
}

/// Ein Feld der Raumzeile: wie es in einem Raum lief.
enum RoomMark {
  /// Kaum etwas abbekommen.
  sauber('s'),

  /// Spürbar getroffen.
  angekratzt('a'),

  /// Schwer getroffen.
  blutig('b'),

  /// Hier gefallen.
  gefallen('g'),

  /// Hier lief die Uhr ab.
  zeitAus('z'),

  /// Der Wächter liegt.
  krone('k'),

  /// Nicht erreicht.
  offen('o');

  const RoomMark(this.code);

  final String code;

  static RoomMark? ofCode(String code) {
    for (final m in values) {
      if (m.code == code) return m;
    }
    return null;
  }
}

/// Ein Versuch in der Tagesgrube.
class DailyRun {
  const DailyRun({
    required this.outcome,
    required this.seconds,
    required this.condition,
    required this.rooms,
  });

  /// Der Versuch beginnt. Bis er endet, gilt er als abgebrochen.
  const DailyRun.started({required this.condition})
      : outcome = DailyOutcome.abgebrochen,
        seconds = 0,
        rooms = const <RoomMark>[];

  final DailyOutcome outcome;

  /// Wie lange der Lauf dauerte. Null bei einem abgebrochenen.
  final double seconds;

  /// Die Verfassung **beim Hinabsteigen** — wer danach abhakt, war beim
  /// Kampf trotzdem nicht in Form.
  final DailyCondition condition;

  /// Die Raumzeile: ein Feld je Raum vor dem Wächter, zuletzt seins. Der
  /// Start steht nicht darin — dort wartet niemand.
  final List<RoomMark> rooms;

  bool get won => outcome == DailyOutcome.sieg;

  bool get isFinished => outcome != DailyOutcome.abgebrochen;

  int get fame => DailyPitRewards.fameFor(this);

  /// Derselbe Versuch, zu Ende gegangen wie [world].
  DailyRun endedBy(ActionWorld world) {
    return DailyRun(
      outcome: world.isWon
          ? DailyOutcome.sieg
          : world.isTimedOut
              ? DailyOutcome.zeitAus
              : DailyOutcome.gefallen,
      seconds: (world.elapsed * 10).round() / 10,
      condition: condition,
      rooms: marksOf(world),
    );
  }

  /// Die Raumzeile zu einem beendeten Lauf.
  ///
  /// **Die Farbe sagt, was der Raum gekostet hat**, als Anteil des vollen
  /// Lebens (`ActionBalance.dailyRoomLightShare`, `dailyRoomHeavyShare`).
  /// Was im Start ankam, zählt zum ersten Raum: Wer sich dorthin
  /// zurückzieht, hat den Kampf nicht verlassen.
  static List<RoomMark> marksOf(ActionWorld world) {
    final anzahl = world.level.rooms.length;
    if (anzahl < 2) return const <RoomMark>[];

    final schaden = world.damageByRoom;
    final letzter = anzahl - 1;
    final verloren = world.isOver && !world.isWon;
    final ende = world.currentRoom < 1 ? 1 : world.currentRoom;
    final endeMarke = world.isTimedOut ? RoomMark.zeitAus : RoomMark.gefallen;

    RoomMark farbe(int raum) {
      final verlust = schaden[raum] + (raum == 1 ? schaden[0] : 0);
      final anteil = verlust / world.heroMaxHp;
      if (anteil < ActionBalance.dailyRoomLightShare) return RoomMark.sauber;
      if (anteil < ActionBalance.dailyRoomHeavyShare) {
        return RoomMark.angekratzt;
      }
      return RoomMark.blutig;
    }

    return List<RoomMark>.unmodifiable(<RoomMark>[
      for (var raum = 1; raum <= letzter; raum++)
        if (verloren && raum == ende)
          endeMarke
        else if (raum == letzter)
          world.isWon ? RoomMark.krone : RoomMark.offen
        else if (raum > world.deepestRoom)
          RoomMark.offen
        else
          farbe(raum),
    ]);
  }

  /// Vier Einträge, kurz gehalten: Der Stand wird als Text kopiert
  /// (ADR-0054), und es kommt jeden Tag einer dazu.
  List<Object?> toJson() {
    return <Object?>[
      outcome.code,
      seconds,
      condition.code,
      rooms.map((m) => m.code).join(),
    ];
  }

  /// Liest einen Versuch — oder null, wenn er nicht lesbar ist. Ein
  /// unbekanntes Feld der Raumzeile fällt heraus, der Versuch bleibt.
  static DailyRun? fromJson(Object? json) {
    if (json is! List || json.length < 3) return null;
    final outcome = DailyOutcome.ofCode(json[0]);
    final sekunden = json[1];
    final condition = DailyCondition.ofCode(json[2]);
    if (outcome == null || condition == null) return null;
    if (sekunden is! num || sekunden < 0) return null;
    final zeile = json.length > 3 ? json[3] : '';
    final rooms = <RoomMark>[];
    if (zeile is String) {
      for (var i = 0; i < zeile.length; i++) {
        final marke = RoomMark.ofCode(zeile[i]);
        if (marke != null) rooms.add(marke);
      }
    }
    return DailyRun(
      outcome: outcome,
      seconds: sekunden.toDouble(),
      condition: condition,
      rooms: List<RoomMark>.unmodifiable(rooms),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailyRun &&
        other.outcome == outcome &&
        other.seconds == seconds &&
        other.condition == condition &&
        other.rooms.join() == rooms.join();
  }

  @override
  int get hashCode => Object.hash(outcome, seconds, condition, rooms.join());
}

/// Die Versuche in der Tagesgrube, je Tag einer — eine **Historie** wie
/// die Häkchen (ADR-0072).
///
/// Ruhm wird daraus gerechnet, nie gezählt. Und weil ein Tag nur einen
/// Eintrag haben kann, ist „ein Versuch“ keine Regel, die jemand prüfen
/// muss: Es gibt keinen Platz für einen zweiten.
class DailyPitLog {
  const DailyPitLog._(this._runs);

  const DailyPitLog.empty() : _runs = const <int, DailyRun>{};

  /// Je Tag (Tage seit dem 1.1.1970) der Versuch.
  final Map<int, DailyRun> _runs;

  bool get isEmpty => _runs.isEmpty;

  /// An wie vielen Tagen jemand hinabgestiegen ist.
  int get attempts => _runs.length;

  int get wins => _runs.values.where((r) => r.won).length;

  DailyRun? runOn(int day) => _runs[day];

  bool hasStarted(int day) => _runs.containsKey(day);

  /// Alles, was die Tagesgrube je an Ruhm gebracht hat.
  int get fame {
    var summe = 0;
    for (final run in _runs.values) {
      summe += run.fame;
    }
    return summe;
  }

  /// Der Versuch des Tages beginnt — **und ist damit gebraucht.**
  ///
  /// Nur so hält „ein Versuch“ im Browser: Zählte er erst mit dem Ende,
  /// reichte Neuladen, sobald es schlecht läuft. Ändert nichts, wenn der
  /// Tag schon einen Versuch hat.
  DailyPitLog start(int day, {required DailyCondition condition}) {
    if (hasStarted(day)) return this;
    return DailyPitLog._(<int, DailyRun>{
      ..._runs,
      day: DailyRun.started(condition: condition),
    });
  }

  /// Trägt ein, wie der Versuch des Tages ausging. Die Verfassung bleibt
  /// die vom Start.
  ///
  /// **Nur einmal, und nur nach [start]:** Ein beendeter Versuch lässt
  /// sich nicht überschreiben.
  DailyPitLog finish(int day, ActionWorld world) {
    final bisher = _runs[day];
    if (bisher == null || bisher.isFinished) return this;
    return DailyPitLog._(<int, DailyRun>{
      ..._runs,
      day: bisher.endedBy(world),
    });
  }

  /// Derselbe Stand ohne den Versuch von [day]. Nur der Entwicklermodus
  /// ruft das.
  DailyPitLog without(int day) {
    if (!hasStarted(day)) return this;
    return DailyPitLog._(Map<int, DailyRun>.of(_runs)..remove(day));
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      for (final entry in _runs.entries) '${entry.key}': entry.value.toJson(),
    };
  }

  /// Nachsichtig je Eintrag (ADR-0010): Ein unlesbarer Tag fehlt, die
  /// anderen bleiben.
  factory DailyPitLog.fromJson(Map<String, Object?> json) {
    final runs = <int, DailyRun>{};
    for (final entry in json.entries) {
      final tag = int.tryParse(entry.key);
      final run = DailyRun.fromJson(entry.value);
      if (tag == null || run == null) continue;
      runs[tag] = run;
    }
    return DailyPitLog._(runs);
  }

  @override
  bool operator ==(Object other) {
    if (other is! DailyPitLog || other._runs.length != _runs.length) {
      return false;
    }
    for (final entry in _runs.entries) {
      if (other._runs[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(<Object>[
        for (final entry in _runs.entries) Object.hash(entry.key, entry.value),
      ]);
}
