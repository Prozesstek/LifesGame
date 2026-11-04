// Die Schattenstiefel, die Schuhe des Vampirsets, passend zu Haube und
// Mantel: ein Paar, ausgerichtet wie alle Schuhe im Spiel — der vordere
// zeigt nach links unten, der hintere steht höher und zeigt nach rechts,
// beide offen von oben. Ein Stiefel, zweimal gestempelt.
// Gezeichnet mit pxl auf 64 × 64. Abgelegt in 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/schattenstiefel.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/schattenstiefel.png assets/Schuhe/Schattenstiefel.png
pal({
  k: "#170e1e",                                 // Umriss
  d: "#1f1730", n: "#2e2340", N: "#4f3d6e",     // Nacht
  l: "#8672ad", L: "#c6b8e0",                   // Licht auf dem Metall
  m: "#4a1233", b: "#a8305f", B: "#d65c8f",     // Blut
  e: "#ffb3cf",                                 // der Stein, der glüht
  s: "#e8e4ef", S: "#a9a3bd",                   // Kralle
})
ramps("kdnNlL", "kmbBe", "kSs")

// Ein Stiefel, die Spitze links: Schaft, dann der Fuss.
const leib = () => [
  poly([12, 10, 27, 10, 26, 28, 29, 39, 29, 42, 3, 42, 0, 38, 2, 34, 12, 27], "n"),
  poly([23, 10, 27, 10, 26, 28, 29, 39, 29, 42, 25, 42, 23, 30], "d"),
  poly([3, 34, 12, 28, 16, 33, 12, 40, 3, 40], "N"),
  line(4, 34, 11, 29, "L"),
  // Schienen über dem Rist.
  line(15, 31, 13, 40, "k"), line(16, 31, 14, 40, "N"),
  line(19, 32, 17, 40, "k"), line(20, 32, 18, 40, "N"),
]

// Die Schiene am Schaft wie die Brust des Mantels, mit Stein.
const schiene = () => [
  poly([14, 16, 23, 16, 23, 25, 18, 30, 14, 25], "N"),
  vline(14, 17, 8, "l"),
  line(14, 25, 18, 29, "L"), line(18, 29, 22, 25, "L"),
  poly([18, 17, 15, 21, 18, 25, 21, 21], "k"),
  poly([18, 18, 16, 21, 18, 24, 20, 21], "b"),
  poly([18, 19, 17, 21, 18, 23, 19, 21], "e"),
]

// Kralle an der Spitze, Sporn an der Ferse, Sohle und Absatz.
const beschlag = () => [
  rect(1, 40, 28, 3, "d"), hline(3, 40, 26, "l"),
  rect(19, 42, 10, 2, "d"),
  poly([0, 36, 6, 40, 3, 43, 0, 44], "s"), line(1, 41, 0, 43, "S"),
  poly([28, 36, 30, 34, 30, 40], "s"),
]

// Der Kragen, von oben offen: Rand, rotes Futter, innen dunkel, zwei
// Spitzen wie die Ohren der Haube, darunter gezackte Flügelhaut wie am
// Saum des Mantels.
const kragen = () => [
  poly([10, 13, 13, 16, 15, 13, 18, 17, 21, 13, 24, 16, 26, 13, 29, 15, 29, 10, 10, 10], "b"),
  poly([10, 13, 13, 15, 15, 12, 18, 15, 21, 12, 24, 14, 26, 12, 29, 13, 29, 10, 10, 10], "m"),
  poly([7, 11, 4, 0, 13, 6], "n"), poly([30, 11, 30, 0, 24, 6], "n"),
  poly([7, 9, 6, 3, 10, 7], "N"), poly([29, 9, 29, 3, 26, 7], "N"),
  ellipse(19, 9, 11, 4, "N"),
  ellipse(19, 9, 9, 3, "b"),
  ellipse(19, 10, 8, 2, "k"),
  line(5, 2, 7, 8, "l"),
]

sprite("_stiefel", { w: 30, h: 44, outline: "k" },
  ...leib(), ...schiene(), ...beschlag(), ...kragen())

sprite("schattenstiefel", { w: 64, h: 64 },
  stamp("_stiefel", 30, 3, { flip: "x" }),
  stamp("_stiefel", 1, 18),
  glow("e", { r: 2, strength: 0.25 }))
