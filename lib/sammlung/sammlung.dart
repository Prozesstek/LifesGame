import 'package:abilities/abilities.dart';
import 'package:achievements/achievements.dart';
import 'package:action_combat/action_combat.dart';
import 'package:gear/gear.dart';
import 'package:identity/identity.dart';
import 'package:theory/theory.dart';

import '../action/boss_text.dart';
import '../action/gegner_text.dart';
import '../action/pit_text.dart';

/// Die Reiter der Sammlung (Issues #137, #138), in ihrer Reihenfolge.
enum SammelArt {
  ausruestung('Ausrüstung'),
  faehigkeiten('Fähigkeiten'),
  gegner('Gegner'),
  titel('Titel'),
  seiten('Seiten'),
  errungenschaften('Errungenschaften');

  const SammelArt(this.label);

  final String label;
}

/// Ein Platz in der Sammlung: gesammelt oder ein Fragezeichen.
///
/// **Was er verrät, ist entschieden** (Frederik, 20.10.): Name und Bild
/// stehen erst da, wenn er gesammelt ist; [woher] steht immer und kommt
/// auf Tipp — ein Ziel, auf das man hinspielen kann.
class SammelEintrag {
  const SammelEintrag({
    required this.id,
    required this.name,
    required this.woher,
    required this.stufe,
    this.stufen = 1,
    this.anzahl,
  });

  final String id;
  final String name;

  /// Wo es herkommt, in einem Satz.
  final String woher;

  /// Wie viele Stufen erreicht sind: 0 heißt Fragezeichen. Nur Gegner
  /// haben mehr als eine (`Bestiarium.stufenGegner`).
  final int stufe;
  final int stufen;

  /// Wie oft besiegt — nur bei Gegnern.
  final int? anzahl;

  bool get gesammelt => stufe > 0;
}

/// Wie weit ein Reiter gefüllt ist: erreichte Stufen von allen.
class SammelStand {
  const SammelStand(this.erreicht, this.gesamt);

  /// Zählt die Stufen aller [eintraege] zusammen. So bringt bei den
  /// Gegnern auch der zehnte und hundertste Sieg Prozente, nicht nur der
  /// erste.
  factory SammelStand.aus(List<SammelEintrag> eintraege) {
    var erreicht = 0;
    var gesamt = 0;
    for (final e in eintraege) {
      erreicht += e.stufe;
      gesamt += e.stufen;
    }
    return SammelStand(erreicht, gesamt);
  }

  final int erreicht;
  final int gesamt;

  /// Abgerundet: 100 % erst, wenn wirklich alles da ist.
  int get prozent => gesamt == 0 ? 0 : (erreicht * 100) ~/ gesamt;

  SammelStand operator +(SammelStand other) =>
      SammelStand(erreicht + other.erreicht, gesamt + other.gesamt);
}

/// Die Einträge der Sammlung — **reine Rechnung**, was hereinkommt, ist
/// schon abgeleitet (`sammlung_provider.dart`). Eine Stelle für jede
/// Frage „woher kommt das?“.
abstract final class Sammlung {
  /// Alle 60 Stücke; gesammelt ist, was je besessen war, auch verkauft.
  static List<SammelEintrag> ausruestung(Set<String> jeBesessen) {
    return <SammelEintrag>[
      for (final item in GearCatalog.all)
        SammelEintrag(
          id: item.id,
          name: item.name,
          woher: woherStueck(item),
          stufe: jeBesessen.contains(item.id) ? 1 : 0,
        ),
    ];
  }

  /// Woher ein Stück kommt: Laden und Beute, ab welcher Ebene, und zu
  /// welchem Set es gehört.
  static String woherStueck(GearItem item) {
    final ab = switch (item.rarity) {
      GearRarity.epic => ', ab Ebene ${GearGates.epicRung}',
      GearRarity.legendary => ', ab Ebene ${GearGates.legendaryRung}',
      _ => '',
    };
    final set = GearSets.byId(item.setId);
    final teil = set == null ? '' : ' — Teil von „${set.name}“';
    return 'Im Laden und als Beute$ab$teil.';
  }

