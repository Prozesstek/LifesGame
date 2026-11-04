// Die Fledermaushaube, das Herz des Vampirsets: ein Helm als Fledermaus.
// Gezeichnet mit pxl (github.com/crsolver/claude-pxl) auf 64 × 64 wie
// jedes Bild im Projekt. Nur die linke Hälfte steht hier, `mx` spiegelt
// sie, die Mitte liegt also genau auf der Kante zwischen x = 30 und 31.
// Abgelegt in 256 × 256 mit tool/pixel/vergroessern.js:
//   node <pxl>/bin/pxl.js build tool/pixel/fledermaushaube.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/fledermaushaube.png assets/Helme/Fledermaushaube.png
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/charakter_fledermaushaube.png assets/character/Charakter_Fledermaushaube.png
pal({
  k: "#170e1e",                                 // Umriss
  d: "#1f1730", n: "#2e2340", N: "#4f3d6e",     // Nacht, wie der Mantel
  l: "#8672ad", L: "#c6b8e0",                   // Licht auf dem Metall
  m: "#4a1233", b: "#a8305f", B: "#d65c8f",     // Blut, wie die Sichel
  e: "#ffb3cf",                                 // das Auge, das glüht
  s: "#e8e4ef", S: "#a9a3bd",                   // Fangzähne
})
ramps("kdnNlL", "kmbBe", "kSs")

// Der Flügel an der Wange: Haut zwischen Fingern, unten ausgezackt.
// Jedes Feld zwischen zwei Fingern ist oben heller als unten, so wölbt
// sich die Haut, statt wie ein Brett dazustehen.
const fluegel = () => [
  poly([14, 26, 1, 18, 0, 24, 1, 44, 6, 38, 9, 51, 14, 43, 18, 55, 24, 44], "m"),
  poly([15, 28, 2, 21, 1, 30, 2, 38, 8, 33], "b"),
  poly([15, 31, 7, 37, 9, 44, 12, 38], "b"),
  poly([17, 34, 14, 41, 17, 48, 19, 41], "b"),
  poly([12, 27, 4, 22, 3, 26, 7, 28], "B"),
  // Die Finger, von der Schulter in die Zacken.
  line(15, 28, 1, 19, "N", 2), line(15, 30, 2, 42, "N", 1),
  line(16, 32, 9, 49, "N", 1), line(18, 34, 18, 53, "N", 1),
  line(14, 27, 3, 20, "l"),
  // Die Kralle am Knick.
  poly([3, 20, 0, 13, 5, 19], "s"),
]

// Die Ohren: hoch, leicht nach aussen, innen blutrot.
const ohren = () => [
  poly([5, 30, 7, 0, 22, 14, 18, 24], "n"),
  poly([5, 30, 7, 0, 9, 3, 8, 28], "N"),
  poly([9, 24, 9, 7, 18, 15, 15, 22], "m"),
  poly([10, 22, 10, 11, 15, 16, 13, 20], "b"),
  line(6, 26, 7, 2, "l"),
]

// Die Haube: ein Ei, Licht von oben links, darüber ein Stirnband, das
// zur Mitte hin abfällt und die Augen wütend macht.
const haube = () => [
  ellipse(31, 28, 19, 21, "n"),
  poly([16, 36, 31, 36, 31, 58, 25, 54, 20, 46], "n"),
  clip((x, y) => x < 15 || y > 46, ellipse(31, 28, 19, 21, "d")),
  // Alles über dem Band liegt im Licht.
  clip((x, y) => y < 21 + (x - 14) * 0.53, ellipse(31, 28, 17, 20, "N")),
  line(14, 21, 29, 29, "L"),
  line(16, 17, 22, 11, "l", 2),
  line(14, 22, 29, 30, "d"),
]

// Die Spitze auf der Stirn, die zwischen die Augen zieht.
const grat = () => [
  poly([31, 3, 25, 9, 28, 28, 31, 36], "N"),
  poly([31, 6, 29, 10, 30, 26, 31, 30], "L"),
]

// Die Augen: schmal, schräg, glühend.
const augen = () => [
  poly([13, 26, 28, 33, 28, 38, 17, 35], "k"),
  poly([16, 29, 27, 34, 27, 36, 19, 34], "b"),
  poly([18, 31, 26, 35, 25, 36, 20, 34], "e"),
]

// Der Mund, offen, und zwei Fänge daraus.
const faenge = () => [
  poly([20, 43, 31, 45, 31, 52, 25, 50], "k"),
  poly([22, 43, 27, 44, 25, 55], "s"),
  line(26, 45, 25, 53, "S"),
]

sprite("fledermaushaube", { w: 62, h: 62, mx: true, outline: "k" },
  ...fluegel(), ...ohren(), ...haube(), ...grat(), ...augen(), ...faenge(),
  glow("e", { r: 3, strength: 0.3 }))

// Dieselbe Haube auf der Figur: deckungsgleich mit Charakter.png, die
// Mitte des Kopfes liegt auf der Spiegelkante. Das Gesicht bleibt frei,
// die Figur soll ja noch jemand sein.
sprite("charakter_fledermaushaube", { w: 62, h: 62, mx: true, outline: "k" },
  // Die Flügel an den Wangen, unten ausgezackt.
  poly([21, 9, 16, 8, 15, 19, 18, 16, 19, 22, 22, 18], "m"),
  poly([21, 10, 17, 9, 17, 14, 20, 15], "b"),
  line(21, 10, 16, 9, "N"),
  // Die Ohren.
  poly([19, 9, 18, 0, 27, 5], "n"),
  poly([20, 7, 20, 3, 24, 6], "b"),
  // Die Haube bis auf die Stirn, die Spitze zieht zwischen die Augen.
  clip((x, y) => y < 14, ellipse(31, 12, 11, 11, "n")),
  poly([20, 12, 31, 15, 31, 17, 28, 15, 20, 15], "n"),
  clip((x, y) => y < 12, ellipse(31, 12, 9, 10, "N")),
  line(20, 12, 29, 15, "L"),
  line(23, 6, 26, 3, "l"),
  poly([31, 1, 29, 3, 30, 12, 31, 16], "L"))
