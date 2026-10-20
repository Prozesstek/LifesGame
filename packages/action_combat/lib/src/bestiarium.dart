import 'entity.dart';

/// Wie oft jemand welche Art Gegner und welchen Wächter besiegt hat —
/// die Gegner der Sammlung (Issue #138).
///
/// **Eine Zahl je Art, die nur steigt**, wie die Niederlagen je Stufe
/// (`LadderProgress.defeats`). Sie wirkt **nicht rückwirkend**: Was vor
/// ihrem Einbau fiel, steht nirgends, und jeder Stand fängt bei null an.
///
/// Gesammelt wird in Stufen (Frederik: „1 mal besiegt, 10 mal besiegt
/// etc.“): Eine Art ist mit dem ersten Sieg da, und jede weitere Stufe
/// ist ein Stern mehr.
class Bestiarium {
  const Bestiarium._(this._gegner, this._waechter);

  const Bestiarium.leer()
      : _gegner = const <EnemyKind, int>{},
        _waechter = const <BossKind, int>{};

  final Map<EnemyKind, int> _gegner;
  final Map<BossKind, int> _waechter;

  /// Die Arten, die man sammeln kann. **Ohne den Schleimling**: Er steht
  /// in keinem Raum und entsteht nur aus einem Schleim (ADR-0063) — wer
  /// den Schleim hat, hat ihn gesehen. Der Wächter steht als seine vier
  /// [BossKind]s da, nicht als [EnemyKind.endgegner].
  static const List<EnemyKind> arten = <EnemyKind>[
    EnemyKind.fussvolk,
    EnemyKind.schuetze,
    EnemyKind.flink,
    EnemyKind.flatterer,
    EnemyKind.brocken,
    EnemyKind.schleim,
    EnemyKind.grimlock,
    EnemyKind.kreischer,
    EnemyKind.heiler,
    EnemyKind.strahler,
  ];

  /// Ab wie vielen Siegen eine Art die nächste Stufe hat.
  static const List<int> stufenGegner = <int>[1, 10, 100];

  /// Dasselbe für einen Wächter. Er fällt einmal je Lauf, ein Gegner
  /// zwanzigmal — deshalb kleinere Schritte.
  static const List<int> stufenWaechter = <int>[1, 5, 25];

  int besiegt(EnemyKind art) => _gegner[art] ?? 0;

  int besiegtWaechter(BossKind waechter) => _waechter[waechter] ?? 0;

  /// Welche Stufe [anzahl] Siege erreichen: 0 heißt noch nicht gesammelt.
  static int stufe(int anzahl, List<int> stufen) {
    var erreicht = 0;
    for (final schwelle in stufen) {
      if (anzahl >= schwelle) erreicht++;
    }
    return erreicht;
  }

  int stufeVon(EnemyKind art) => stufe(besiegt(art), stufenGegner);

  int stufeVonWaechter(BossKind waechter) =>
      stufe(besiegtWaechter(waechter), stufenWaechter);

  /// Trägt ein, was ein Lauf gefällt hat.
  ///
  /// Was nicht gesammelt wird ([EnemyKind.keiner], der Schleimling, der
  /// Wächter als [EnemyKind.endgegner]), fällt still heraus — der Wächter
  /// kommt als [waechter].
  Bestiarium mit({
    Map<EnemyKind, int> gegner = const <EnemyKind, int>{},
    BossKind? waechter,
  }) {
    final neuGegner = Map<EnemyKind, int>.of(_gegner);
    for (final eintrag in gegner.entries) {
      if (!arten.contains(eintrag.key) || eintrag.value <= 0) continue;
      neuGegner[eintrag.key] = besiegt(eintrag.key) + eintrag.value;
    }
    final neuWaechter = Map<BossKind, int>.of(_waechter);
    if (waechter != null) {
      neuWaechter[waechter] = besiegtWaechter(waechter) + 1;
    }
    return Bestiarium._(
      Map<EnemyKind, int>.unmodifiable(neuGegner),
      Map<BossKind, int>.unmodifiable(neuWaechter),
    );
  }

  bool get istLeer => _gegner.isEmpty && _waechter.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        if (_gegner.isNotEmpty)
          'gegner': <String, Object?>{
            for (final eintrag in _gegner.entries)
              eintrag.key.name: eintrag.value,
          },
        if (_waechter.isNotEmpty)
          'waechter': <String, Object?>{
            for (final eintrag in _waechter.entries)
              eintrag.key.name: eintrag.value,
          },
      };

  /// Liest nachsichtig (ADR-0010): Eine unbekannte Art oder eine Zahl,
  /// die keine ist, fällt heraus.
  factory Bestiarium.fromJson(Object? json) {
    if (json is! Map) return const Bestiarium.leer();
    final gegner = <EnemyKind, int>{};
    final rohGegner = json['gegner'];
    if (rohGegner is Map) {
      for (final eintrag in rohGegner.entries) {
        final art = EnemyKind.values.asNameMap()['${eintrag.key}'];
        final zahl = eintrag.value;
        if (art == null || !arten.contains(art)) continue;
        if (zahl is! int || zahl <= 0) continue;
        gegner[art] = zahl;
      }
    }
    final waechter = <BossKind, int>{};
    final rohWaechter = json['waechter'];
    if (rohWaechter is Map) {
      for (final eintrag in rohWaechter.entries) {
        final art = BossKind.values.asNameMap()['${eintrag.key}'];
        final zahl = eintrag.value;
        if (art == null || zahl is! int || zahl <= 0) continue;
        waechter[art] = zahl;
      }
    }
    return Bestiarium._(
      Map<EnemyKind, int>.unmodifiable(gegner),
      Map<BossKind, int>.unmodifiable(waechter),
    );
  }
}
