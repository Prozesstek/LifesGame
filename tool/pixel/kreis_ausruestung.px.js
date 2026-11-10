// Das Zeichen des Kreises „Ausrüstung“: ein Plattenharnisch von vorn, mit
// Goldbeschlag, Schulterstücken, Gürtel und Schurz — was man anlegt.
pal({
  k: "#2a1b24",
  W: "#f6f8fc", S: "#d9dfea", s: "#aeb8cb", t: "#7f8aa3", T: "#545d76",
  G: "#fff0a8", g: "#ffc93f", o: "#e89a26", d: "#b56a1c",
  n: "#8a4a2a", N: "#5e3020", r: "#e8423a", R: "#9e2430", w: "#ffffff",
})

const MX = 31
const dxOf = (x) => Math.abs(x + 0.5 - MX)
const links = (x) => x + 0.5 < MX

// Rumpf: breit an der Brust, schmal zur Taille, oben ein runder Halsausschnitt.
const breite = (y) => y < 18 ? 15 + (y - 10) * 0.25 : 17 - (y - 18) * 0.2
const hals = (x, y) => y < 9 + 5.5 * Math.cos(Math.min(dxOf(x) / 8, 1) * Math.PI / 2) && dxOf(x) < 8
const imRumpf = (x, y) => y >= (dxOf(x) < 9 ? 10 : 18) && y <= 45 && dxOf(x) <= breite(y) && !hals(x, y)

const rumpf = () => [
  (c) => {
    for (let x = 0; x < 62; x++) for (let y = 0; y < 62; y++) {
      if (!imRumpf(x, y)) continue
      const kante = !imRumpf(x - 1, y) || !imRumpf(x + 1, y) || !imRumpf(x, y - 1)
      const amHals = kante && hals(x, y - 1)
      if (kante || (hals(x, y - 2) && dxOf(x) < 8)) {
        c.px(x, y, amHals || hals(x, y - 2) ? (links(x) ? "G" : "g") : links(x) ? "g" : "o")
        continue
      }
      const dx = dxOf(x)
      c.px(x, y, links(x) ? (dx < 3 ? "W" : dx < 10 ? "S" : "s") : (dx < 6 ? "s" : dx < 12 ? "t" : "T"))
    }
  },
  // Grat in der Mitte
  vline(30, 15, 14, "W"), vline(31, 15, 14, "t"),
  // Rundung der Brust
  (c) => {
    for (let dx = 2; dx <= 13; dx++) {
      const y = Math.round(29 + (dx - 7.5) ** 2 / 12)
      c.px(MX - 1 - dx, y, "t"); c.px(MX + dx, y, "T")
      c.px(MX - 1 - dx, y + 1, "W"); c.px(MX + dx, y + 1, "S")
    }
  },
  // Bauchplatten
  (c) => {
    for (const y of [34, 39]) for (let x = 0; x < 62; x++) {
      if (!imRumpf(x - 1, y) || !imRumpf(x + 1, y)) continue
      c.px(x, y, "T"); c.px(x, y + 1, links(x) ? "W" : "s")
    }
  },
]

// Schulterstücke: drei geschwungene Lagen, die vom Hals über die Schulter
// nach außen abfallen, die unterste mit Goldrand und Nieten.
const schulter = (sd) => {
  const ansatz = sd < 0 ? MX - 8 : MX + 7
  const uOf = (x) => sd < 0 ? ansatz - x : x - ansatz
  const form = (u) => {
    let top = 10 + (Math.max(u, 0) / 19) ** 1.3 * 13
    let h = 12 - Math.max(u, 0) * 0.1
    if (u > 14) { const r = (u - 14) ** 2 * 0.45; top += r; h -= 2 * r }
    return [top, h]
  }
  return [(c) => {
    for (let x = 0; x < 62; x++) {
      const u = uOf(x)
      if (u < 0 || u > 19) continue
      const [top, h] = form(u)
      for (let y = Math.ceil(top); y < top + h; y++) {
        const b = (y - top) / h
        const lage = b < 0.34 ? 0 : b < 0.66 ? 1 : 2
        const start = [0, 0.34, 0.66][lage] * h + top
        const ersteZeile = y - start < 1
        const letzte = y + 1 >= top + h
        const licht = (sd < 0 ? 1 : 0) + (lage === 0 ? 1 : 0) - (u > 11 ? 1 : 0)
        let f = licht >= 2 ? "W" : licht === 1 ? "S" : licht === 0 ? "s" : "t"
        if (lage === 2) f = letzte ? "d" : ersteZeile ? "G" : sd < 0 ? "g" : "o"
        else if (ersteZeile && lage > 0) f = "T"
        else if (y - start < 2 && lage > 0) f = "W"
        c.px(x, y, f)
      }
    }
    // Nieten auf dem Goldrand
    for (const u of [1, 8, 15]) {
      const x = sd < 0 ? ansatz - u : ansatz + u
      const [top, h] = form(u)
      c.px(x, Math.floor(top + h * 0.83), "W")
    }
  }]
}

// Wappen in der Brust: ein Goldkreis mit rotem Stein.
const wappen = () => [
  circ(MX - 0.5, 22, 5, "d"), circ(MX - 0.5, 22, 4, "g"),
  circ(MX - 0.5, 22, 2.5, "R"), rect(29, 20, 2, 2, "r"), px(29, 20, "w"),
]

// Gürtel mit Schnalle, darunter der Schurz aus zwei Reihen Platten.
const unterteil = () => [
  rect(MX - 14, 44, 28, 5, "n"), hline(MX - 14, 44, 28, "d"), hline(MX - 14, 48, 28, "N"),
  rect(MX - 4, 43, 8, 7, "o"), rect(MX - 3, 44, 6, 5, "g"), rect(MX - 1, 45, 2, 3, "n"),
  hline(MX - 3, 44, 6, "G"),
  ...[[49, 13], [54, 11]].map(([y0, hw]) => (c) => {
    for (let x = MX - hw; x < MX + hw; x++) for (let y = y0; y < y0 + 5; y++) {
      const fx = (x + hw - MX) % 6
      const unten = y === y0 + 4
      c.px(x, y, unten ? (links(x) ? "g" : "o") : fx === 5 ? "T" : links(x) ? (y === y0 ? "W" : "S") : "s")
    }
  }),
]

sprite("_rumpf", { w: 62, h: 62, outline: "k" }, ...rumpf(), ...wappen(), ...unterteil())
sprite("_schulter_l", { w: 62, h: 62, outline: "k" }, ...schulter(-1))
sprite("_schulter_r", { w: 62, h: 62, outline: "k" }, ...schulter(1))

sprite("kreis_ausruestung", { w: 64, h: 64 },
  stamp("_rumpf", 0, 1), stamp("_schulter_l", 0, 1), stamp("_schulter_r", 0, 1))
