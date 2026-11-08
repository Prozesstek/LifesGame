// Ein Zauberstab mit Kristall oben: der Griff unten links, der Kristall
// oben rechts, wie bei den anderen Waffen. Gezeichnet mit pxl auf 64 × 64.
//   node <pxl>/bin/pxl.js build tool/pixel/zauberstab.px.js
//
// Alles liegt auf einer Achse, der Diagonale x + y = 63. Jedes Teil fragt
// nur nach a (entlang der Achse, + zum Kristall) und b (quer dazu, − ist
// die Lichtseite oben links). Damit ist jede Form an der Achse gespiegelt.
pal({
  k: "#1a1220",                                           // Umriss
  h: "#3d2418", H: "#6b3f26", W: "#9a6338", w: "#c48a52", // Holz
  l: "#2b1a2e", L: "#5a3448",                             // Lederwicklung
  g: "#7a5a1e", G: "#c9a033", y: "#f2d572",               // Messing
  q: "#123a6b", Q: "#1f6fb0", c: "#3fb4e8", C: "#9de6ff", z: "#f2fdff", // Kristall
})
ramps("khHWw", "klL", "kgGy", "kqQcCz")

const MX = 47, MY = 16                       // Mitte des Kristalls, auf der Achse
const a = (x, y) => ((x - MX) - (y - MY)) / Math.SQRT2
const b = (x, y) => ((x - MX) + (y - MY)) / Math.SQRT2
const flaeche = (test, key) => clip((x, y) => test(a(x, y), b(x, y)), rect(0, 0, 62, 62, key))

// Holz in drei Tönen quer zur Achse: Licht oben links, Schatten unten rechts.
const holz = (von, bis, breit) => [
  flaeche((A, B) => A >= von && A <= bis && Math.abs(B) <= breit, "W"),
  flaeche((A, B) => A >= von && A <= bis && B >= -breit && B < -0.6, "w"),
  flaeche((A, B) => A >= von && A <= bis && B > 0.8 && B <= breit, "H"),
]

// Ein Messingring quer über den Stab.
const ring = (bei, dicke, breit) => [
  flaeche((A, B) => Math.abs(A - bei) <= dicke && Math.abs(B) <= breit, "G"),
  flaeche((A, B) => Math.abs(A - bei) <= dicke && B < -0.6 && B >= -breit, "y"),
  flaeche((A, B) => Math.abs(A - bei) <= dicke && B > 1.2 && B <= breit, "g"),
]

const stab = () => [
  ...holz(-52, -12, 1.8),
  // Maserung: ein dunkler Strich entlang
  flaeche((A, B) => A > -34 && A < -14 && B > -0.2 && B < 0.6 && Math.floor(A) % 7 !== 0, "H"),
]

// Der Griff: Leder schräg gewickelt, zwischen zwei Ringen, unten ein Knauf.
const griff = () => [
  flaeche((A, B) => A >= -51 && A <= -37 && Math.abs(B) <= 2.3, "l"),
  flaeche((A, B) => A >= -51 && A <= -37 && Math.abs(B) <= 2.3 && ((Math.floor(A + B * 0.8) % 3) + 3) % 3 === 0, "L"),
  ...ring(-36, 0.8, 2.6),
  ...ring(-52, 0.8, 2.6),
  // Knauf: eine Kugel, darin ein kleiner Kristall
  flaeche((A, B) => Math.hypot(A + 56, B) <= 3.4, "G"),
  flaeche((A, B) => Math.hypot(A + 56, B) <= 3.4 && B < -1, "y"),
  flaeche((A, B) => Math.hypot(A + 56, B) <= 3.4 && B > 1.6, "g"),
  flaeche((A, B) => Math.abs(A + 56) + Math.abs(B) <= 1.3, "c"),
  flaeche((A, B) => Math.abs(A + 56.5) + Math.abs(B + 0.5) <= 0.4, "z"),
]

// Die Fassung: Kragen, dann zwei Krallen, die den Kristall umgreifen.
const fassung = () => [
  ...ring(-12, 1.2, 3.2),
  ...ring(-9.5, 0.8, 4.2),
  // Krallen: steigen vom Kragen nach aussen und biegen sich an den Kristall
  flaeche((A, B) => A >= -9 && A <= -1 && Math.abs(Math.abs(B) - kralle(A)) <= 0.8, "G"),
  flaeche((A, B) => A >= -9 && A <= -1 && B < 0 && Math.abs(-B - kralle(A)) <= 0.8 && -B < kralle(A), "y"),
  flaeche((A, B) => A >= -2 && A <= -1 && Math.abs(Math.abs(B) - kralle(A)) <= 0.8, "y"),
]
const kralle = (A) => (A < -5 ? 4.4 + (A + 9) * 0.6 : 6.8 - (A + 5) * 0.2)

// Der Kristall: sechseckig, lang, spitz nach oben rechts.
const halb = (A) => (A > 7 ? (6 * (15 - A)) / 8 : A >= -6 ? 6 : (6 * (A + 13)) / 7)
const imKristall = (A, B) => A >= -13 && A <= 15 && Math.abs(B) <= halb(A)
const kristall = () => [
  flaeche(imKristall, "Q"),
  flaeche((A, B) => imKristall(A, B) && B < -2, "c"),
  flaeche((A, B) => imKristall(A, B) && B >= -2 && B < 0, "C"),
  flaeche((A, B) => imKristall(A, B) && B > 2.6, "q"),
  // Spitze und Fuss eine Stufe dunkler: die schrägen Flächen
  flaeche((A, B) => imKristall(A, B) && (A > 8 || A < -7) && B < -2, "Q"),
  flaeche((A, B) => imKristall(A, B) && (A > 8 || A < -7) && B > 0.5, "q"),
  // die Kante und ein Glanz
  flaeche((A, B) => imKristall(A, B) && A > -10 && A < 12 && B >= -1 && B < 0, "z"),
  flaeche((A, B) => Math.abs(A - 3) + Math.abs(B + 4) <= 0.8, "z"),
]

// Funken um den Kristall, gespiegelt an der Achse
const funke = (A, B) => [
  flaeche((a2, b2) => Math.abs(a2 - A) + Math.abs(b2 - B) <= 0.8, "C"),
  flaeche((a2, b2) => Math.abs(a2 - A) + Math.abs(b2 - B) <= 0.3, "z"),
]

sprite("zauberstab", { w: 62, h: 62, outline: "k" },
  ...stab(), ...griff(), ...fassung(), ...kristall(),
  ...funke(18, 0), ...funke(8, -10), ...funke(6, 10),
  glow("Cz", { r: 6, strength: 0.5 }),
)
