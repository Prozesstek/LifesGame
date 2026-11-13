// Das Zeichen für „mehrere verkaufen“ (Rucksack und Siegerblatt): ein
// Lederbeutel, schwer von Münzen — unten breit und flach, oben mit einer
// goldenen Kordel zugeschnürt —, davor die Goldmünze aus goldmuenze.px.js,
// kleiner. Ersetzt das Systemzeichen mit Haken und Strichen (AktivesBrett,
// 13.11.2026).
// Gezeichnet mit pxl (github.com/crsolver/claude-pxl) auf 64 × 64; abgelegt
// als assets/UI/Verkaufen.png in 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/mehrere_verkaufen.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/mehrere_verkaufen.png assets/UI/Verkaufen.png
pal({
  k: "#2a1b24",                                                   // Umriss
  L: "#e8b878", b: "#c98a4e", B: "#9c5f32", n: "#6e3d22", N: "#4a2616", // Leder
  W: "#fffbe6", O: "#fff2b0", o: "#f2cf5c", y: "#c8952c", Y: "#7a5212", // Gold
  x: "#ffffff",
})
ramps("kNnBbL", "kYyoOW")

// ── Der Beutel ──────────────────────────────────────────────────────────
// Ein Ledersack, schwer von Münzen: unten breit und flach, nach oben
// verjüngt er sich zum Hals.
const BX = 25           // Mitte des Beutels
const OBEN = 17, UNTEN = 58
// halbe Breite je Zeile
const breite = (y) => {
  const t = (y - OBEN) / (UNTEN - OBEN)            // 0 oben … 1 unten
  // erst rasch breiter, dann bauchig bis fast zum Boden
  const s = t < 0.62 ? Math.sin((t / 0.62) * Math.PI / 2) ** 0.8 : 1
  let w = 6 + 17 * s + (t > 0.5 ? Math.sin(((t - 0.5) / 0.5) * Math.PI) * 1.5 : 0)
  // runde Ecken unten, der Boden selbst flach
  const rest = UNTEN - y
  if (rest < 4) w -= (4 - rest) * (4 - rest) * 0.6
  return w
}
const bauch = (c) => {
  for (let y = OBEN; y <= UNTEN; y++) {
    const w = breite(y)
    for (let x = Math.round(BX - w); x <= Math.round(BX + w); x++) {
      const nx = (x + 0.5 - BX) / w, ny = (y - OBEN) / (UNTEN - OBEN)
      // Licht von oben links, unten zum Boden hin dunkler
      const l = -nx * 0.6 - (ny - 0.4) * 0.7 + (1 - nx * nx) * 0.3 - (y > UNTEN - 2 ? 0.5 : 0)
      c.px(x, y, l > 0.75 ? "L" : l > 0.3 ? "b" : l > -0.15 ? "B" : l > -0.55 ? "n" : "N")
    }
  }
}

// Falten, die vom Hals nach unten auslaufen.
const falten = () => [
  line(22, 20, 14, 34, "n"), line(26, 20, 25, 33, "n"), line(30, 20, 37, 33, "N"),
  line(21, 21, 13, 34, "L"),
]

// Der zugeschnürte Hals und die Zipfel oben.
const kopf = () => [
  poly([20, 18, 32, 18, 30, 13, 22, 13], "B"),
  poly([20, 18, 24, 18, 23, 13, 22, 13], "b"),
  poly([13, 3, 19, 8, 26, 1, 33, 8, 39, 3, 35, 12, 17, 12], "b"),
  poly([13, 3, 19, 8, 18, 11, 17, 12], "L"),
  poly([26, 1, 33, 8, 39, 3, 35, 12, 29, 12], "B"),
  line(19, 8, 21, 11, "n"), line(33, 8, 31, 11, "n"),
]

// Die Kordel: um den Hals, ein Knoten, ein Ende.
const kordel = () => [
  rect(17, 12, 18, 2, "o"), hline(17, 12, 18, "O"), hline(17, 14, 18, "y"),
  rect(24, 11, 4, 4, "o"), px(24, 11, "O"), px(27, 14, "Y"),
  line(25, 15, 21, 22, "o"), line(26, 15, 23, 23, "y"),
  px(20, 23, "O"), px(22, 24, "Y"),
]

// ── Die Münze, wie Gold.png, kleiner ───────────────────────────────────
const CM = 44.5, CR = 15.6, CRAND = 3.2
const cr = (x, y) => Math.hypot(x + 0.5 - CM, y + 0.5 - CM)
const cl = (x, y) => (-(x + 0.5 - CM) - (y + 0.5 - CM)) / (Math.SQRT2 * CR)
const muenze = (c) => {
  const innen = CR - CRAND
  for (let y = 0; y < 64; y++) for (let x = 0; x < 64; x++) {
    const d = cr(x, y)
    if (d > CR) continue
    const l = cl(x, y)
    // Umriss um die Münze, damit sie vor dem Beutel steht
    if (d > CR - 1) { c.px(x, y, "k"); continue }
    if (d > innen) {
      const ll = l + (d > CR - 1.9 ? -0.25 : 0)
      c.px(x, y, ll > 0.5 ? "O" : ll > 0.1 ? "o" : ll > -0.4 ? "y" : "Y")
    } else if (d > innen - 1.2) c.px(x, y, l > 0.2 ? "Y" : l < -0.3 ? "O" : "y")
    else c.px(x, y, l > 0.55 ? "O" : l > -0.3 ? "o" : "y")
  }
  // Rändelung
  for (let i = 0; i < 20; i++) {
    const a = ((i + 0.5) / 20) * Math.PI * 2
    const x = Math.floor(CM + Math.cos(a) * (CR - 2.3)), y = Math.floor(CM + Math.sin(a) * (CR - 2.3))
    c.px(x, y, cl(x, y) > 0.3 ? "o" : "Y")
  }
  // Die Krone, klein: drei Spitzen, ein Band.
  const krone = [
    "W...W...W",
    "O...O...O",
    "OO.OOO.OO",
    "OOOOOOOOO",
    "ooooooooo",
    "yyyyyyyyy",
  ]
  const ox = 40, oy = 42
  krone.forEach((z, j) => [...z].forEach((ch, i) => { if (ch !== ".") c.px(ox + i + 1, oy + j + 1, "Y") }))
  krone.forEach((z, j) => [...z].forEach((ch, i) => { if (ch !== ".") c.px(ox + i, oy + j, ch) }))
  // Glanz
  for (let a = 200; a <= 250; a += 2) {
    const t = (a * Math.PI) / 180
    c.px(Math.floor(CM + Math.cos(t) * (CR - 2)), Math.floor(CM + Math.sin(t) * (CR - 2)), "W")
  }
  c.px(37, 37, "x"); c.px(36, 37, "W"); c.px(38, 37, "W"); c.px(37, 36, "W"); c.px(37, 38, "W")
}

sprite("mehrere_verkaufen", { w: 62, h: 62, outline: "k" },
  bauch, ...falten(), ...kopf(), ...kordel(), muenze)
