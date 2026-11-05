// Der Frostreif, ein legendärer Ring: ein breiter Reif aus geschliffenem
// Eis mit sternförmigen Facetten, darauf ein blauer Diamant zwischen
// silbernen Krallen. Das Innere des Reifs ist zu sehen, oben leuchtet es.
// Licht von oben links. Gezeichnet mit pxl auf 64 × 64. Abgelegt in 256 × 256:
//   node <pxl>/bin/pxl.js build tool/pixel/frostreif.px.js
//   node tool/pixel/vergroessern.js tool/pixel/out/sprites/frostreif.png assets/Ringe/Frostreif.png
pal({
  k: "#0b1430",                                 // Umriss
  d: "#14274f", n: "#1f4580", m: "#2e6fb0",     // Eis im Schatten
  c: "#3ba6d6", C: "#5fd0ea",                   // Eis
  l: "#9be8f5", L: "#d2f7fb", w: "#ffffff",     // Eis im Licht
  g: "#1b7fe0", D: "#0f4fb4", a: "#e6ffff",     // der Diamant
  S: "#7f93b0", s: "#e0e8f2",                   // Silber
})

const MX = 31, MY = 37
const oval = (x, y, cx, cy, rx, ry) => Math.hypot((x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry)
const aussen = (x, y) => oval(x, y, MX, MY, 27, 25)    // Rand des Reifs
const vorn = (x, y) => oval(x, y, MX, MY, 17, 15.5)      // Innenkante der Vorderseite
const loch = (x, y) => oval(x, y, 32, 37, 15, 14)  // das Loch, etwas versetzt

// Ein fester Zufall je Facette, damit das Eis nicht gleichförmig ist.
const zufall = (i) => {
  const v = Math.sin(i * 127.1 + 11.7) * 43758.5453
  return v - Math.floor(v)
}
const TOENE = ["d", "n", "m", "c", "C", "l", "L"]
const ton = (wert) => TOENE[Math.max(0, Math.min(6, Math.round(wert * 6)))]

// Die Vorderseite: Keile rund um den Reif, jeder in Dreiecke geschliffen,
// sodass Sterne entstehen. Das Licht kommt von oben links.
const KEILE = 12
const facette = (x, y) => {
  const dx = x + 0.5 - MX, dy = y + 0.5 - MY
  const winkel = (Math.atan2(dy, dx) + Math.PI) / (2 * Math.PI)
  const quer = (vorn(x, y) - 1) / (vorn(x, y) - aussen(x, y))
  const stelle = winkel * KEILE
  const keil = Math.floor(stelle), f = stelle - keil
  const spitze = 1 - Math.abs(2 * f - 1)
  const innenDreieck = quer < spitze
  const halb = f < 0.5 ? 0 : 1
  const kante = Math.abs(quer - spitze) < 0.09
  const g = (-dx - dy) / (Math.hypot(dx, dy) * Math.SQRT2)
  // Meist helles Eis, nur einzelne Dreiecke fallen ins Blaue.
  const wurf = zufall(keil * 4 + halb * 2 + (innenDreieck ? 1 : 0))
  const wert = 0.62 + 0.24 * g + (wurf < 0.22 ? -0.3 : (wurf - 0.6) * 0.3)
  return { wert, kante, quer }
}

const reif = (c) => {
  for (let y = 0; y < 62; y++) for (let x = 0; x < 62; x++) {
    if (aussen(x, y) > 1 || loch(x, y) <= 1) continue
    if (vorn(x, y) <= 1) {
      // Die Innenwand: unten rechts im Licht, oben glüht sie unter dem Stein.
      const g = (x - MX + (y - MY)) / 24
      const glut = y < 22 ? 0.3 : 0
      c.px(x, y, ton(0.55 + g * 0.3 + glut))
      continue
    }
    const { wert, kante, quer } = facette(x, y)
    if (quer > 0.86) {
      // Der Rand trägt Reif: dicht und körnig, oben links am hellsten.
      const dicht = zufall(x * 61 + y) < 0.45
      c.px(x, y, dicht ? "w" : ton(wert + 0.25))
    } else {
      c.px(x, y, kante ? (wert > 0.5 ? "w" : "L") : ton(wert))
    }
  }
}

// Der Stein ist in den Reif eingelassen: Nur sein oberes Drittel ragt
// heraus. `tief` rückt die Punkte an ihren Platz.
const tief = (y) => 6 + (y - 1) * 0.8

// Oben rund, unten spitz, wie ein Brillant von vorn. Die Facetten laufen aus
// der Mitte, hell und tief im Wechsel: Der Kontrast macht das Funkeln.
const MITTE = [31, tief(8)]
const RAND = [
  [26, 1, "L"], [31, 1, "C"], [36, 1, "l"], [40, 4, "D"], [41, 8, "c"], [38, 13, "D"],
  [34, 17, "C"], [31, 20, "l"], [28, 17, "D"], [24, 13, "C"], [21, 8, "g"], [22, 4, "w"],
]
const stein = () => [
  ...RAND.map(([x, y, farbe], i) => {
    const [nx, ny] = RAND[(i + 1) % RAND.length]
    return poly([...MITTE, x, tief(y), nx, tief(ny)], farbe)
  }),
  // Das Herz: ein weisser Stern in der Mitte.
  poly([31, tief(4), 35, tief(8), 31, tief(13), 27, tief(8)], "a"),
  poly([31, tief(5), 33, tief(8), 31, tief(11), 29, tief(8)], "w"),
]

// Die Halterung: ein schmaler Silberrand um die untere Hälfte des Steins.
// Er gehört zum Reif und teilt seinen Umriss.
const fassung = () => [
  poly([18, 12, 44, 12, 40, 18, 31, 23, 22, 18], "S"),
  poly([18, 12, 31, 12, 31, 23, 22, 18], "s"),
]

sprite("_reif", { w: 62, h: 62, outline: "k" }, reif, ...fassung())
sprite("_stein", { w: 62, h: 62, outline: "k" }, ...stein())

// Die Kälte um den Ring: Schneeflocken, Eissplitter und ein Hauch aus
// einzelnen Pixeln dicht am Reif.
const flocke = (x, y, gross) => {
  const teile = [hline(x - gross, y, 2 * gross + 1, "c"), vline(x, y - gross, 2 * gross + 1, "c")]
  for (let i = 1; i < gross; i++) {
    for (const [dx, dy] of [[-i, -i], [i, -i], [-i, i], [i, i]]) teile.push(px(x + dx, y + dy, "C"))
  }
  teile.push(px(x, y, "w"))
  return teile
}
const splitter = (punkte, licht) => [poly(punkte, "c"), poly(licht, "L")]

sprite("_splitter", { w: 62, h: 62, outline: "k" },
  ...splitter([4, 17, 8, 11, 9, 16], [4, 17, 8, 11, 7, 15]),
  ...splitter([54, 16, 58, 19, 53, 21], [54, 16, 58, 19, 55, 18]),
  ...splitter([5, 47, 2, 52, 8, 50], [5, 47, 2, 52, 6, 49]))

const hauch = (x, y) => {
  const weite = Math.hypot((x + 0.5 - 32) / 28, (y + 0.5 - 35) / 26)
  return weite > 1.05 && weite < 1.24 && zufall(x * 37 + y * 11) < 0.13
}

sprite("frostreif", { w: 64, h: 64 },
  clip(hauch, rect(0, 0, 64, 64, "l")),
  stamp("_splitter", 0, 0),
  stamp("_reif", 0, -3), stamp("_stein", 0, -3),
  ...flocke(7, 6, 3), ...flocke(57, 7, 3), ...flocke(58, 56, 3), ...flocke(6, 58, 2),
  ...flocke(47, 3, 1), ...flocke(16, 3, 1),
  // Ein paar Flocken fallen durch den Ring.
  ...flocke(27, 31, 1), ...flocke(38, 40, 2), px(31, 42, "c"), px(24, 41, "c"), px(36, 28, "c"))
