// Die Blutsichel, die Waffe des Vampirsets, passend zu Haube, Mantel und
// Stiefeln: der Griff unten links, die Klinge biegt sich oben herum nach
// rechts, wie bisher. Unter der Klinge spannt sich Flügelhaut.
// Gezeichnet mit pxl auf 64 × 64. Abgelegt in 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/blutsichel.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/blutsichel.png assets/Waffen/Sicheln/Blutsichel.png
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/charakter_blutsichel.png assets/character/Charakter_Blutsichel.png
pal({
  k: "#170e1e",                                 // Umriss
  d: "#1f1730", n: "#2e2340", N: "#4f3d6e",     // Nacht
  l: "#8672ad", L: "#c6b8e0",                   // Licht auf dem Metall
  m: "#4a1233", b: "#a8305f", B: "#d65c8f",     // Blut
  e: "#ffb3cf", r: "#ff5c8f",                   // was glüht
  t: "#3b3253", S: "#6a5f86", s: "#a89dc4",     // die Klinge: dunkler Stahl
  c: "#e8e4ef",                                 // Kralle
})
ramps("kdnNlL", "kmbBe", "ktSs")

// Die Klinge ist der Rest zwischen zwei Kreisen: dick am Griff, spitz am
// Ende. Wo sie liegt, sagt `klinge`, alles andere fragt dort nach.
const aussen = (x, y) => Math.hypot(x - 36, y - 29)
const innen = (x, y) => Math.hypot(x - 41, y - 35)
const klinge = (x, y) => aussen(x, y) <= 26 && innen(x, y) > 24 && y < 38

// Die Flügelhaut unter der Klinge, unten ausgezackt.
const haut = () => [
  poly([17, 32, 24, 13, 38, 10, 46, 13, 41, 21, 37, 17, 34, 27, 28, 22, 26, 34, 21, 28], "m"),
  poly([18, 28, 24, 15, 37, 12, 40, 15, 36, 15, 33, 22, 28, 19, 25, 27, 21, 24], "b"),
]

// Ein Punkt auf der Klinge, in Grad um den äusseren Kreis.
const auf = (grad, r) => [
  Math.round(36 + r * Math.cos((grad * Math.PI) / 180)),
  Math.round(29 + r * Math.sin((grad * Math.PI) / 180)),
]

// Dornen auf dem Rücken, wie die Krallen am Flügel.
const dornen = () => [205, 232, 259].map((g) => {
  const [ax, ay] = auf(g - 6, 25), [bx, by] = auf(g, 30), [cx, cy] = auf(g + 6, 25)
  return poly([ax, ay, bx, by, cx, cy], "S")
})

const schneide = () => [
  ...dornen(),
  clip(klinge, rect(0, 0, 62, 40, "t")),
  // Der Schliff in der Mitte, der Rücken im Licht.
  clip((x, y) => klinge(x, y) && aussen(x, y) > 20 && aussen(x, y) <= 23, rect(0, 0, 62, 40, "S")),
  clip((x, y) => klinge(x, y) && aussen(x, y) > 24.5, rect(0, 0, 62, 40, "s")),
  // Die Schneide glüht.
  clip((x, y) => klinge(x, y) && innen(x, y) <= 26.5, rect(0, 0, 62, 40, "b")),
  clip((x, y) => klinge(x, y) && innen(x, y) <= 25.5, rect(0, 0, 62, 40, "r")),
  // Runen im Schliff.
  ...[212, 236, 260, 284].flatMap((g) => {
    const [x, y] = auf(g, 21.5)
    return [px(x, y, "r"), px(x + 1, y, "b"), px(x, y + 1, "b"), px(x - 1, y, "b"), px(x, y - 1, "b")]
  }),
]

// Der Griff: dunkel, rot umwickelt, unten eine Kralle.
const griff = () => [
  line(14, 36, 4, 58, "n", 5),
  line(13, 37, 3, 57, "N", 2),
  line(9, 42, 13, 44, "b", 2), line(7, 47, 11, 49, "b", 2),
  line(5, 52, 9, 54, "b", 2),
  poly([0, 57, 8, 58, 2, 62], "c"),
]

// Die Parierstange: zwei kleine Flügel um einen Stein.
const parier = () => [
  poly([14, 33, 3, 27, 5, 37, 9, 34, 11, 41, 15, 38, 21, 41, 20, 37, 25, 37, 20, 33], "n"),
  poly([13, 34, 6, 30, 7, 34, 10, 32, 12, 37, 15, 35], "N"),
  poly([14, 32, 10, 36, 14, 40, 18, 36], "k"),
  poly([14, 33, 11, 36, 14, 39, 17, 36], "b"),
  poly([14, 34, 13, 36, 14, 38, 15, 36], "e"),
]

// Blut, das an der Schneide herabläuft: ein Film entlang der Kante, aus
// dem Zungen verschiedener Länge hängen. Unten rund, Licht links.
const zunge = (x, y, lang) => [
  rect(x - 1, y, 3, lang, "b"),
  px(x, y + lang, "b"),
  vline(x - 1, y, lang, "B"),
  vline(x + 1, y + 1, lang - 1, "m"),
]

// Ein Tropfen im Fall: spitz nach oben, unten rund.
const tropfen = (x, y) => [
  px(x, y, "b"), px(x, y + 1, "b"),
  rect(x - 1, y + 2, 3, 3, "b"),
  rect(x - 2, y + 3, 5, 2, "b"),
  rect(x - 1, y + 5, 3, 1, "b"),
  px(x - 1, y + 3, "B"), px(x - 1, y + 4, "e"),
  vline(x + 2, y + 3, 2, "m"), px(x + 1, y + 5, "m"),
]

const blut = () => [
  clip((x, y) => x >= 44 && x <= 57 && innen(x, y) > 21.5 && innen(x, y) <= 24, rect(40, 8, 22, 16, "b")),
  ...zunge(46, 13, 3),
  ...zunge(50, 14, 10),
  ...zunge(54, 15, 5),
  ...tropfen(50, 30),
]

sprite("blutsichel", { w: 62, h: 62, outline: "k" },
  ...haut(), ...schneide(), ...griff(), ...parier(), ...blut(),
  glow("er", { r: 2, strength: 0.25 }))

// Dieselbe Sichel auf der Figur: deckungsgleich mit Charakter.png, der
// Griff liegt in der rechten Hand. Wer sie verschiebt, schiebt alles.
const klein = (x, y) =>
  Math.hypot(x - 53, y - 20) <= 9 && Math.hypot(x - 55, y - 22) > 8 && y < 24
sprite("charakter_blutsichel", { w: 62, h: 62, outline: "k" },
  // Die Haut zuerst, dann die Klinge darüber.
  poly([46, 22, 49, 15, 56, 14, 53, 18, 51, 17, 50, 21, 48, 20], "b"),
  clip(klein, rect(38, 8, 24, 18, "S")),
  clip((x, y) => klein(x, y) && Math.hypot(x - 53, y - 20) > 8, rect(38, 8, 24, 18, "s")),
  clip((x, y) => klein(x, y) && Math.hypot(x - 55, y - 22) <= 9, rect(38, 8, 24, 18, "r")),
  // Der Griff hell genug, um sich vom Mantel abzuheben.
  line(40, 50, 47, 24, "N", 3), line(40, 49, 46, 25, "l"),
  px(42, 42, "b"), px(43, 42, "b"), px(44, 35, "b"), px(45, 35, "b"),
  poly([44, 24, 46, 21, 49, 24, 46, 27], "n"),
  px(46, 23, "e"), px(46, 24, "e"), px(46, 25, "b"))
