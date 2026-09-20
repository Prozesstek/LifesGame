import 'level.dart';

/// Die Hallen des Prototyps.
///
/// Hier wird geschrieben, nicht gerechnet — wie `catalog.dart` in
/// `package:gear` oder `theory_graph_content.dart` in `package:theory`.
/// Wer eine Halle ändert, lässt `dart test` laufen: `level_test.dart`
/// geht über **jede** Karte und prüft, dass sie geschlossen ist, genau
/// einen Endgegner hat und jeden Gegner vom Start aus erreichbar lässt.
abstract final class LevelCatalog {
  /// **Die Grube.** Vier Räume, einundzwanzig Nahkämpfer, fünf
  /// Fernkämpfer und ein Endgegner in der hinteren Halle.
  ///
  /// Der Aufbau folgt dem, was der Prototyp beantworten soll: Der erste
  /// Raum hat zwei Gegner, damit der Einstieg nicht überfällt; die
  /// hintere Halle hat acht plus den Endgegner, damit spürbar wird, was
  /// eine Traube ausmacht. Die Gänge sind zwei Felder breit — in einem
  /// einzelnen bleibt man an der ersten Ecke hängen.
  ///
  /// **Die Fernkämpfer stehen bewusst hinten**, nie an der Tür: Sie
  /// sollen aus dem Rücken schiessen, während vorne das Fussvolk kommt.
  /// Einer am Eingang wäre nur ein Nahkämpfer, der nicht herankommt.
  ///
  /// | Zeichen | Bedeutung |
  /// |---|---|
  /// | `#` | Wand |
  /// | `.` | Boden |
  /// | `@` | Start |
  /// | `e` | Fussvolk |
  /// | `s` | Fernkämpfer — steht hinten, wo er Deckung hat |
  /// | `B` | Endgegner |
  static final Level grube = Level.parse('Die Grube', const <String>[
    '##############################################',
    '##############################################',
    '##..............##########..................##',
    '##..............##########..................##',
    '##..........e...##########...e....s....e....##',
    '##..............##########..................##',
    '##...@......................................##',
    '##..........................................##',
    '##..............##########...e....e....e....##',
    '##..........e...##########..................##',
    '##..............##########..................##',
    '##..............##########.....s.....s......##',
    '#######..#################..................##',
    '#######..#####################################',
    '#######..#####################################',
    '#######..#####################################',
    '#######..#####################################',
    '##...............#######....................##',
    '##...............#######....................##',
    '##...............#######....................##',
    '##...e....e...e..#######....e....e....s.....##',
    '##...............#######....................##',
    '##...............#######....................##',
    '##..........................................##',
    '##..........................................##',
    '##...e....e...e..#######....................##',
    '##...............#######....e....s....e.....##',
    '##...............#######....................##',
    '##...............#######....................##',
    '##......e....e...#######.................B..##',
    '##...............#######......e.....e.......##',
    '##...............#######....................##',
    '##############################################',
    '##############################################',
  ]);

  static final List<Level> all = List<Level>.unmodifiable(<Level>[grube]);
}
