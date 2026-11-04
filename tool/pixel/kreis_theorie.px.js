// Das Zeichen des Kreises „Theorie“: ein Foliant mit dem Talentbaum vorn.
// Gezeichnet mit pxl (github.com/crsolver/claude-pxl) auf 64 × 64; abgelegt
// als assets/UI/Buch.png in 256 × 256 (4×, hart).
pal({
  k: "#2a1b24",                                           // Umriss, wie bei Raven
  R: "#4a1f1a", r: "#7a3324", q: "#a0482e", Q: "#c4683e", // Leder, dunkel -> hell
  B: "#341611",                                           // Rücken, tiefer
  P: "#c9a46a", p: "#efdcae", n: "#fff4d6",               // Seiten
  Y: "#7a5212", y: "#c8952c", o: "#f2cf5c", O: "#fff2b0", // Gold
  g: "#3f8a3a",                                           // Lesebändchen
})
ramps("kBRrqQ", "kPpn", "kYyoO")

sprite("kreis_theorie", { w: 62, h: 62, outline: "k" },
  // Mittig im Kreis: Der Rücken links wiegt mehr als der Seitenblock
  // rechts, deshalb alles um 3 nach rechts und 1 nach oben.
  layer("buch", { x: 3, y: -1 },
  // Der hintere Deckel: ein schmaler Rand unter und rechts vom Buchblock,
  // links läuft er in den Rücken.
  rect(8, 7, 44, 51, "R"),
  // Der Buchblock. Die Blätter liegen parallel zum Deckel: rechts sieht
  // man ihre Kanten als senkrechte Linien, unten als waagerechte. Direkt
  // unter dem vorderen Deckel liegt Schatten.
  rect(11, 7, 39, 49, "p"),
  vline(47, 7, 48, "P"), vline(48, 7, 48, "n"), vline(49, 7, 48, "p"),
  hline(11, 53, 38, "P"), hline(11, 54, 38, "n"), hline(11, 55, 38, "p"),
  px(47, 53, "P"), px(48, 54, "n"), px(49, 55, "p"),
  // Der vordere Deckel.
  rect(10, 4, 37, 49, "r"),
  rect(10, 4, 37, 2, "q"), rect(10, 4, 2, 49, "q"),     // Licht oben links
  rect(10, 51, 37, 2, "R"), rect(45, 4, 2, 49, "R"),    // Schatten unten rechts
  // Prägung: ein Rahmen, eine Linie nach innen.
  box(14, 8, 29, 41, "R"),
  box(15, 9, 27, 39, "q"),
  // Der Rücken links, mit drei Bünden.
  // Er reicht bis unter den Buchblock und rundet sich dort in den
  // hinteren Deckel.
  rect(5, 4, 6, 53, "B"), vline(6, 5, 51, "R"), px(5, 56, "_"),
  ...[12, 28, 44].map((y) => rect(5, y, 6, 2, "q")),
  ...[12, 28, 44].map((y) => hline(5, y + 2, 6, "k")),
  // Goldene Ecken.
  poly([47, 4, 39, 4, 47, 12], "y"), line(41, 5, 46, 10, "o"),
  poly([47, 53, 39, 53, 47, 45], "y"), line(46, 47, 42, 51, "Y"),
  poly([10, 4, 16, 4, 10, 10], "y"), px(11, 5, "o"),
  poly([10, 53, 16, 53, 10, 47], "Y"),
  // Das Wappen: der Talentbaum in Gold.
  // Krone aus drei Laubballen, dunkle Fugen dazwischen.
  circ(22, 23, 5, "Y"), circ(34, 23, 5, "Y"), circ(28, 17, 6, "Y"),
  circ(22, 22, 4, "y"), circ(34, 22, 4, "y"), circ(28, 16, 5, "y"),
  circ(21, 21, 2, "o"), circ(33, 21, 2, "o"), circ(27, 15, 3, "o"),
  px(26, 13, "O"), px(27, 13, "O"), px(26, 14, "O"), px(20, 20, "O"), px(32, 20, "O"),
  // Stamm mit zwei Ästen in die Krone.
  rect(27, 26, 3, 12, "y"), vline(27, 26, 12, "o"),
  line(27, 29, 23, 25, "y", 2), line(29, 29, 33, 25, "Y", 2),
  // Wurzeln greifen aus.
  line(27, 37, 21, 42, "y", 2), line(29, 37, 35, 42, "Y", 2),
  line(28, 38, 28, 42, "y", 2),
  hline(20, 43, 17, "Y"),
  // Der Riemen mit der Schließe, rechts über den Rand.
  rect(39, 27, 12, 6, "B"), hline(39, 27, 12, "R"),
  rect(38, 26, 6, 8, "y"), rect(39, 27, 4, 6, "Y"), rect(40, 28, 2, 4, "R"),
  px(38, 26, "O"), vline(38, 27, 6, "o"),
  // Das Lesebändchen hängt unten heraus.
  rect(34, 53, 3, 7, "g"), px(35, 59, "_"),
))
