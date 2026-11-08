// Das Zeichen des Kreises „Statistik“: drei Balken, die steigen, und ein
// goldener Pfeil, der über sie hinweg nach oben schießt — das Zeichen für
// Fortschritt, das man aus jedem Spiel kennt. Alles steht mittig im Bild,
// die Spitze des Pfeils liegt genau in der Richtung seines letzten Stücks.
// Gezeichnet mit pxl (github.com/crsolver/claude-pxl) auf 64 × 64; abgelegt
// als assets/UI/Kreis_Statistik.png in 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/kreis_statistik.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/kreis_statistik.png assets/UI/Kreis_Statistik.png
pal({
  k: "#2a1b24",                                           // Umriss, wie bei Raven
  h: "#d2f58a", g: "#6abe30", G: "#3f8a2a", D: "#25572a", // Balken, grün wie das Häkchen
  O: "#fff2b0", o: "#f2cf5c", y: "#c8952c", Y: "#7a5212", // Gold
  v: "#c4864a", w: "#8a5128", W: "#552f17",               // Holz
  x: "#ffffff",
})
ramps("kDGgh", "kYyoO", "kWwv")

const BODEN = 50

// Ein Balken: links Licht, rechts Schatten, oben eine helle Kappe.
const balken = (x, oben) => [
  rect(x, oben, 11, BODEN - oben, "g"),
  rect(x, oben, 2, BODEN - oben, "h"),
  rect(x + 8, oben, 2, BODEN - oben, "G"),
  rect(x + 10, oben, 1, BODEN - oben, "D"),
  rect(x, oben, 11, 2, "h"),
  hline(x, oben + 2, 11, "G"),
  line(x + 3, oben + 6, x + 5, oben + 4, "h"),
]

// Das Brett, auf dem alles steht.
const brett = () => [
  rect(4, BODEN, 54, 6, "w"),
  hline(4, BODEN, 54, "v"),
  hline(4, BODEN + 5, 54, "W"),
  px(16, BODEN + 2, "W"), px(17, BODEN + 2, "W"), px(42, BODEN + 3, "W"), px(43, BODEN + 3, "W"),
]

// Der Pfeil. Die Spitze wird aus dem letzten Stück gerechnet: Sie zeigt
// genau in seine Richtung und sitzt mittig auf ihm.
const PFAD = [[5, 31], [19, 19], [29, 25], [41, 13]] // das letzte Stück unter genau 45°
const [ax, ay] = PFAD[PFAD.length - 2], [bx, by] = PFAD[PFAD.length - 1]
const laenge = Math.hypot(bx - ax, by - ay)
const [rx, ry] = [(bx - ax) / laenge, (by - ay) / laenge] // Richtung
const [qx, qy] = [-ry, rx]                                // quer dazu
// Ein Stück des Schafts, um `seite` quer zu seiner Richtung verschoben —
// negativ ist oben links, die Seite im Licht. Das letzte Stück endet unter
// der Spitze.
const stueck = (i, farbe, breit, seite = 0) => {
  const [x0, y0] = PFAD[i], [x1, y1] = PFAD[i + 1]
  const l = Math.hypot(x1 - x0, y1 - y0)
  const [ux, uy] = [(x1 - x0) / l, (y1 - y0) / l]
  const [px0, py0] = [-uy * seite, ux * seite]
  const ende = i === PFAD.length - 2 ? 3 : 0
  return line(Math.round(x0 + px0), Math.round(y0 + py0),
    Math.round(x1 - ux * ende + px0), Math.round(y1 - uy * ende + py0), farbe, breit)
}
const strich = (farbe, breit, seite = 0) =>
  PFAD.slice(1).map((_, i) => stueck(i, farbe, breit, seite))
// Die Spitze ist ein rechter Winkel: oben waagrecht, rechts senkrecht, so
// bleiben ihre Kanten im Raster gerade. Sie wird Pixel für Pixel gesetzt
// und ist dabei genau spiegelgleich zur Diagonale durch ihre Spitze — auf
// dieser Diagonale liegt auch das letzte Stück des Schafts. Nur das Licht
// fällt von oben links.
const SCHENKEL = 12
const [tx, ty] = [bx + SCHENKEL / 2, by - SCHENKEL / 2]
const kopf = (rand) => (c) => {
  for (let y = ty - 3; y <= ty + SCHENKEL + 3; y++) {
    for (let x = tx - SCHENKEL - 3; x <= tx + 3; x++) {
      const links = tx - x, unten = y - ty
      const innen = links >= 0 && unten >= 0 && links + unten <= SCHENKEL
      const umriss = links >= -2 && unten >= -2 && links + unten <= SCHENKEL + 3
      if (rand && umriss && !innen) c.px(x, y, "k")
      if (!rand && innen) {
        const farbe = unten < links - 1 ? (unten < 2 && links > 2 ? "O" : "o") : unten > links + 1 ? "y" : "o"
        c.px(x, y, farbe)
      }
    }
  }
}
const pfeil = () => [
  ...strich("k", 8),
  kopf(true),
  ...strich("y", 4),
  ...strich("o", 2, -1),
  kopf(false),
]

sprite("kreis_statistik", { w: 62, h: 62, outline: "k" },
  ...brett(), ...balken(9, 41), ...balken(25, 35), ...balken(41, 28), ...pfeil())
