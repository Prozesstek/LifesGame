import 'bestiarium.dart';
import 'entity.dart';
import 'stage.dart';

/// Was ein erstmals besiegter Gegner einbringt.
///
/// **Der Kampf gibt etwas, aber nur einmal je Gegner** -- die Entscheidung
/// aus ADR-0032. Bis dahin gab er gar nichts, weil `konzept.md` Abschnitt 2
/// ihn zur *Auszahlung* des Fortschritts erklaert und nicht zu seiner
/// Quelle. Der Einwand galt jedoch nur wiederholbarer Belohnung: Eine
/// Lektion in `package:theory` zahlt ebenfalls, und ebenfalls genau
/// einmal.
///
/// **Die Menge ist damit gedeckelt und nachrechenbar** -- siehe
/// [lifetimeXp] und [lifetimeGold]. Wer an diesen Zahlen dreht, laesst
/// `flutter test test/progression_test.dart` laufen: Dort haengen
/// Belohnungs-, Habit-, Level- und Preiskurve zusammen.
abstract final class LadderRewards {
  /// Erfahrung fuer Sprosse 1.
  static const int baseXp = 20;

  /// Wie viel Erfahrung je Sprosse dazukommt.
  static const int xpPerRung = 5;

  /// Gold fuer Sprosse 1.
  static const int baseGold = 8;

  /// Wie viel Gold je Sprosse dazukommt.
  ///
  /// **Bewusst flacher als die Erfahrung.** Gold hat mit dem Laden einen
  /// Abfluss, der auf den Zufluss aus Gewohnheiten ausgelegt ist (25 am
  /// Tag, siehe `package:gear`). Eine Reihe, die mehr einbringt als ein
  /// Monat Haekchen, machte den Laden zur Formsache.
  static const int goldPerRung = 2;

  static int xpFor(int rung) => baseXp + xpPerRung * (rung - 1);

  static int goldFor(int rung) => baseGold + goldPerRung * (rung - 1);

  /// **Nur noch für alte Stände** (ADR-0072). Bis dahin zahlten vier
  /// Stufen des Tages je ein Viertel ihres Erstsiegs (ADR-0040). Was ein
  /// Stand damals verdient hat, bleibt gespeichert und zählt weiter —
  /// sonst fiele nachträglich ein Level. Neues kommt hier nicht mehr an:
  /// Der eine Kampf des Tages ist die Tagesgrube, und die zahlt Ruhm.
  static const double dailyShare = 0.25;

  static int dailyXpFor(int rung) => (xpFor(rung) * dailyShare).round();

  static int dailyGoldFor(int rung) => (goldFor(rung) * dailyShare).round();

  /// Alles, was die ganze Reihe ueber ein Spielerleben hergibt.
  static int get lifetimeXp => _summe(xpFor);

  static int get lifetimeGold => _summe(goldFor);

  static int _summe(int Function(int) je) {
    var summe = 0;
    for (var rung = 1; rung <= PitStage.count; rung++) {
      summe += je(rung);
    }
    return summe;
  }
}

/// Erfahrung und Gold zusammen — ein Topf oder ein Teil davon.
typedef Payout = ({int xp, int gold});

const Payout _nichts = (xp: 0, gold: 0);

Payout _plus(Payout a, Payout b) => (xp: a.xp + b.xp, gold: a.gold + b.gold);

Payout _minus(Payout a, Payout b) => (
      xp: a.xp - b.xp < 0 ? 0 : a.xp - b.xp,
      gold: a.gold - b.gold < 0 ? 0 : a.gold - b.gold
    );

Payout _hoechstens(Payout a, Payout grenze) => (
      xp: a.xp < grenze.xp ? a.xp : grenze.xp,
      gold: a.gold < grenze.gold ? a.gold : grenze.gold,
    );

/// Wie weit jemand in der Gegnerreihe gekommen ist.
///
/// **Eine einzige Zahl, und das ist der ganze Punkt.** Die Reihe wird von
/// unten nach oben gegangen: Wer auf Sprosse 7 steht, hat 1 bis 6
/// geschlagen. Eine Liste besiegter Ids waere dieselbe Information in
/// laenger -- und eine zweite Wahrheit, sobald sie von der Zahl abweicht.
///
/// Erfahrung und Gold stehen deshalb auch hier nicht: Sie werden aus
/// [highestDefeated] **gerechnet** (ADR-0008, ADR-0011). Ein gespeicherter
/// Betrag koennte von der Rechnung abweichen, eine Sprossenzahl *ist* die
/// Rechnung.
class LadderProgress {
  const LadderProgress({
    this.highestDefeated = 0,
    this.defeats = const <int, int>{},
    this.dailyPicks = const <int, List<int>>{},
    this.dailyClears = const <int, Set<int>>{},
    this.partial = const <int, Payout>{},
    this.dailyPartial = const <int, Map<int, Payout>>{},
    this.bestTimes = const <int, double>{},
    this.bestiarium = const Bestiarium.leer(),
  });

