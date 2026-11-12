/// **Was jemand schon gesehen hat** — für den gelben Punkt (11.11.2026,
/// Frederik: „Immer wo es etwas Neues gibt wird ein gelber Punkt
/// angezeigt“).
///
/// Jedes Neue trägt eine **Marke**: `rueckfrage:20403`, `faehigkeit:mend`,
/// `stueck:<uid>`. Ein Kreis zeigt den Punkt, solange eine seiner Marken
/// nicht in [marken] steht; beim Öffnen kommen alle hinein. Fähigkeiten
/// und Stücke tragen ihn innen zusätzlich, bis sie angetippt sind
/// ([angetippt]).
///
/// **Gespeichert wird nur, was gesehen ist**, und nur, was es noch gibt:
/// Jede Änderung wirft Marken heraus, die nicht mehr vorkommen (ein
/// vergangener Tag, ein verkauftes Stück). Ohne das wüchse die Menge mit
/// jedem Tag.
class NeuGesehen {
  const NeuGesehen({
    this.marken = const <String>{},
    this.angetippt = const <String>{},
  });

  /// Was an einem Kreis gesehen ist.
  final Set<String> marken;

  /// Was innen angetippt ist — Fähigkeiten und Stücke.
  final Set<String> angetippt;

  /// Ein Kreis ist geöffnet: [neu] ist gesehen. Was es nicht mehr gibt
  /// ([alle]), fällt heraus.
  NeuGesehen sieh(Iterable<String> neu, {required Set<String> alle}) {
    return NeuGesehen(
      marken: <String>{...marken.where(alle.contains), ...neu},
      angetippt: angetippt,
    );
  }

  /// [marke] ist innen angetippt. Was es nicht mehr gibt ([alle]), fällt
  /// heraus.
  NeuGesehen tippe(String marke, {required Set<String> alle}) {
    if (angetippt.contains(marke)) return this;
    return NeuGesehen(
      marken: marken,
      angetippt: <String>{...angetippt.where(alle.contains), marke},
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'marken': marken.toList()..sort(),
    'angetippt': angetippt.toList()..sort(),
  };

  /// Nachsichtig wie jedes `fromJson` (ADR-0010): Unbekanntes fällt weg.
  static NeuGesehen fromJson(Object? json) {
    if (json is! Map) return const NeuGesehen();
    Set<String> menge(Object? roh) => <String>{
      if (roh is List)
        for (final e in roh)
          if (e is String) e,
    };
    return NeuGesehen(
      marken: menge(json['marken']),
      angetippt: menge(json['angetippt']),
    );
  }
}
