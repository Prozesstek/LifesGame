// Das Zeichen des Kreises „Kampf“: zwei gekreuzte Schwerter.
// Gezeichnet mit pxl (github.com/crsolver/claude-pxl) auf 64 × 64; abgelegt
// als assets/UI/Kreis_Kampf.png in 256 × 256 (4×, hart).
pal({
  k: "#2a1b24",                                           // Umriss, wie bei Raven
  x: "#f4faff", w: "#bcd3e8", s: "#6f8eae", S: "#3e5470", // Stahl, kühl und kräftig
  O: "#fff2b0", o: "#f2cf5c", y: "#c8952c", Y: "#7a5212", // Gold
  l: "#8a5530", L: "#55301c",                             // Leder am Griff
})
ramps("kSswx", "kYyoO", "kLl")

// Ein Schwert, Knauf unten links, Spitze oben rechts. Jedes Pixel wird
// auf die Achse des Schwerts gelegt: u entlang (vom Knauf aus), v quer
// (negativ = oben links, die Seite im Licht).
const KNAUF = [8, 54]
const ACHSE = [Math.SQRT1_2, -Math.SQRT1_2]
const QUER = [Math.SQRT1_2, Math.SQRT1_2]
const SPITZE = 65

function farbe(u, v) {
  const a = Math.abs(v)
  // Knauf: eine goldene Kugel.
  const k = Math.hypot(u - 2.2, v)
  if (k < 3.3) return k < 1.5 && v < 0 ? "O" : v < 0.4 ? "o" : "y"
  // Griff: Leder, schräg umwickelt.
  if (u >= 4.5 && u < 13 && a < 2.4) return (u + v * 0.6) % 3 < 1 ? "l" : "L"
  // Parierstange: quer, mit runden Enden.
  if (u >= 13 && u < 17 && a < 10) {
    if (a > 7.8) return v < 0 ? "O" : "y"
    return u < 14.2 ? "o" : u > 15.8 ? "Y" : v < 0 ? "o" : "y"
  }
  // Die Klinge: breit bis kurz vor der Spitze, dann spitz zulaufend. Die
  // Seite im Licht hell, die andere grau, dazwischen der Grat.
  if (u >= 17 && u <= SPITZE) {
    const breit = u < SPITZE - 10 ? 4.4 : 4.4 * (SPITZE - u) / 10
    if (a > breit || breit < 0.8) return null
    if (a < 0.6 && u < SPITZE - 8) return "S"            // Grat
    if (v > breit - 0.9) return "S"                      // Schneide im Schatten
    if (v < -breit + 0.9) return "x"                     // Kante im Licht
    return v < 0 ? "w" : "s"
  }
  return null
}

sprite("_schwert", { w: 62, h: 62, outline: "k" }, (c) => {
  for (let y = 0; y < 62; y++) for (let x = 0; x < 62; x++) {
    const dx = x + 0.5 - KNAUF[0], dy = y + 0.5 - KNAUF[1]
    const f = farbe(dx * ACHSE[0] + dy * ACHSE[1], dx * QUER[0] + dy * QUER[1])
    if (f) c.px(x, y, f)
  }
})

// Das zweite liegt gespiegelt obenauf; jedes hat seinen eigenen Umriss,
// so sieht man an der Kreuzung, welches vorn ist.
sprite("kreis_kampf", { w: 64, h: 64 },
  stamp("_schwert", 0, -1),
  stamp("_schwert", 0, -1, { flip: "x" }))