  const LadderProgress.empty() : this();

  /// Die hoechste Sprosse, die geschlagen wurde. 0 heisst: noch keine.
  final int highestDefeated;

  /// Wie oft an welcher Sprosse verloren wurde.
  ///
  /// **Die eine Spur, die ADR-0033 dem Kampf hinzufuegt.** Ohne sie gibt
  /// es „der Unbeugsame" nicht: Der Stand haelt sonst nur den hoechsten
  /// Sieg, und eine Niederlage steht nirgends.
  ///
  /// Eine Zahl je Sprosse, die nur steigt -- damit kann sie nie zu einer
  /// zweiten Wahrheit werden, und die Bedingung faellt nie wieder weg.
  /// Sie wirkt allerdings **nicht rueckwirkend**: Wer vor ihrem Einbau
  /// dreimal an Sprosse 7 gescheitert ist, hat das nirgends stehen.
  final Map<int, int> defeats;

  /// Welche vier Stufen an welchem Tag die Dailies waren (Tage seit dem
  /// 1.1.1970).
  ///
  /// **Nur noch Historie** (ADR-0072): Dailies gibt es nicht mehr, aber
  /// was ein Stand damit verdient hat, zählt weiter. Diese drei Felder
  /// werden gelesen und geschrieben, nie mehr verändert.
  final Map<int, List<int>> dailyPicks;

  /// Welche Dailies an welchem Tag geschafft wurden. Erfahrung und Gold
  /// daraus werden gerechnet.
  final Map<int, Set<int>> dailyClears;

  /// Was aus dem Topf einer **noch nicht** geschafften Stufe schon gezahlt
  /// ist — gesammelt in Läufen, die verloren gingen (ADR-0041). Mit dem
  /// Sieg zählt der volle Betrag, und der Eintrag ist bedeutungslos.
  final Map<int, Payout> partial;

  /// Dasselbe für die Dailies von damals, je Tag und Stufe.
  final Map<int, Map<int, Payout>> dailyPartial;

  /// Die schnellste gewonnene Zeit je Stufe, in Sekunden (ADR-0048).
  ///
  /// **Das Können, nicht die Macht.** Wer besser spielt, ist schneller;
  /// eine Bestzeit gibt einer geschafften Stufe wieder einen Grund. Sie
  /// zahlt nichts und schaltet nichts frei — sie kann fallen, und darf es.
  final Map<int, double> bestTimes;

  /// Wie oft welche Art Gegner und welcher Wächter fiel — die Gegner der
  /// Sammlung (Issue #138). Grube und Tagesgrube zählen beide.
  final Bestiarium bestiarium;

  /// Trägt ein, was ein Lauf gefällt hat — gewonnen oder verloren.
  LadderProgress recordKills(
    Map<EnemyKind, int> gegner, {
    BossKind? waechter,
  }) {
    if (gegner.isEmpty && waechter == null) return this;
    return copyWith(
      bestiarium: bestiarium.mit(gegner: gegner, waechter: waechter),
    );
  }

  /// Hält einen Sieg in [seconds] fest, wenn er schneller war als der
  /// bisher beste. Auf eine Zehntelsekunde gerundet — mehr liest niemand.
  LadderProgress recordTime(int rung, double seconds) {
    if (rung < 1 || rung > PitStage.count || seconds <= 0) return this;
    final gerundet = (seconds * 10).round() / 10;
    final bisher = bestTimes[rung];
    if (bisher != null && bisher <= gerundet) return this;
    return copyWith(
      bestTimes: <int, double>{...bestTimes, rung: gerundet},
    );
  }

  /// Was ein Lauf auf [rung] noch einbringen kann — der **Rest** des
  /// Topfs.
  ///
  /// **Nur eine neue Stufe hat einen**: ihren Erstsieg, abzüglich dessen,
  /// was verlorene Läufe schon gesammelt haben (ADR-0041). Eine geschaffte
  /// Stufe zahlt nichts mehr (ADR-0032) — seit ADR-0072 auch nicht mehr
  /// als Stufe des Tages.
  Payout potFor(int rung) {
    if (rung != highestDefeated + 1 || rung > PitStage.count) return _nichts;
    final voll =
        (xp: LadderRewards.xpFor(rung), gold: LadderRewards.goldFor(rung));
    return _minus(voll, partial[rung] ?? _nichts);
  }

