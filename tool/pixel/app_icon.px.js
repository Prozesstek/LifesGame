// Das Startsymbol der App, nach AktivesBretts Vorlage vom 11.11.2026:
// ein Wappen mit „LG“ über dem Berg in der Abenddämmerung, darunter ein
// Holzschild mit „LIFES GAME“, alles im Holzrahmen.
pal({
  k: "#1a1020", // Umriss
  // Holz, dunkel nach hell
  a: "#3b2416", b: "#6b4226", c: "#8f5a32", e: "#b47a45", f: "#d39a5e",
  // Himmel, oben nach unten
  1: "#241a3d", 2: "#3a2652", 3: "#63305f", 4: "#a24562", 5: "#e07a5c", 6: "#f3b26b",
  // Berg
  m: "#2a1c3a", M: "#433055", W: "#e8e2f0", V: "#a99cc4",
  // Wappen
  r: "#7c1f30", R: "#b8323f", s: "#e8605c",
  d: "#9a5a1a", g: "#f2b53a", G: "#ffe9a0",
  // Blätter
  l: "#2f6a3a", L: "#5fa35a", D: "#1d4229",
  // Schrift auf dem Schild
  x: "#fff3dc", y: "#f6d9a8", z: "#d6a26c",
  // Sterne
  o: "#ffd36b", O: "#fff6c8",
})

const S = 64
const MX = 32

// ein abgerundetes Quadrat, um `rand` eingerückt
const feld = (x, y, rand, ecke = 10) => {
  if (x < rand || y < rand || x >= S - rand || y >= S - rand) return false
  const a = ecke - rand
  const lx = Math.max(rand + a - x - 0.5, 0, x + 0.5 - (S - rand - a))
  const ly = Math.max(rand + a - y - 0.5, 0, y + 0.5 - (S - rand - a))
  return lx * lx + ly * ly <= a * a
}

// zwei Berge, der hintere höher
const berg = (x, y) => {
  const h1 = 18 + Math.abs(x - 40) * 0.9 // hinten, Gipfel bei 40
  const h2 = 24 + Math.abs(x - 16) * 0.8 // vorn links
  return { hinten: y >= h1, vorn: y >= h2, h1, h2 }
}

const himmel = (y) => (y < 9 ? "1" : y < 15 ? "2" : y < 21 ? "3" : y < 27 ? "4" : y < 32 ? "5" : "6")

// Versatz: zeichnet um o Bildpunkte verschoben, für die adaptive Fassung
const versetzt = (c, o) => ({
  px: (x, y, k) => c.px(x + o, y + o, k),
  circ: (x, y, r, k) => c.circ(x + o, y + o, r, k),
  rect: (x, y, w, h, k) => c.rect(x + o, y + o, w, h, k),
})

