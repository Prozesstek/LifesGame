import 'dailies.dart';
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

  /// **Ein Daily zahlt ein Viertel des Erstsiegs** (ADR-0040). Vier davon
  /// liegen damit in der Grössenordnung eines Tags Gewohnheiten, nicht
  /// darüber — sonst wäre der Kampf die Quelle des Fortschritts statt
  /// seiner Auszahlung (`konzept.md` Abschnitt 2).
  static const double dailyShare = 0.25;

  static int dailyXpFor(int rung) => (xpFor(rung) * dailyShare).round();

  static int dailyGoldFor(int rung) => (goldFor(rung) * dailyShare).round();

  /// Was vier Dailies an einem Tag höchstens einbringen — die vier
  /// obersten Stufen. Die Obergrenze, gegen die die Kurven rechnen.
  static int get maxDailyXpPerDay => _obersteVier(dailyXpFor);

  static int get maxDailyGoldPerDay => _obersteVier(dailyGoldFor);

  static int _obersteVier(int Function(int) je) {
    var summe = 0;
    for (var i = 0; i < PitDailies.perDay; i++) {
      summe += je(PitStage.count - i);
    }
    return summe;
  }

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
  /// 1.1.1970). **Eingefroren**, sobald sie zum ersten Mal gebraucht
  /// werden: Sie hängen an der höchsten geschafften Stufe, und wer mittags
  /// eine neue schafft, soll nicht plötzlich andere vier vor sich haben.
  final Map<int, List<int>> dailyPicks;

  /// Welche Dailies an welchem Tag geschafft wurden — eine **Historie**,
  /// wie die Häkchen. Erfahrung und Gold daraus werden gerechnet.
  final Map<int, Set<int>> dailyClears;

  /// Was aus dem Topf einer **noch nicht** geschafften Stufe schon gezahlt
  /// ist — gesammelt in Läufen, die verloren gingen (ADR-0041). Mit dem
  /// Sieg zählt der volle Betrag, und der Eintrag ist bedeutungslos.
  final Map<int, Payout> partial;

  /// Dasselbe für die Dailies, je Tag und Stufe.
  final Map<int, Map<int, Payout>> dailyPartial;

  /// Was ein Lauf auf [rung] am Tag [day] noch einbringen kann — der
  /// **Rest** des Topfs. Eine neue Stufe: ihr Erstsieg; ein Daily, falls
  /// [dailyAllowed]: sein Viertel; sonst nichts.
  Payout potFor(int day, int rung, {required bool dailyAllowed}) {
    if (rung == highestDefeated + 1 && rung <= PitStage.count) {
      final voll =
          (xp: LadderRewards.xpFor(rung), gold: LadderRewards.goldFor(rung));
      return _minus(voll, partial[rung] ?? _nichts);
    }
    if (!dailyAllowed) return _nichts;
    if (!dailiesOn(day).contains(rung) || isDailyCleared(day, rung)) {
      return _nichts;
    }
    final voll = (
      xp: LadderRewards.dailyXpFor(rung),
      gold: LadderRewards.dailyGoldFor(rung),
    );
    return _minus(voll, dailyPartial[day]?[rung] ?? _nichts);
  }

  /// Trägt einen Lauf ein: was er aus dem Topf gesammelt hat, und ob er
  /// gewonnen wurde. **Mehr als der Topf zählt nie** — was die Welt meldet,
  /// wird auf [potFor] gekappt.
  LadderProgress bookRun(
    int day,
    int rung, {
    required bool won,
    required Payout collected,
    required bool dailyAllowed,
  }) {
    final stand = withDailiesFrozen(day);
    final neu = rung == stand.highestDefeated + 1;
    final topf = stand.potFor(day, rung, dailyAllowed: dailyAllowed);
    final gesammelt = _hoechstens(collected, topf);

    if (neu) {
      if (won) {
        final ohne = Map<int, Payout>.of(stand.partial)..remove(rung);
        return stand.defeat(rung).copyWith(partial: ohne);
      }
      final bisher = stand.partial[rung] ?? _nichts;
      return stand.recordDefeat(rung).copyWith(
        partial: <int, Payout>{
          ...stand.partial,
          rung: _plus(bisher, gesammelt),
        },
      );
    }

    final gezahlt = topf.xp > 0 || topf.gold > 0;
    if (won) {
      if (!gezahlt) return stand;
      final heute = Map<int, Payout>.of(stand.dailyPartial[day] ?? const {})
        ..remove(rung);
      return stand.claimDaily(day, rung).copyWith(
        dailyPartial: <int, Map<int, Payout>>{
          ...stand.dailyPartial,
          day: heute,
        },
      );
    }

    final verloren = stand.recordDefeat(rung);
    if (!gezahlt) return verloren;
    final bisher = stand.dailyPartial[day]?[rung] ?? _nichts;
    return verloren.copyWith(
      dailyPartial: <int, Map<int, Payout>>{
        ...stand.dailyPartial,
        day: <int, Payout>{
          ...?stand.dailyPartial[day],
          rung: _plus(bisher, gesammelt),
        },
      },
    );
  }

  /// Die Dailies des Tages [day] — eingefroren, falls schon geschehen,
  /// sonst so, wie sie jetzt gewürfelt würden.
  List<int> dailiesOn(int day) {
    return dailyPicks[day] ?? PitDailies.forDay(day, highestDefeated);
  }

  /// Ob [rung] am Tag [day] schon als Daily gezahlt hat.
  bool isDailyCleared(int day, int rung) {
    return dailyClears[day]?.contains(rung) ?? false;
  }

  /// Friert die Dailies des Tages [day] ein. Ändert nichts, wenn sie
  /// schon feststehen — oder wenn es noch keine gibt.
  LadderProgress withDailiesFrozen(int day) {
    if (dailyPicks.containsKey(day)) return this;
    final heute = PitDailies.forDay(day, highestDefeated);
    if (heute.isEmpty) return this;
    return copyWith(
      dailyPicks: <int, List<int>>{
        ...dailyPicks,
        day: List<int>.unmodifiable(heute),
      },
    );
  }

  /// Trägt einen Sieg in einem Daily ein. Zahlt nur, wenn [rung] an [day]
  /// zu den eingefrorenen Stufen gehört und heute noch nicht gezahlt hat.
  ///
  /// **Ob an diesem Tag abgehakt wurde, prüft der Aufrufer** — die Reihe
  /// kennt die Gewohnheiten nicht.
  LadderProgress claimDaily(int day, int rung) {
    final heute = withDailiesFrozen(day);
    if (!heute.dailiesOn(day).contains(rung)) return heute;
    if (heute.isDailyCleared(day, rung)) return heute;
    return heute.copyWith(
      dailyClears: <int, Set<int>>{
        ...heute.dailyClears,
        day: Set<int>.unmodifiable(<int>{...?heute.dailyClears[day], rung}),
      },
    );
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
  }) {
    return LadderProgress(
      highestDefeated: highestDefeated ?? this.highestDefeated,
      defeats: defeats ?? this.defeats,
      dailyPicks: dailyPicks ?? this.dailyPicks,
      dailyClears: dailyClears ?? this.dailyClears,
      partial: partial ?? this.partial,
      dailyPartial: dailyPartial ?? this.dailyPartial,
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

  /// Erstsiege plus alle Dailies — gerechnet, nie gezählt.
  ///
  /// Dazu, was aus den Töpfen noch nicht geschaffter Stufen und Dailies
  /// schon gefallen ist (ADR-0041).
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
        if (!isDailyCleared(tag.key, entry.key)) summe += je(entry.value);
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
    );
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
