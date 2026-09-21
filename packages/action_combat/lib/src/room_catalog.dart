/// Die Räume, aus denen die Grube zusammengesteckt wird (ADR-0039).
///
/// Hier wird geschrieben, nicht gerechnet — wie `level_catalog.dart`.
/// Jeder Raum ist genau [width] × [height] Felder gross und kennt dieselben
/// Zeichen wie eine Halle:
///
/// | Zeichen | Bedeutung |
/// |---|---|
/// | `#` | Wand |
/// | `.` | Boden |
/// | `e` | Fussvolk |
/// | `s` | Fernkämpfer |
/// | `B` | Endgegner — nur in [bossRooms] |
/// | `k` | Kobold — schnell, schwach, im Rudel |
/// | `t` | Troll — gross, zäh; setzt meist der Zufallsbau |
///
/// **Zwei Regeln, die ein Raum einhalten muss**, und die
/// `level_builder_test.dart` über hunderte gebaute Gruben prüft:
///
/// 1. Die Mitte (Spalten 6–7, Zeilen 4–5) ist die Stelle, durch die die
///    Gänge laufen. Wände dort werden beim Bauen aufgebrochen, Gegner
///    bleiben stehen.
/// 2. Jeder Gegner muss von der Mitte aus erreichbar sein. Ein Raum mit
///    einem eingemauerten Schützen erzeugt eine Grube, die sich nicht
///    räumen lässt.
abstract final class RoomCatalog {
  static const int width = 14;
  static const int height = 10;

  /// Der Raum, in dem der Held anfängt. Ohne Gegner: Die ersten Sekunden
  /// gehören dem Zurechtfinden.
  static const List<String> startRoom = <String>[
    '..............',
    '..............',
    '..##......##..',
    '..............',
    '..............',
    '..............',
    '..............',
    '..##......##..',
    '..............',
    '..............',
  ];

  /// Die Räume dazwischen. Jeder Lauf zieht daraus, mit Zurücklegen.
  static const List<List<String>> rooms = <List<String>>[
    // Die Halle: offen, verteilt — der Raum, in dem man lernt.
    <String>[
      '..............',
      '..e........e..',
      '..............',
      '.....e..e.....',
      '..............',
      '..............',
      '.....e..k.....',
      '..............',
      '..e........s..',
      '..............',
    ],
    // Die Säulen: Deckung für beide Seiten.
    <String>[
      '..............',
      '..##..e...##..',
      '..##......##..',
      '......s.......',
      '..e........e..',
      '..............',
      '..##..e...##..',
      '..##......##..',
      '..............',
      '.......e......',
    ],
    // Das Schützennest: zwei Mauern, hinter denen geschossen wird.
    <String>[
      '..............',
      '.s..........s.',
      '....######....',
      '..............',
      '..e...e..e....',
      '..............',
      '....######....',
      '..............',
      '.e..........e.',
      '..............',
    ],
    // Das Kreuz: die Ecken sind Fels, gekämpft wird in der Mitte.
    <String>[
      '####......####',
      '###..e.....###',
      '##..........##',
      '...e......e...',
      '......s.......',
      '..............',
      '...e......e...',
      '##..........##',
      '###.....e..###',
      '####......####',
    ],
    // Der Ring: ein Schütze in einer Mauer mit zwei Durchgängen.
    <String>[
      '..............',
      '.e..........e.',
      '...###..###...',
      '...#......#...',
      '.......s......',
      '...#......#...',
      '...###..###...',
      '.e..........e.',
      '..............',
      '......e.......',
    ],
    // Der Engpass: zwei Hälften, die sich nur in der Mitte berühren.
    <String>[
      '......##......',
      '..e...##...e..',
      '......##......',
      '..............',
      '####..e...####',
      '####......####',
      '..............',
      '......##......',
      '..s...##...e..',
      '......##......',
    ],
    // Das Nest: ein Rudel Kobolde, das von allen Seiten kommt. Wer hier
    // wegläuft, wird eingeholt.
    <String>[
      '..............',
      '.k..........k.',
      '..............',
      '....k....k....',
      '..............',
      '..............',
      '....k....k....',
      '..............',
      '.k..........k.',
      '..............',
    ],
    // Die Höhle des Trolls: ein Brocken, zwei Kobolde als Vorhut. Der
    // eine Raum, in dem er fest steht — sonst setzt ihn der Zufallsbau.
    <String>[
      '##............',
      '#.....k.......',
      '..............',
      '......##......',
      '..k...##...t..',
      '..............',
      '......##......',
      '..............',
      '#......e......',
      '##............',
    ],
    // Die Wachstube: dicht gedrängt, der Raum für den Rundumschlag.
    <String>[
      '..............',
      '..e.e....e.e..',
      '..............',
      '..............',
      '...e..s...e...',
      '..............',
      '..............',
      '..e.e....e.e..',
      '..............',
      '..............',
    ],
  ];

  /// Die Räume des Wächters. Immer der letzte Raum eines Laufs.
  static const List<List<String>> bossRooms = <List<String>>[
    // Die Arena: vier Leibwächter, vier Säulen.
    <String>[
      '..............',
      '.#..........#.',
      '..............',
      '....e....e....',
      '......B.......',
      '..............',
      '....e....e....',
      '..............',
      '.#..........#.',
      '..............',
    ],
    // Der Thronsaal: Schützen an den Wänden, der Wächter hinten.
    <String>[
      '.s..........s.',
      '..............',
      '..##......##..',
      '..............',
      '.......B......',
      '..............',
      '..##......##..',
      '..e........e..',
      '..............',
      '.s..........s.',
    ],
  ];

  /// Alle Räume, auch Start und Wächter — für die Prüfung der Form.
  static List<List<String>> get all => <List<String>>[
        startRoom,
        ...rooms,
        ...bossRooms,
      ];
}
