// Die Kette: zwei Glieder aus Stahl, senkrecht ineinander — das Zeichen
// für gekoppelte Gewohnheiten (ADR-0065): Sie hängt, wie die Gewohnheiten
// untereinander hängen. Beide Glieder von vorn (19.11.2026 gewählt, vor
// einem zur Seite gedrehten). Gezeichnet mit pxl auf 64 × 64.
// Abgelegt in 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/kette.px.js --only kette
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/kette.png assets/UI/Kette.png
include("paletten/grund.px.js")

// Ein Glied ist ein Stadion (Rechteck mit runden Enden) als Ring,
// senkrecht gestellt. Von der Seite gesehen ist es ein schmaler Stab.
const A = 7         // halbe Länge der geraden Seite
const R = 10        // äußerer Radius der Rundung
const T = 5         // Dicke des Stahls
const D = 25        // Abstand der beiden Mitten
const M = 30.5      // Bildmitte
const oberes = { cx: M, cy: M - D / 2 }

// Wie weit ein Punkt vom Rand eines Glieds liegt (negativ innen), samt
// Richtung nach außen von der Mittellinie.
function stadion(g, px, py, a, r) {
  const dx = px - g.cx, dy = py - g.cy
  const uk = Math.max(-a, Math.min(a, dy))
  let nx = dx, ny = dy - uk
  const l = Math.hypot(nx, ny) || 1
  return { d: l - r, nx: nx / l, ny: ny / l }
}

// Licht von oben links und etwas von vorn.
const licht = [-0.55, -0.6, 0.58]
const ton = (h) => (h > 0.9 ? "x" : h > 0.66 ? "w" : h > 0.25 ? "s" : "S")

// Ein Glied als Ring aus rundem Draht. `sx` staucht es in der Breite:
// 1 ist von vorn, mehr ist zur Seite gedreht.
function glied(g, sx = 1) {
  return (px, py) => {
    const s = stadion(g, g.cx + (px - g.cx) * sx, py, A, R)
    if (s.d > 0 || s.d <= -T) return null
    const sq = (s.d + T / 2) / (T / 2)          // -1 innen, +1 außen
    const z = Math.sqrt(Math.max(0, 1 - sq * sq))
    return s.nx * sq * licht[0] + s.ny * sq * licht[1] + z * licht[2]
  }
}

// Zeichnet zwei Glieder; wo beide sind, entscheidet `obenauf`, wo eines
// unter dem anderen verschwindet, trennt sie eine Fuge in Umrissfarbe.
function kette(c, glieder, obenauf) {
  const wer = (x, y) => {
    const h = glieder.map((f) => f(x + 0.5, y + 0.5))
    if (h[0] != null && h[1] != null) return obenauf(x, y)
    return h[0] != null ? 0 : h[1] != null ? 1 : -1
  }
  for (let y = 0; y < 62; y++)
    for (let x = 0; x < 62; x++) {
      const i = wer(x, y)
      if (i < 0) continue
      let fuge = false
      for (const [nx, ny] of [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]]) {
        const j = wer(nx, ny)
        if (j >= 0 && j !== i && glieder[i](nx + 0.5, ny + 0.5) != null) fuge = true
      }
      const h = glieder[i](x + 0.5, y + 0.5)
      c.px(x, y, fuge || h < -0.5 ? "k" : ton(h))
    }
}

// Beide von vorn: links liegt das obere Glied obenauf, rechts das untere.
sprite("kette", { w: 62, h: 62, outline: "k" }, (c) => {
  const unten = { cx: M, cy: M + D / 2 }
  kette(c, [glied(oberes), glied(unten)], (x) => (x < 31 ? 0 : 1))
})