  /// Trägt einen Lauf ein: was er aus dem Topf gesammelt hat, und ob er
  /// gewonnen wurde. **Mehr als der Topf zählt nie** — was die Welt meldet,
  /// wird auf [potFor] gekappt.
  LadderProgress bookRun(
    int rung, {
    required bool won,
    required Payout collected,
  }) {
    // Eine geschaffte Stufe ändert nur noch, wie oft dort verloren wurde.
    if (rung != highestDefeated + 1) return won ? this : recordDefeat(rung);

    if (won) {
      final ohne = Map<int, Payout>.of(partial)..remove(rung);
      return defeat(rung).copyWith(partial: ohne);
    }
    final gesammelt = _hoechstens(collected, potFor(rung));
    final bisher = partial[rung] ?? _nichts;
    return recordDefeat(rung).copyWith(
      partial: <int, Payout>{...partial, rung: _plus(bisher, gesammelt)},
    );
  }

  /// Ob [rung] am Tag [day] als Daily gezahlt hat — für alte Stände.
  bool _dailyCleared(int day, int rung) {
    return dailyClears[day]?.contains(rung) ?? false;
  }

  /// **`copyWith` statt des Konstruktors**: Ein neues Feld mit
  /// Standardwert fiel hier sonst still heraus (`gotchas.md`, zweimal).
  LadderProgress copyWith({
    int? highestDefeated,
    Map<int, int>? defeats,
    Map<int, List<int>>? dailyPicks,
    Map<int, Set<int>>? dailyClears,
    Map<int, Payout>? partial,
    Map<int, Map<int, Payout>>? dailyPartial,
    Map<int, double>? bestTimes,
    Bestiarium? bestiarium,
  }) {
    return LadderProgress(
      highestDefeated: highestDefeated ?? this.highestDefeated,
      defeats: defeats ?? this.defeats,
      dailyPicks: dailyPicks ?? this.dailyPicks,
      dailyClears: dailyClears ?? this.dailyClears,
      partial: partial ?? this.partial,
      dailyPartial: dailyPartial ?? this.dailyPartial,
      bestTimes: bestTimes ?? this.bestTimes,
      bestiarium: bestiarium ?? this.bestiarium,
    );
  }

  /// Der Gegner, der als Naechstes ansteht.
  ///
  /// Bleibt auf der letzten Sprosse stehen, wenn die Reihe durch ist --
  /// so gibt es immer einen Kampf, auch am Ende.
  int get nextRung {
    final naechste = highestDefeated + 1;
    return naechste > PitStage.count ? PitStage.count : naechste;
  }

  bool get isComplete => highestDefeated >= PitStage.count;

  /// Ob ein Sieg gegen [rung] noch etwas einbringt.
  bool isNewGround(int rung) => rung > highestDefeated;

  /// Erstsiege plus die Dailies von damals — gerechnet, nie gezählt.
  ///
  /// Dazu, was aus den Töpfen noch nicht geschaffter Stufen schon
  /// gefallen ist (ADR-0041).
  int get earnedXp =>
      _summeBis(LadderRewards.xpFor) +
      _dailies(LadderRewards.dailyXpFor) +
      _teile((p) => p.xp);

  int get earnedGold =>
      _summeBis(LadderRewards.goldFor) +
      _dailies(LadderRewards.dailyGoldFor) +
      _teile((p) => p.gold);

  int _teile(int Function(Payout) je) {
    var summe = 0;
    for (final entry in partial.entries) {
      if (entry.key > highestDefeated) summe += je(entry.value);
    }
    for (final tag in dailyPartial.entries) {
      for (final entry in tag.value.entries) {
        if (!_dailyCleared(tag.key, entry.key)) summe += je(entry.value);
      }
    }
    return summe;
  }

  int _dailies(int Function(int) je) {
    var summe = 0;
    for (final stufen in dailyClears.values) {
      for (final rung in stufen) {
        summe += je(rung);
      }
    }
    return summe;
  }

  /// Traegt einen Sieg ein.
  ///
  /// **Nur ein Schritt nach oben zaehlt.** Ein erneuter Sieg gegen einen
  /// laengst geschlagenen Gegner laesst den Stand unveraendert -- und
  /// damit auch Erfahrung und Gold. Das ist die Stelle, an der aus
  /// "Belohnung" keine Dauerquelle wird.
  LadderProgress defeat(int rung) {
    if (!isNewGround(rung)) return this;
    if (rung > PitStage.count) return this;

    // Sprossen lassen sich nicht ueberspringen: Wer Sprosse 9 meldet,
    // ohne 8 geschlagen zu haben, hat einen Fehler im Aufrufer -- nicht
    // einen Fortschritt.
    if (rung != highestDefeated + 1) return this;

    return copyWith(highestDefeated: rung);
  }