  /// Die wählbaren Fähigkeiten und die Ultimates; die Waffenzüge kommen
  /// mit ihrer Waffe und stehen bei der Ausrüstung.
  static List<SammelEintrag> faehigkeiten(Set<String> gelernt) {
    return <SammelEintrag>[
      for (final ability in <Ability>[
        ...AbilityCatalog.choosable,
        ...AbilityCatalog.ultimates,
      ])
        SammelEintrag(
          id: ability.moveId,
          name: pitNameOf(ability.moveId) ?? ability.moveId,
          woher: '${ability.requirement}.',
          stufe: gelernt.contains(ability.moveId) ? 1 : 0,
        ),
    ];
  }

  /// Die zehn Arten und die vier Wächter, in Stufen.
  static List<SammelEintrag> gegner(Bestiarium b) {
    return <SammelEintrag>[
      for (final art in Bestiarium.arten)
        SammelEintrag(
          id: art.name,
          name: GegnerText.nameOf(art),
          woher: 'Lebt unten in der Grube.',
          stufe: b.stufeVon(art),
          stufen: Bestiarium.stufenGegner.length,
          anzahl: b.besiegt(art),
        ),
      for (final waechter in BossKind.values)
        SammelEintrag(
          id: 'waechter-${waechter.name}',
          name: BossText.nameOf(waechter),
          woher: 'Wartet am Ende einer Grube.',
          stufe: b.stufeVonWaechter(waechter),
          stufen: Bestiarium.stufenWaechter.length,
          anzahl: b.besiegtWaechter(waechter),
        ),
    ];
  }

  /// Ab wie vielen Siegen [eintrag] die nächste Stufe hat — null, wenn
  /// er voll ist oder kein Gegner.
  static int? naechsteSchwelle(SammelEintrag eintrag) {
    if (eintrag.anzahl == null) return null;
    final stufen = eintrag.id.startsWith('waechter-')
        ? Bestiarium.stufenWaechter
        : Bestiarium.stufenGegner;
    if (eintrag.stufe >= stufen.length) return null;
    return stufen[eintrag.stufe];
  }

  /// Die dreizehn Titel; woher sagt die Errungenschaft, die ihn vergibt.
  static List<SammelEintrag> titel(Set<String> verdient) {
    return <SammelEintrag>[
      for (final titel in TitleCatalog.all)
        SammelEintrag(
          id: titel.id,
          name: titel.label,
          woher: _woherTitel(titel.id),
          stufe: verdient.contains(titel.id) ? 1 : 0,
        ),
    ];
  }

  static String _woherTitel(String titelId) {
    for (final a in AchievementCatalog.all) {
      if (a.titleId != titelId) continue;
      // Eine Entdeckung verrät sich nicht (ADR-0033) — auch hier nicht.
      return a.isDiscovery
          ? 'Eine Entdeckung — sie verrät sich nicht.'
          : '„${a.name}“: ${a.requirement}.';
    }
    return 'Eine Errungenschaft.';
  }

  /// Alle Seiten im Baum; woher sagt, unter welchem Gebiet sie hängt.
  static List<SammelEintrag> seiten(TheoryGraph graph, TheoryProgress p) {
    return <SammelEintrag>[
      for (final node in graph.nodes)
        SammelEintrag(
          id: node.id,
          name: node.name,
          woher: _woherSeite(graph, node),
          stufe: p.isPassed(node.lesson.id) ? 1 : 0,
        ),
    ];
  }

  static String _woherSeite(TheoryGraph graph, TheoryNode node) {
    if (node.parentIds.isEmpty) return 'Eine Wurzel des Wissensbaums.';
    final weg = <String>[];
    var eltern = graph.nodeById(node.parentIds.first);
    while (eltern != null) {
      weg.insert(0, eltern.name);
      eltern = eltern.parentIds.isEmpty
          ? null
          : graph.nodeById(eltern.parentIds.first);
    }
    return 'Im Wissensbaum unter ${weg.join(' › ')}.';
  }
}
