// Die Goldmünze, überall wo Gold steht (`GoldIcon`): dicker, gerändelter
// Rand, eine vertiefte Fläche mit einer leise geprägten Krone, Licht von
// oben links und ein Glanzfunke. Ersetzt die Münze mit der „1“ (AktivesBrett,
// 13.11.2026).
// Gezeichnet mit pxl (github.com/crsolver/claude-pxl) auf 64 × 64; abgelegt
// als assets/Items/Gold.png in 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/goldmuenze.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/goldmuenze.png assets/Items/Gold.png
pal({
  k: "#2a1b24",                                           // Umriss
  W: "#fffbe6", O: "#fff2b0", o: "#f2cf5c", y: "#c8952c", Y: "#7a5212", // Gold
  x: "#ffffff",
})
ramps("kYyoOW")

const M = 31             // Mitte (62 breit, mit Umriss 64)
const R = 28.6           // Aussenrand — kein Zacken an den vier Seiten
const RAND = 5           // Breite des Rands
const INNEN = R - RAND

const r = (x, y) => Math.hypot(x + 0.5 - M, y + 0.5 - M)
// Licht von oben links: -1 dunkel … +1 hell.
const licht = (x, y) => (-(x + 0.5 - M) - (y + 0.5 - M)) / (Math.SQRT2 * R)

// 1. Der Rand: ein dicker Ring, oben links hell, unten rechts dunkel; die
//    äusserste Reihe eine Spur dunkler, das ist die Kante der Münze.
const rand = (c) => {
  for (let y = 0; y < 62; y++) for (let x = 0; x < 62; x++) {
    const d = r(x, y)
    if (d > R || d <= INNEN) continue
    const l = licht(x, y) + (d > R - 1.2 ? -0.25 : 0)
    c.px(x, y, l > 0.5 ? "O" : l > 0.1 ? "o" : l > -0.4 ? "y" : "Y")
  }
}

// 2. Die Rändelung: gleichmässige Kerben im Rand, je eine Stufe dunkler
//    als ihr Grund.
const kerben = (c) => {
  const n = 36
  for (let i = 0; i < n; i++) {
    const a = ((i + 0.5) / n) * Math.PI * 2
    const x = Math.floor(M + Math.cos(a) * (R - 2.6))
    const y = Math.floor(M + Math.sin(a) * (R - 2.6))
    const l = licht(x, y)
    c.px(x, y, l > 0.5 ? "o" : l > 0.1 ? "y" : l > -0.4 ? "Y" : "Y")
  }
}

// 3. Die Fläche: vertieft, also umgekehrtes Licht an ihrer Kante (oben
//    links Schatten, unten rechts Licht), innen ein weicher Verlauf.
const flaeche = (c) => {
  for (let y = 0; y < 62; y++) for (let x = 0; x < 62; x++) {
    const d = r(x, y)
    if (d > INNEN) continue
    const l = licht(x, y)
    let f
    if (d > INNEN - 1.5) f = l > 0.2 ? "Y" : l < -0.3 ? "O" : "y"   // Fase
    else f = l > 0.55 ? "O" : l > -0.3 ? "o" : "y"
    c.px(x, y, f)
  }
}

// 4. Die Krone, leise geprägt: in den Farben der Fläche, nur ein Schatten
//    unten rechts und helle Spitzen.
const krone = [
  "..W.........W.........W..",
  "..W.........W.........W..",
  "..O.........O.........O..",
  "..OO.......OOO.......OO..",
  "..OOO.....OOOOO.....OOO..",
  "..OOOO...OOOOOOO...OOOO..",
  "..OOOOO.OOOOOOOOO.OOOOO..",
  "..OOOOOOOOOOOOOOOOOOOOO..",
  "..OOOOOOOOOOOOOOOOOOOOO..",
  "..ooooooooooooooooooooo..",
  "..yyyyyyyyyyyyyyyyyyyyy..",
  "..OOOOOOOOOOOOOOOOOOOOO..",
  "..OoOoOoOoOoOoOoOoOoOoO..",
  "..yyyyyyyyyyyyyyyyyyyyy..",
]
const praegung = (c) => {
  const ox = 18, oy = 23
  const zeichne = (dx, dy, farbe) => krone.forEach((zeile, j) => [...zeile].forEach((ch, i) => {
    if (ch !== ".") c.px(ox + i + dx, oy + j + dy, farbe ?? ch)
  }))
  zeichne(1, 1, "Y")    // Schatten der Prägung
  zeichne(0, 0)
}

// 5. Glanz: ein heller Bogen oben links auf dem Rand und ein Funke.
const glanz = (c) => {
  for (let a = 200; a <= 250; a += 1) {
    const t = (a * Math.PI) / 180
    for (const d of [R - 1.8, R - 3]) {
      c.px(Math.floor(M + Math.cos(t) * d), Math.floor(M + Math.sin(t) * d), "W")
    }
  }
  const fx = 13, fy = 12
  for (const [dx, dy] of [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]) c.px(fx + dx, fy + dy, "x")
  for (const [dx, dy] of [[2, 0], [-2, 0], [0, 2], [0, -2]]) c.px(fx + dx, fy + dy, "W")
}

sprite("goldmuenze", { w: 62, h: 62, outline: "k" }, rand, kerben, flaeche, praegung, glanz)
