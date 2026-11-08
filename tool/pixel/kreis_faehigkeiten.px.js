// Das Zeichen des Kreises „Fähigkeiten“: ein schräg liegendes Zauberbuch,
// auf dem Deckel ein Siegel mit einer Flamme in goldenem Beschlag.
pal({
  k: "#2a1b24",
  B: "#a9bdff", b: "#7493f2", m: "#5f7de0", v: "#4a5fc0", V: "#36459a",
  G: "#fff0a8", g: "#ffc93f", o: "#e89a26", d: "#b56a1c", D: "#7e4614",
  p: "#fff6e2", P: "#e6d3ae", q: "#bfa47c",
  w: "#ffffff", r: "#f04a3a", R: "#b42a2a", y: "#ffd86a",
  n: "#a5532c", N: "#6e3420",
})

const DECKEL = [19, 5, 54, 10, 50, 50, 15, 45]
const innen = (pts, e) => {
  // ein Viereck, um e nach innen gerückt (grob, reicht für schmale Ränder)
  const [x0, y0, x1, y1, x2, y2, x3, y3] = pts
  return [x0 + e, y0 + e, x1 - e, y1 + e, x2 - e, y2 - e, x3 + e, y3 - e]
}

// Hinterdeckel und Seiten, gestaffelt, damit das Buch Dicke hat.
const block = () => [
  poly([10, 10, 59, 16, 55, 59, 8, 54], "d"),
  line(9, 54, 54, 59, "D", 2), line(58, 17, 55, 58, "D", 2),
  poly([12, 9, 57, 14, 53, 55, 11, 50], "p"),
  // Seitenlinien rechts und unten
  ...[0, 2, 4].map((i) => line(53 + i * 0.7, 13 + i, 50 + i * 0.7, 51 + i, "P")),
  ...[0, 2, 4].map((i) => line(17, 47 + i, 50, 52 + i, "P")),
  line(56, 15, 53, 54, "q"), line(14, 50, 52, 55, "q"),
  // Schatten des Deckels auf den Seiten
  line(51, 12, 47, 51, "q"), line(16, 46, 49, 51, "q"),
]

// Der Deckel: Licht von oben links, zur Ecke unten rechts dunkler.
const deckel = () => [
  poly(DECKEL, "b"),
  clip(DECKEL, poly([15, 30, 54, 36, 50, 50, 15, 45], "m")),
  clip(DECKEL, poly([15, 40, 54, 46, 50, 50, 15, 45], "v")),
  line(20, 6, 53, 11, "B", 2), line(17, 8, 15, 42, "B"),
  line(52, 12, 49, 49, "V", 2), line(16, 45, 49, 50, "V", 2),
  // goldene Einlage, ein Rahmen drei Felder nach innen
  poly(innen(DECKEL, 4), "o"), poly(innen(DECKEL, 5), "b"),
  clip(innen(DECKEL, 5), poly([15, 30, 54, 36, 50, 50, 15, 45], "m")),
  clip(innen(DECKEL, 5), poly([15, 40, 54, 46, 50, 50, 15, 45], "v")),
  line(24, 9, 49, 13, "g"), line(22, 10, 20, 40, "g"),
]

// Beschläge an den Ecken, mit Nieten.
const ecken = () => [
  poly([44, 9, 55, 10, 54, 21], "g"), line(45, 9, 54, 10, "G"),
  line(54, 11, 53, 20, "d"), px(51, 12, "G"), px(52, 12, "o"),
  poly([50, 51, 52, 39, 40, 50], "o"), line(51, 41, 50, 50, "d"),
  line(41, 50, 49, 50, "d"), px(48, 47, "G"),
  // Lesezeichen
  poly([54, 22, 60, 23, 59, 29, 53, 28], "n"), line(54, 23, 59, 24, "G"),
  poly([53, 31, 59, 32, 58, 38, 52, 37], "N"), line(53, 32, 58, 33, "n"),
]

// Der Rücken: rund gewölbt, mit zwei erhabenen Bünden.
const ruecken = () => [
  poly([11, 7, 20, 5, 16, 46, 7, 49], "o"),
  line(12, 8, 8, 47, "G", 2), line(14, 7, 10, 47, "g", 2),
  line(19, 6, 15, 45, "d", 2),
  ...[15, 36].map((y) => [
    line(8, y + 1.5, 19, y - 1, "D", 2), line(8, y, 19, y - 2.5, "G"),
  ]).flat(),
]

// Das Siegel: Goldring mit Kerbe, weißes Feld, Flamme; links und rechts
// greifen goldene Ranken nach dem Ring.
const MX = 33, MY = 28
const ranke = (s) => [
  line(MX + s * 11, MY, MX + s * 15, MY, "g", 2),
  line(MX + s * 15, MY, MX + s * 17, MY - 3, "g"),
  line(MX + s * 15, MY + 1, MX + s * 17, MY + 4, "g"),
  px(MX + s * 18, MY - 4, "G"), px(MX + s * 18, MY + 5, "G"),
  line(MX + s * 9, MY - 6, MX + s * 13, MY - 9, "o"),
  line(MX + s * 9, MY + 6, MX + s * 13, MY + 9, "o"),
]
const siegel = () => [
  ...ranke(-1), ...ranke(1),
  // Strahlen
  ...[[0, -15], [-7, -13], [7, -13], [0, 15]].map(([x, y]) =>
    poly([MX + x - 1, MY + y + (y < 0 ? 1 : -1), MX + x + 1, MY + y + (y < 0 ? 1 : -1), MX + x, MY + y - (y < 0 ? 1 : -1)], "g")),
  circ(MX, MY, 11, "d"), circ(MX, MY, 10, "g"),
  clip([MX, MY, 10], poly([MX - 11, MY - 11, MX + 11, MY - 11, MX - 11, MY + 4], "G")),
  circ(MX, MY, 8, "o"), circ(MX, MY, 7, "w"),
  clip([MX, MY, 7], poly([MX + 7, MY - 7, MX + 7, MY + 7, MX - 7, MY + 7], "p")),
  (c) => {
    for (let x = MX - 7; x <= MX + 7; x++) for (let y = MY - 8; y <= MY + 6; y++) {
      const dy = y + 0.5 - (MY + 2)
      const w = dy >= 0 ? Math.sqrt(Math.max(0, 20 - dy * dy)) : 4.5 * Math.max(0, 1 - (-dy / 9) ** 1.5)
      const sway = dy < 0 ? Math.sin(-dy * 0.4) : 0
      const dx = x + 0.5 - MX - sway
      if (Math.abs(dx) > w) continue
      const iy = y + 0.5 - (MY + 3)
      const iw = iy >= 0 ? Math.sqrt(Math.max(0, 4 - iy * iy)) : 2 * Math.max(0, 1 - (-iy / 5) ** 1.3)
      const kern = Math.abs(x + 0.5 - MX) <= iw
      c.px(x, y, kern ? "y" : dx > 1.5 ? "R" : "r")
    }
  },
]

sprite("kreis_faehigkeiten", { w: 62, h: 62, outline: "k" },
  ...block(), ...deckel(), ...ecken(), ...ruecken(), ...siegel())
