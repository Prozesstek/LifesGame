import 'dart:math' as math;
import 'dart:ui';

import 'package:theory/theory.dart';

/// Wo die Knoten **einer Ebene** sitzen.
///
/// **Reine Rechnung, kein Widget.** Die Anordnung ist der Teil, der
/// schiefgehen kann — überlappende Knoten, ein Kind außerhalb der
/// Fläche, ein Startknoten ohne Platz. Als Funktion lässt sich das
/// prüfen, ohne etwas zu rendern.
///
/// **Warum nur eine Ebene, und warum nach oben** ([ADR-0026]).
/// Bis dahin lagen alle vier Gebiete als Bänder auf einer gemeinsamen
/// Zeichenfläche, verschiebbar und zoombar. Das war schon bei
/// vierundzwanzig Knoten eng und wäre mit jedem weiteren schlechter
/// geworden. Sichtbar ist jetzt der Startknoten und genau eine Ebene
/// darüber — das bleibt gleich gut, egal wie tief der Baum wird.
///
/// Nach **oben**, weil der Startknoten dort liegen soll, wo der Daumen
/// ist, und weil Fortschritt nach oben die Richtung ist, in der man ihn
/// ohnehin denkt.
class TreeLayout {
  const TreeLayout({
    required this.focusId,
    required this.positions,
    required this.rows,
    required this.size,
  });

  /// Baut die Anordnung um [focusId] herum.
  ///
  /// [width] ist die verfügbare Breite und keine feste Zahl mehr: Ohne
  /// `InteractiveViewer` gibt es keine Fläche, die breiter sein darf als
  /// das Gerät. [minHeight] ist die Höhe des Fensters — die Fläche wird
  /// nie kleiner, damit der Startknoten auch bei einer einzigen Reihe
  /// unten sitzt und nicht in der Mitte schwebt.
  factory TreeLayout.of(
    TheoryGraph graph,
    String focusId, {
    required double width,
    required double minHeight,
  }) {
    final kinder = graph.childrenOf(focusId).map((n) => n.id).toList();
    final rows = _rowsFor(kinder, width);

    final height = math.max(minHeight, _heightFor(rows.length));
    final focusY = height - focusInsetBottom;

    final positions = <String, Offset>{focusId: Offset(width / 2, focusY)};

    for (var r = 0; r < rows.length; r++) {
      final reiheY = focusY - actionBand - rowHeight * r;
      for (var i = 0; i < rows[r].length; i++) {
        positions[rows[r][i]] = _slotOffset(i, rows[r].length, width, reiheY);
      }
    }

    return TreeLayout(
      focusId: focusId,
      positions: positions,
      rows: rows,
      size: Size(width, height),
    );
  }

  /// Wie breit ein Knoten mindestens sein darf.
  ///
  /// Daraus folgt, wie viele in eine Reihe passen — nicht umgekehrt. Eine
  /// feste Zahl („immer drei") würde auf einem schmalen Gerät Namen
  /// abschneiden und auf einem breiten Platz verschenken.
  static const double minSlotWidth = 116;

  /// Wie weit über dem Startknoten die nächste Ebene beginnt.
  ///
  /// Der Abstand ist größer als zwischen zwei Reihen, weil dazwischen der
  /// Handlungsknopf sitzt — „über dem angetippten Knoten" (ADR-0026).
  /// Wie viel davon der Knopf haben darf, sagt [panelMaxHeight]; wer
  /// diese Zahl ändert, ändert beides.
  static const double actionBand = 260;

  /// Wie weit eine Blase unter ihrem Mittelpunkt endet.
  ///
  /// Kreis, Abstand und zwei Zeilen Name. Die Anordnung gibt nur den
  /// Mittelpunkt zurück — ohne diese Zahl wüsste niemand, wo ein Knoten
  /// tatsächlich aufhört, und der Knopf legte sich darüber.
  static const double labelDrop = 58;

  /// Luft zwischen Handlungsknopf und Startknoten.
  static const double panelGap = 12;

  /// Wie hoch der Handlungsknopf höchstens sein darf.
  ///
  /// **Abgeleitet, nicht gesetzt.** Er sitzt im Band zwischen Startknoten
  /// und erster Kinderreihe; was dort nach Kreis, Namen und Luft übrig
  /// bleibt, ist sein Platz. Wird er höher, verdeckt er die Kinder — und
  /// zwar nicht nur im Bild: Ein Druck auf ein Kind käme dann gar nicht
  /// mehr an.
  static const double panelMaxHeight =
      actionBand - focusRadius - panelGap - arcLift - labelDrop - 8;

  /// Abstand zweier Kinderreihen.
  static const double rowHeight = 132;

  /// Wie weit über dem unteren Rand der Startknoten sitzt.
  static const double focusInsetBottom = 96;

  /// Luft über der obersten Reihe.
  static const double topPadding = 76;

  /// Wie stark sich der Bogen der Kinder hebt.
  static const double arcLift = 20;

  /// Radius eines gewöhnlichen Knotens.
  static const double nodeRadius = 26;

  /// Radius des Startknotens. Größer, weil er der Ort ist, an dem man
  /// gerade steht — und weil ein zweiter Druck darauf ihn öffnet.
  static const double focusRadius = 34;

  /// Der Knoten, um den herum angeordnet wurde — unten in der Mitte.
  final String focusId;

  final Map<String, Offset> positions;

  /// Die Kinder, in Reihen von unten nach oben. `rows.first` liegt am
  /// nächsten am Startknoten.
  final List<List<String>> rows;

  final Size size;

  Offset? operator [](String nodeId) => positions[nodeId];

  /// Wie viele Knoten bei [width] in eine Reihe passen.
  static int maxPerRow(double width) {
    return math.max(2, (width / minSlotWidth).floor());
  }

  static double _heightFor(int rowCount) {
    final reihen = rowCount == 0 ? 0.0 : rowHeight * (rowCount - 1);
    return focusInsetBottom + actionBand + reihen + topPadding;
  }

  /// Verteilt die Kinder auf Reihen.
  ///
  /// **Die untere Reihe bekommt den Rest**, nicht die obere. Sie liegt am
  /// nächsten am Startknoten und ist die, die man zuerst ansieht; eine
  /// volle Reihe unten und eine dünne darüber liest sich als Baum, andersherum
  /// als Versehen.
  static List<List<String>> _rowsFor(List<String> ids, double width) {
    if (ids.isEmpty) return const <List<String>>[];

    final proReihe = maxPerRow(width);
    final anzahl = (ids.length / proReihe).ceil();
    final rows = <List<String>>[];

    var rest = ids.length;
    var index = 0;
    for (var r = 0; r < anzahl; r++) {
      final nimm = (rest / (anzahl - r)).ceil();
      rows.add(List<String>.unmodifiable(ids.sublist(index, index + nimm)));
      index += nimm;
      rest -= nimm;
    }

    return List<List<String>>.unmodifiable(rows);
  }

  static Offset _slotOffset(int index, int count, double width, double rowY) {
    final slot = width / count;
    final x = slot * index + slot / 2;

    // Die äußeren Kinder rutschen zum Startknoten hin, die mittleren
    // stehen höher — das ergibt den Bogen. Reine Kosmetik, aber er
    // unterscheidet den Baum von einer Tabelle.
    final mitte = (count - 1) / 2;
    final abstand = mitte == 0 ? 0.0 : (index - mitte).abs() / mitte;

    return Offset(x, rowY + arcLift * abstand);
  }
}