// der Hintergrund; ohne Rahmen läuft er o Bildpunkte über jeden Rand
const bild = (rahmen = true, o = 0) => [(c0) => {
  const c = versetzt(c0, o)
  for (let x = -o; x < S + o; x++) for (let y = -o; y < S + o; y++) {
    if (rahmen) {
    if (!feld(x, y, 0)) continue
    // Holzrahmen: Umriss, Holz mit Licht oben links, innen dunkel
    if (!feld(x, y, 1)) { c.px(x, y, "k"); continue }
    if (!feld(x, y, 2)) { c.px(x, y, x + y < 60 ? "f" : "e"); continue }
    if (!feld(x, y, 3)) { c.px(x, y, (x * 7 + y * 3) % 11 === 0 ? "b" : "c"); continue }
    if (!feld(x, y, 4)) { c.px(x, y, "a"); continue }
    }
    // Himmel mit gerasterten Übergängen: zwei Zeilen je Wechsel
    let h = himmel(y)
    const grenze = [9, 15, 21, 27, 32].find((g) => y >= g && y < g + 2)
    if (grenze !== undefined) {
      const dicht = y === grenze ? (x + y) % 2 === 0 : x % 4 === y % 4
      if (dicht) h = himmel(grenze - 1)
    }
    c.px(x, y, h)
    const b = berg(x, y)
    if (b.hinten) {
      const schnee = y < b.h1 + 4 - (x % 3 === 0 ? 1 : 0)
      c.px(x, y, schnee ? (x < 40 ? "W" : "V") : x < 40 ? "M" : "m")
    }
    if (b.vorn) {
      const schnee = y < b.h2 + 3 - (x % 2)
      c.px(x, y, schnee ? (x < 16 ? "W" : "V") : x < 16 ? "M" : "m")
    }
    // eine Wiese davor, oben mit Halmen
    const wiese = 35 + Math.round(Math.sin(x / 5) * 1.5)
    if (y >= wiese) c.px(x, y, y === wiese ? (x % 3 ? "L" : "l") : "l")
    if (y === wiese - 1 && x % 4 === 1) c.px(x, y, "L")
  }
  // Blumen im Gras unter dem Schild
  for (const [x, y, f] of [[5, 57, "o"], [11, 59, "s"], [52, 59, "O"], [58, 56, "o"], [24, 59, "o"], [40, 59, "s"]]) c.px(x, y, f)
  // ein Mond oben links, warm
  c.circ(11, 11, 4, "O"); c.circ(13, 10, 3, "1"); c.px(9, 9, "o"); c.px(8, 12, "o")
  for (const [x, y] of [[18, 14], [50, 7], [55, 13], [46, 11], [21, 6], [7, 19]]) c.px(x, y, "O")
  // ein funkelnder Stern mit vier Strahlen
  c.px(52, 22, "O"); c.px(51, 22, "o"); c.px(53, 22, "o"); c.px(52, 21, "o"); c.px(52, 23, "o")
  for (const [x, y] of [[12, 6], [52, 16], [44, 5]]) c.px(x, y, "o")
}]

// das Wappen: oben gerade, unten in zwei gleichen Bögen zur Spitze
const wappenForm = (x, y) => {
  const dx = Math.abs(x + 0.5 - MX)
  if (y < 4 || y > 31) return false
  if (y < 19) return dx <= 11
  const t = (y + 0.5 - 19) / 13 // 0 oben, 1 an der Spitze
  // zuletzt gerade zur Spitze, ein Bildpunkt je Zeile
  return dx <= Math.min(11 * (1 - t * t), 32 - y)
}
// um e Bildpunkte eingerückt: die Nachbarn in den vier Richtungen liegen drin
const wappen = (x, y, e) => {
  for (const [ox, oy] of [[e, 0], [-e, 0], [0, e], [0, -e]]) {
    if (!wappenForm(x + ox, y + oy)) return false
  }
  return true
}

const schild = (o = 0) => [(c0) => {
  const c = versetzt(c0, o)
  for (let x = 0; x < S; x++) for (let y = 0; y < S; y++) {
    if (!wappen(x, y, 0)) continue
    if (!wappen(x, y, 1)) { c.px(x, y, "k"); continue }
    if (!wappen(x, y, 2)) { c.px(x, y, x < MX ? (y < 20 ? "G" : "g") : y < 12 ? "g" : "d"); continue }
    const l = (x - MX) + (y - 8) * 1.2
    let t = l < -9 ? "s" : l < 7 ? "R" : "r"
    if ((x + y) % 4 === 0 && (x - y + 64) % 4 === 0 && t === "R") t = "r"
    c.px(x, y, t)
  }
  // ein Glanz auf dem Goldrand oben links
  c.px(MX - 10, 6, "O"); c.px(MX - 9, 5, "O")
}]

// eine kleine Tanne mit Schnee auf den Spitzen, dunkler Rand
sprite("_tanne", { w: 11, h: 18, outline: "k" }, (c) => {
  const M = 5
  // drei Stufen, jede unten breiter
  for (const [y0, y1, w0, w1] of [[0, 5, 0, 3], [5, 10, 1, 4], [10, 15, 2, 5]]) {
    for (let y = y0; y <= y1; y++) {
      const halb = Math.round(w0 + (w1 - w0) * (y - y0) / (y1 - y0))
      for (let x = M - halb; x <= M + halb; x++) {
        // unter jeder Stufe ein Schatten der Stufe darüber
        const schatten = y0 > 0 && y <= y0 + 1 && Math.abs(x - M) < halb
        c.px(x, y, schatten ? (x <= M ? "l" : "D") : x <= M ? "L" : x === M + halb ? "D" : "l")
      }
      // Schnee auf der linken Kante der Stufe
      if (y <= y0 + 1) c.px(M - halb, y, "W")
    }
  }
  c.px(M, 0, "W")
  c.rect(M - 1, 16, 2, 2, "b"); c.px(M - 1, 16, "c")
})

