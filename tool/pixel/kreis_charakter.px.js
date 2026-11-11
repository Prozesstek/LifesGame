// Das Zeichen des Kreises „Charakter“: die Silhouette eines Kopfes mit
// Schultern, wie das Profil-Zeichen in einem Spiel.
pal({ k: "#2a1b24", G: "#fff0a8", g: "#ffc93f", o: "#e89a26", d: "#b56a1c" })

const MX = 31
const kopf = (x, y) => Math.hypot(x + 0.5 - MX, y + 0.5 - 20) <= 12
const schultern = (x, y) => {
  if (y < 37 || y > 60) return false
  // eine Kuppel: oben rund, unten gerade
  return ((x + 0.5 - MX) / 25) ** 2 + ((y + 0.5 - 61) / 23) ** 2 <= 1
}
// eine Lücke zwischen Kopf und Schultern, damit beide getrennt stehen
const luecke = (x, y) => !kopf(x, y) && Math.hypot(x + 0.5 - MX, y + 0.5 - 20) <= 13.6

const silhouette = () => [(c) => {
  for (let x = 0; x < 62; x++) for (let y = 0; y < 62; y++) {
    const inK = kopf(x, y)
    if (!inK && (!schultern(x, y) || luecke(x, y))) continue
    // Licht von oben links
    // ein runder Glanz oben links, zum Rand hin dunkler
    const d = inK
      ? Math.hypot(x + 0.5 - (MX - 4), y + 0.5 - 15) / 13
      : Math.hypot((x + 0.5 - (MX - 9)) / 26, (y + 0.5 - 43) / 17)
    c.px(x, y, d < 0.3 ? "G" : d < 0.75 ? "g" : d < 1.15 ? "o" : "d")
  }
}]

sprite("kreis_charakter", { w: 62, h: 62, outline: "k" }, ...silhouette())
