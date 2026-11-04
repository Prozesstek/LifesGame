// Der Nachtmantel, die Rüstung des Vampirsets, passend zur Fledermaushaube:
// vorn ein Harnisch, hinten zwei Flügel, die als Mantel fallen.
// Gezeichnet mit pxl auf 64 × 64, nur die linke Hälfte, `mx` spiegelt sie.
// Abgelegt in 256 × 256 mit tool/pixel/vergroessern.js:
//   node <pxl>/bin/pxl.js build tool/pixel/nachtmantel.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/nachtmantel.png assets/Ruestung/Nachtmantel.png
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/charakter_nachtmantel.png assets/character/Charakter_Nachtmantel.png
pal({
  k: "#170e1e",                                 // Umriss
  d: "#1f1730", n: "#2e2340", N: "#4f3d6e",     // Nacht
  l: "#8672ad", L: "#c6b8e0",                   // Licht auf dem Metall
  m: "#4a1233", b: "#a8305f", B: "#d65c8f",     // Blut
  e: "#ffb3cf",                                 // der Stein, der glüht
  s: "#e8e4ef", S: "#a9a3bd",                   // Krallen
})
ramps("kdnNlL", "kmbBe", "kSs")

// Der Mantel: Flügelhaut hinter dem Harnisch, unten ausgezackt wie an
// der Haube, jedes Feld oben heller.
const mantel = () => [
  poly([12, 10, 3, 14, 0, 26, 1, 50, 6, 44, 9, 58, 14, 49, 18, 61, 24, 50, 24, 12], "m"),
  poly([12, 18, 4, 18, 2, 30, 2, 44, 7, 38], "b"),
  poly([13, 26, 8, 38, 9, 50, 13, 42], "b"),
  poly([15, 32, 14, 42, 17, 54, 19, 44], "b"),
  poly([10, 19, 5, 20, 4, 27, 7, 27], "B"),
  line(12, 16, 2, 46, "N"), line(13, 22, 9, 56, "N"), line(15, 28, 18, 59, "N"),
]

// Der Harnisch: schmal in der Taille, Licht von oben links.
const harnisch = () => [
  poly([12, 12, 31, 12, 31, 56, 24, 54, 19, 42, 14, 28], "n"),
  poly([12, 14, 15, 14, 18, 28, 22, 42, 26, 54, 24, 54, 19, 42, 14, 28], "d"),
  // Die Brust, oben im Licht; das Band fällt zur Mitte, wie an der Haube.
  poly([15, 13, 31, 13, 31, 30, 17, 23], "N"),
  line(16, 23, 29, 29, "L"),
  line(16, 24, 29, 30, "d"),
  line(18, 16, 24, 15, "l", 2),
  // Die Naht zwischen den Brustplatten.
  vline(30, 14, 15, "n"),
]

// Die Fledermaus auf dem Bauch: klarer Umriss, ein Stein als Herz.
const zeichen = () => [
  poly([31, 36, 29, 36, 28, 32, 26, 35, 24, 35, 18, 31, 20, 41, 23, 38, 25, 43, 27, 40, 29, 45, 31, 47], "k"),
  poly([31, 37, 29, 37, 28, 34, 27, 36, 24, 36, 20, 33, 21, 38, 23, 36, 25, 41, 27, 38, 29, 43, 31, 45], "b"),
  line(21, 34, 24, 36, "B"), line(25, 37, 28, 37, "B"),
  poly([31, 38, 29, 40, 31, 42], "e"),
]

// Der Bauch: drei Schienen, die zur Mitte hin abfallen.
const schienen = () => [
  line(23, 47, 30, 49, "k"), line(23, 48, 30, 50, "N"),
  line(25, 51, 30, 53, "k"), line(25, 52, 30, 54, "N"),
]

// Der Kragen: steht hoch wie die Ohren der Haube, innen blutrot.
const kragen = () => [
  poly([12, 12, 13, 0, 24, 6, 31, 18, 31, 13, 22, 13], "n"),
  poly([15, 11, 15, 4, 22, 8, 27, 13], "m"),
  poly([17, 11, 17, 7, 21, 10, 23, 12], "b"),
  line(13, 10, 14, 1, "l"),
  poly([23, 8, 31, 8, 31, 18], "m"),
]

// Die Schulter: eine gefaltete Flügelkuppe mit Kralle.
const schulter = () => [
  ellipse(9, 16, 8, 8, "n"),
  clip((x, y) => y < 16, ellipse(9, 16, 7, 7, "N")),
  line(4, 13, 8, 10, "l", 2),
  line(2, 19, 15, 19, "d"),
  line(3, 21, 14, 21, "d"),
  poly([3, 12, 1, 2, 8, 10], "s"),
  line(4, 10, 2, 4, "S"),
]

sprite("nachtmantel", { w: 62, h: 62, mx: true, outline: "k" },
  ...mantel(), ...harnisch(), ...zeichen(), ...schienen(),
  ...kragen(), ...schulter(),
  glow("e", { r: 2, strength: 0.25 }))

// Derselbe Mantel auf der Figur: deckungsgleich mit Charakter.png, die
// Mitte des Körpers liegt auf der Spiegelkante. Die Hände und Füsse
// bleiben frei.
sprite("charakter_nachtmantel", { w: 62, h: 62, mx: true, outline: "k" },
  // Der Mantel hinter allem, unten ausgezackt.
  poly([22, 27, 16, 30, 15, 42, 14, 53, 18, 48, 20, 56, 23, 49, 26, 54, 26, 27], "m"),
  poly([21, 31, 18, 31, 16, 43, 19, 40], "b"),
  poly([22, 42, 21, 49, 23, 44], "b"),
  line(19, 30, 16, 49, "N"),
  // Die Beine.
  rect(25, 45, 4, 13, "d"), vline(25, 45, 13, "n"),
  // Die Arme.
  rect(20, 30, 4, 12, "n"), vline(20, 30, 12, "N"), rect(20, 39, 4, 3, "d"),
  hline(20, 41, 4, "b"),
  // Der Harnisch.
  rect(24, 26, 7, 21, "n"),
  vline(24, 27, 19, "d"),
  poly([25, 27, 31, 27, 31, 34, 25, 31], "N"),
  line(25, 31, 30, 33, "L"), line(25, 32, 30, 34, "d"),
  vline(30, 27, 6, "n"),
  // Die Fledermaus auf dem Bauch.
  poly([31, 37, 29, 37, 28, 36, 26, 36, 25, 35, 26, 39, 28, 38, 29, 41, 31, 43], "b"),
  px(30, 39, "e"), px(30, 38, "e"), px(26, 36, "B"), px(27, 37, "B"),
  // Die Schienen darunter.
  hline(25, 43, 6, "k"), hline(25, 44, 6, "N"),
  // Die Schulter mit Kralle.
  ellipse(21, 29, 4, 4, "n"),
  clip((x, y) => y < 29, ellipse(21, 29, 3, 3, "N")),
  px(19, 27, "l"), px(20, 26, "l"), hline(18, 31, 7, "d"),
  poly([18, 27, 16, 22, 20, 26], "s"),
  // Der Kragen, der hochsteht wie die Ohren der Haube.
  poly([23, 27, 23, 22, 27, 25, 31, 30, 31, 27], "n"),
  poly([25, 26, 25, 24, 27, 26, 30, 29], "b"))
