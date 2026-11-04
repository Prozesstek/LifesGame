// Das Zeichen des Kreises „Gewohnheiten“: eine Quest-Rolle mit Haken.
// Gezeichnet mit pxl (github.com/crsolver/claude-pxl) auf 64 × 64 wie
// jedes Bild im Projekt; abgelegt als assets/UI/Kreis_Gewohnheiten.png in
// 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/kreis_gewohnheiten.px.js --scale 4
pal({
  k: "#2a1b24", // Umriss, wie bei Raven
  p: "#f6e6c0", P: "#e8cc94", q: "#cda366", Q: "#9a6e3c", // Pergament
  v: "#c4864a", w: "#8a5128", W: "#552f17",               // Holz der Knäufe
  i: "#6b4f2e",                                             // Tinte
  h: "#d2f58a", g: "#6abe30", G: "#2f7a2a",                 // Haken
})
ramps("kQqPp", "kWwv", "kGgh")

// Eine Rolle quer: Pergament als Zylinder — oben Licht, unten Schatten —,
// an jedem Ende ein runder Holzknauf.
sprite("_rolle", { w: 62, h: 11 },
  rect(5, 0, 52, 11, "P"),
  rect(5, 2, 52, 3, "p"),
  rect(5, 7, 52, 2, "q"),
  rect(5, 9, 52, 2, "Q"),
  // Die Kante, an der das Blatt aus der Rolle kommt.
  vline(5, 0, 11, "q"), vline(56, 0, 11, "q"),
  // Knäufe: rund, Licht oben links.
  ellipse(3, 5, 3, 4, "w"), ellipse(58, 5, 3, 4, "w"),
  rect(1, 2, 2, 2, "v"), rect(57, 2, 2, 2, "v"),
  hline(1, 8, 5, "W"), hline(56, 8, 5, "W"),
  px(3, 9, "W"), px(58, 9, "W"))

// Eine Aufgabe: Kästchen und eine Zeile Tinte, zwei Pixel stark.
sprite("_aufgabe", { w: 32, h: 7 },
  box(0, 0, 7, 7, "i"), box(1, 1, 5, 5, "i"),
  rect(11, 2, 21, 2, "i"))

sprite("kreis_gewohnheiten", { w: 62, h: 62, outline: "k" },
  layer("rolle", { y: 1 },
    // Das Blatt zwischen den Rollen, leicht gewölbt.
    rect(8, 9, 46, 42, "p"),
    rect(8, 9, 2, 42, "P"), rect(52, 9, 2, 42, "q"),
    // Schatten unter der oberen Rolle, nach unten weich.
    rect(10, 10, 42, 2, "q"), dither(10, 12, 42, 2, "p", "P", 0.5),
    stamp("_rolle", 0, 0),
    stamp("_rolle", 0, 49),
    // Drei Aufgaben, die letzte kürzer.
    stamp("_aufgabe", 14, 17),
    stamp("_aufgabe", 14, 27),
    box(14, 37, 7, 7, "i"), box(15, 38, 5, 5, "i"), rect(25, 39, 12, 2, "i"),
    // Der Haken über der rechten unteren Ecke, mit eigenem Rand:
    // erst dunkel und breit, dann grün, dann Licht oben, Schatten unten.
    line(30, 40, 38, 48, "k", 11), line(38, 48, 57, 25, "k", 11),
    line(30, 40, 38, 48, "g", 7), line(38, 48, 57, 25, "g", 7),
    line(30, 43, 37, 50, "G", 2), line(39, 50, 58, 28, "G", 2),
    line(30, 38, 37, 45, "h", 2), line(38, 45, 55, 25, "h", 2)))
