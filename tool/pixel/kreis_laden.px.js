// Das Zeichen des Kreises „Laden“: ein praller Lederbeutel voller Gold,
// oben mit einer goldenen Kordel zugebunden, davor ein Stapel Münzen —
// der Geldbeutel, den man aus jedem Rollenspiel kennt.
// Gezeichnet mit pxl (github.com/crsolver/claude-pxl) auf 64 × 64; abgelegt
// als assets/UI/Kreis_Laden.png in 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/kreis_laden.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/kreis_laden.png assets/UI/Kreis_Laden.png
pal({
  k: "#2a1b24",                                           // Umriss, wie bei Raven
  L: "#e8b878", b: "#c98a4e", B: "#9c5f32", n: "#6e3d22", N: "#4a2616", // Leder
  O: "#fff2b0", o: "#f2cf5c", y: "#c8952c", Y: "#7a5212", // Gold
  x: "#ffffff",
})
ramps("kNnBbL", "kYyoO")

// Der Bauch des Beutels: ein Oval, Licht von oben links, gestuft.
const MX = 30, MY = 40, RX = 21, RY = 19
const bauch = (c) => {
  for (let y = MY - RY; y <= MY + RY; y++) for (let x = MX - RX; x <= MX + RX; x++) {
    const nx = (x + 0.5 - MX) / RX, ny = (y + 0.5 - MY) / RY
    const r = Math.hypot(nx, ny)
    if (r > 1) continue
    const licht = (-nx - ny) / Math.SQRT2 * r + (1 - r) * 0.35
    const farbe = licht > 0.55 ? "L" : licht > 0.2 ? "b" : licht > -0.2 ? "B" : licht > -0.55 ? "n" : "N"
    c.px(x, y, farbe)
  }
}

// Falten, die vom Hals nach unten laufen.
const falten = () => [
  line(24, 25, 18, 36, "B"), line(30, 25, 29, 40, "n"), line(36, 25, 41, 35, "n"),
  line(23, 26, 17, 35, "L"),
]

// Der Hals und die Öffnung oben: drei Zipfel, dazwischen sieht man Gold.
const kopf = () => [
  poly([23, 24, 37, 24, 35, 18, 25, 18], "B"),
  poly([23, 24, 28, 24, 27, 18, 25, 18], "b"),
  poly([17, 6, 24, 11, 30, 4, 36, 11, 43, 6, 39, 17, 21, 17], "b"),
  poly([17, 6, 24, 11, 22, 16, 21, 17], "L"),
  poly([30, 4, 36, 11, 34, 15, 30, 9], "B"),
  poly([43, 6, 39, 17, 35, 15, 36, 11], "n"),
  // Gold, das oben herausschaut.
  ellipse(30, 13, 7, 3, "Y"),
  ellipse(28, 12, 3, 1, "o"), px(33, 12, "O"), px(26, 13, "y"),
]

// Die Kordel: zweimal herum, vorn ein Knoten, zwei Enden hängen.
const kordel = () => [
  rect(21, 17, 19, 3, "y"), hline(21, 17, 19, "o"), hline(21, 19, 19, "Y"),
  line(23, 18, 26, 18, "O"),
  rect(28, 16, 5, 5, "o"), px(29, 17, "O"), px(31, 19, "Y"),
  line(32, 21, 36, 29, "y"), line(33, 21, 37, 29, "Y"),
  line(28, 21, 26, 30, "o"), line(29, 21, 27, 30, "y"),
  rect(35, 29, 3, 3, "y"), px(35, 29, "O"), rect(25, 30, 3, 3, "y"), px(25, 30, "O"),
]

// Eine Münze, flach liegend: Rand, Fläche, Licht.
const muenze = (x, y) => [
  ellipse(x, y, 7, 3, "Y"),
  ellipse(x, y - 1, 7, 3, "y"),
  ellipse(x, y - 1, 6, 2, "o"),
  hline(x - 3, y - 2, 4, "O"),
]
// Eine Münze, aufrecht gestellt, mit Krone.
const stehend = (x, y) => [
  ellipse(x, y, 8, 8, "Y"),
  ellipse(x - 1, y, 7, 8, "y"),
  ellipse(x - 1, y, 5, 6, "o"),
  // Die Krone: drei Zacken auf einem Band.
  rect(x - 5, y + 1, 9, 3, "Y"),
  poly([x - 5, y + 2, x - 5, y - 4, x - 3, y - 1, x - 1, y - 5, x + 1, y - 1, x + 4, y - 4, x + 4, y + 2], "Y"),
  px(x - 5, y - 4, "O"), px(x - 1, y - 5, "O"), px(x + 3, y - 4, "O"),
  hline(x - 4, y + 2, 7, "y"),
  line(x - 5, y - 5, x - 3, y - 7, "O"), px(x - 6, y - 3, "O"),
]

const stapel = () => [...muenze(48, 58), ...muenze(48, 54), ...muenze(49, 50)]

const glanz = () => [px(14, 30, "x"), px(15, 29, "x"), px(13, 31, "L")]

sprite("_beutel", { w: 62, h: 62, outline: "k" },
  bauch, ...falten(), ...kopf(), ...kordel(), ...glanz())
// Jede Münze hat ihren eigenen Rand, sonst flössen sie in den Beutel.
sprite("_stapel", { w: 62, h: 62, outline: "k" }, ...stapel())
sprite("_stehend", { w: 62, h: 62, outline: "k" }, ...stehend(13, 52))

sprite("kreis_laden", { w: 64, h: 64 },
  stamp("_beutel", 0, 0), stamp("_stapel", 0, 0), stamp("_stehend", 0, 0))