  /// Traegt eine Niederlage ein.
  ///
  /// Zaehlt auch an einer Sprosse weiter, die laengst geschlagen ist --
  /// wer zurueckgeht und verliert, hat verloren. Fuer „der Unbeugsame"
  /// spielt das keine Rolle: Dort zaehlt nur, was **vor** dem Sieg stand,
  /// und ein spaeterer Verlust kann die Bedingung nur leichter machen,
  /// nie schwerer.
  LadderProgress recordDefeat(int rung) {
    if (rung < 1 || rung > PitStage.count) return this;

    return copyWith(
      defeats: <int, int>{...defeats, rung: defeatsAt(rung) + 1},
    );
  }

  /// Wie oft an dieser Sprosse verloren wurde.
  int defeatsAt(int rung) => defeats[rung] ?? 0;

  /// Wie viele Sprossen nach mindestens [defeats] Niederlagen doch fielen.
  ///
  /// **Die Zahl kommt von aussen**, weil sie eine Bedingung von
  /// `package:achievements` ist und keine Kampfregel. Hier steht nur, wie
  /// man sie beantwortet.
  int comebackVictoriesAfter(int defeats) {
    if (defeats < 1) return 0;

    var count = 0;
    for (var rung = 1; rung <= highestDefeated; rung++) {
      if (defeatsAt(rung) >= defeats) count++;
    }
    return count;
  }