// das Holzschild unten, zwei Bretter mit Maserung und Nägeln
const brett = (o = 0) => [(c0) => {
  const c = versetzt(c0, o)
  const x0 = 7, x1 = 56, y0 = 34, y1 = 58
  for (let x = x0; x <= x1; x++) for (let y = y0; y <= y1; y++) {
    if (x === x0 || x === x1 || y === y0 || y === y1) { c.px(x, y, "k"); continue }
    if (y === 46) { c.px(x, y, "a"); continue }
    const oben = y === y0 + 1 || y === 47
    const unten = y === y1 - 1 || y === 45
    const linie = Math.round(Math.sin((x + (y < 46 ? 0 : 9)) / 4) * 1.5)
    const maser = (y === 40 + linie || y === 52 + linie) && x % 5 !== 0
    c.px(x, y, oben ? "e" : unten ? "b" : maser ? "b" : x < x0 + 2 ? "e" : "c")
  }
  for (const [x, y] of [[9, 36], [53, 36], [9, 55], [53, 55]]) {
    c.px(x, y, "z"); c.px(x + 1, y, "a"); c.px(x, y + 1, "a"); c.px(x + 1, y + 1, "a")
  }
}]

// eigene fette Buchstaben, 9 hoch, Striche zwei Bildpunkte breit
const Z = {
  L: ["##....","##....","##....","##....","##....","##....","##....","######","######"],
  I: ["####",".##.",".##.",".##.",".##.",".##.",".##.",".##.","####"],
  F: ["######","######","##....","##....","#####.","#####.","##....","##....","##...."],
  E: ["######","######","##....","##....","#####.","#####.","##....","######","######"],
  S: [".#####","######","##....","#####.",".#####","....##","....##","######","#####."],
  G: [".#####","######","##....","##....","##.###","##.###","##..##","######",".#####"],
  A: [".####.","######","##..##","##..##","######","######","##..##","##..##","##..##"],
  M: ["##....##","###..###","########","##.##.##","##.##.##","##....##","##....##","##....##","##....##"],
}
// ein Wort als Raster: oben hell, Mitte Grundton, unten dunkel
const wort = (w, hell, mitte, dunkel) => {
  const zeilen = []
  for (let y = 0; y < 9; y++) {
    const farbe = y < 2 ? hell : y > 6 ? dunkel : mitte
    zeilen.push([...w].map((b) => Z[b][y].replaceAll("#", farbe)).join("."))
  }
  return zeilen.join("\n")
}
sprite("_lg", { outline: "k" }, wort("LG", "G", "g", "d"))
sprite("_lifes", { outline: "k" }, wort("LIFES", "x", "y", "z"))
sprite("_game", { outline: "k" }, wort("GAME", "x", "y", "z"))

sprite("app_icon", { w: S, h: S },
  ...bild(),
  stamp("_tanne", 7, 16), stamp("_tanne", 46, 16, { flip: "x" }),
  ...schild(),
  stamp("_lg", 25, 9),
  ...brett(),
  stamp("_lifes", 15, 35), stamp("_game", 16, 47),
)

// Für Android ab Version 8 in zwei Ebenen, je 96 × 96 (108 dp, die
// mittleren 64 sind die 72 dp, die man sieht): hinten Himmel, Berg und
// Wiese bis an jeden Rand, vorn Tannen, Wappen und Schild. Die Form
// schneidet der Launcher, deshalb ohne eigenen Rahmen.
const A = 16
sprite("app_icon_hinten", { w: S + 2 * A, h: S + 2 * A }, ...bild(false, A))
sprite("app_icon_vorn", { w: S + 2 * A, h: S + 2 * A },
  stamp("_tanne", 7 + A, 16 + A), stamp("_tanne", 46 + A, 16 + A, { flip: "x" }),
  ...schild(A),
  stamp("_lg", 25 + A, 9 + A),
  ...brett(A),
  stamp("_lifes", 15 + A, 35 + A), stamp("_game", 16 + A, 47 + A),
)