  int _summeBis(int Function(int) je) {
    var summe = 0;
    for (var rung = 1; rung <= highestDefeated; rung++) {
      summe += je(rung);
    }
    return summe;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'defeated': highestDefeated,
      // Nur schreiben, wenn etwas drinsteht: Ein Stand ohne Niederlagen
      // sieht aus wie vor ADR-0033. Gleiche Zurueckhaltung wie bei
      // `Loadout.soldIds`.
      if (defeats.isNotEmpty)
        'defeats': <String, Object?>{
          for (final entry in defeats.entries) '${entry.key}': entry.value,
        },
      if (dailyPicks.isNotEmpty)
        'dailies': <String, Object?>{
          for (final entry in dailyPicks.entries)
            '${entry.key}': <String, Object?>{
              'picks': entry.value,
              if (dailyClears[entry.key]?.isNotEmpty ?? false)
                'cleared': dailyClears[entry.key]!.toList()..sort(),
              if (dailyPartial[entry.key]?.isNotEmpty ?? false)
                'partial': _teileJson(dailyPartial[entry.key]!),
            },
        },
      if (partial.isNotEmpty) 'partial': _teileJson(partial),
      if (bestTimes.isNotEmpty)
        'best': <String, Object?>{
          for (final entry in bestTimes.entries) '${entry.key}': entry.value,
        },
      if (!bestiarium.istLeer) 'kills': bestiarium.toJson(),
    };
  }

  /// Liest den Stand. Was nicht lesbar ist, faellt auf 0 zurueck -- ein
  /// beschaedigter Eintrag darf hoechstens die Reihe zuruecksetzen, nie
  /// den ganzen Stand kosten (ADR-0010).
  factory LadderProgress.fromJson(Map<String, Object?> json) {
    // Niederlagen werden auch dann gelesen, wenn die Sprossenzahl fehlt
    // oder unbrauchbar ist: Die beiden sind voneinander unabhaengig, und
    // nachsichtig heisst hier nachsichtig je Feld (ADR-0010).
    final gezaehlt = <int, int>{};
    final rohDefeats = json['defeats'];
    if (rohDefeats is Map) {
      for (final entry in rohDefeats.entries) {
        final key = entry.key;
        final rung = key is int ? key : int.tryParse('$key');
        final count = entry.value;
        if (rung == null || rung < 1 || rung > PitStage.count) continue;
        if (count is! int || count <= 0) continue;
        gezaehlt[rung] = count;
      }
    }

    final roh = json['defeated'];
    final hoechste = roh is int && roh > 0
        ? (roh > PitStage.count ? PitStage.count : roh)
        : 0;

    final picks = <int, List<int>>{};
    final clears = <int, Set<int>>{};
    final tagesTeile = <int, Map<int, Payout>>{};
    final rohDailies = json['dailies'];
    if (rohDailies is Map) {
      for (final entry in rohDailies.entries) {
        final tag = int.tryParse('${entry.key}');
        final wert = entry.value;
        if (tag == null || wert is! Map) continue;
        final gezogen = _stufen(wert['picks']);
        if (gezogen.isEmpty) continue;
        picks[tag] = List<int>.unmodifiable(gezogen);
        // Nur, was an dem Tag auch Daily war — ein fremder Eintrag darf
        // kein Gold erfinden.
        final geschafft = _stufen(wert['cleared']).where(gezogen.contains);
        if (geschafft.isNotEmpty) {
          clears[tag] = Set<int>.unmodifiable(geschafft);
        }
        final teile = _teileLesen(
          wert['partial'],
          (r) => (
            xp: LadderRewards.dailyXpFor(r),
            gold: LadderRewards.dailyGoldFor(r)
          ),
        )..removeWhere((r, _) => !gezogen.contains(r));
        if (teile.isNotEmpty) tagesTeile[tag] = teile;
      }
    }

    return LadderProgress(
      highestDefeated: hoechste,
      defeats: gezaehlt,
      dailyPicks: picks,
      dailyClears: clears,
      partial: _teileLesen(
        json['partial'],
        (r) => (xp: LadderRewards.xpFor(r), gold: LadderRewards.goldFor(r)),
      ),
      dailyPartial: tagesTeile,
      bestTimes: _zeitenLesen(json['best']),
      bestiarium: Bestiarium.fromJson(json['kills']),
    );
  }

  static Map<int, double> _zeitenLesen(Object? roh) {
    final zeiten = <int, double>{};
    if (roh is! Map) return zeiten;
    for (final entry in roh.entries) {
      final rung = int.tryParse('${entry.key}');
      final wert = entry.value;
      if (rung == null || rung < 1 || rung > PitStage.count) continue;
      if (wert is! num || wert <= 0) continue;
      zeiten[rung] = wert.toDouble();
    }
    return zeiten;
  }

  static Map<String, Object?> _teileJson(Map<int, Payout> teile) {
    return <String, Object?>{
      for (final entry in teile.entries)
        '${entry.key}': <int>[entry.value.xp, entry.value.gold],
    };
  }

  /// Nachsichtig je Eintrag; und nie mehr als der volle Topf — ein
  /// fremder Eintrag darf kein Gold erfinden.
  static Map<int, Payout> _teileLesen(
    Object? roh,
    Payout Function(int rung) voll,
  ) {
    final teile = <int, Payout>{};
    if (roh is! Map) return teile;
    for (final entry in roh.entries) {
      final rung = int.tryParse('${entry.key}');
      final wert = entry.value;
      if (rung == null || rung < 1 || rung > PitStage.count) continue;
      if (wert is! List || wert.length != 2) continue;
      final xp = wert[0];
      final gold = wert[1];
      if (xp is! int || gold is! int || xp < 0 || gold < 0) continue;
      teile[rung] = _hoechstens((xp: xp, gold: gold), voll(rung));
    }
    return teile;
  }

  static List<int> _stufen(Object? roh) {
    if (roh is! List) return const <int>[];
    return <int>[
      for (final s in roh)
        if (s is int && s >= 1 && s <= PitStage.count) s,
    ];
  }

  @override
  bool operator ==(Object other) {
    if (other is! LadderProgress) return false;
    if (other.highestDefeated != highestDefeated) return false;
    if (other.defeats.length != defeats.length) return false;
    for (final entry in defeats.entries) {
      if (other.defeats[entry.key] != entry.value) return false;
    }
    if (other.dailyPicks.length != dailyPicks.length) return false;
    for (final entry in dailyPicks.entries) {
      final dort = other.dailyPicks[entry.key];
      if (dort == null || dort.join(',') != entry.value.join(',')) {
        return false;
      }
    }
    if (other.earnedXp != earnedXp || other.earnedGold != earnedGold) {
      return false;
    }
    if (other.dailyClears.length != dailyClears.length) return false;
    for (final entry in dailyClears.entries) {
      final dort = other.dailyClears[entry.key];
      if (dort == null || !dort.containsAll(entry.value)) return false;
      if (dort.length != entry.value.length) return false;
    }
    if (other.bestTimes.length != bestTimes.length) return false;
    for (final entry in bestTimes.entries) {
      if (other.bestTimes[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        highestDefeated,
        Object.hashAllUnordered(<Object>[
          for (final entry in defeats.entries)
            Object.hash(entry.key, entry.value),
        ]),
        Object.hashAllUnordered(<Object>[
          for (final entry in dailyClears.entries)
            Object.hash(entry.key, Object.hashAllUnordered(entry.value)),
        ]),
      );
}
