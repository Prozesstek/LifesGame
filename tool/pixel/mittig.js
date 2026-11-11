// Rückt die Zeichnung eines Kreis-Zeichens in die Mitte ihres Bildes:
// misst, wo Bildpunkte stehen, und schiebt sie in ganzen Bildpunkten der
// 64er-Zeichnung, bis links und rechts, oben und unten gleich viel Luft
// bleibt (11.11.2026, AktivesBrett: „die bilder darin zentrieren“).
//   node tool/pixel/mittig.js <bild.png> [--nur-messen]
const { lies, schreibe } = require("./vergroessern.js");

function rahmen({ w, h, px }) {
  let x0 = w, y0 = h, x1 = -1, y1 = -1;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    if (px[(y * w + x) * 4 + 3] === 0) continue;
    if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
  }
  return { x0, y0, x1, y1 };
}

const [pfad, schalter] = process.argv.slice(2);
const gross = lies(pfad);
const f = gross.w / 64;
// zurück auf die 64er-Zeichnung: jeder Bildpunkt liegt f × f mal da
const klein = { w: 64, h: 64, px: Buffer.alloc(64 * 64 * 4) };
for (let y = 0; y < 64; y++) for (let x = 0; x < 64; x++)
  gross.px.copy(klein.px, (y * 64 + x) * 4, ((y * f) * gross.w + x * f) * 4, ((y * f) * gross.w + x * f) * 4 + 4);
const r = rahmen(klein);
const dx = Math.round((63 - r.x1 - r.x0) / 2), dy = Math.round((63 - r.y1 - r.y0) / 2);
console.log(`${pfad}: x ${r.x0}–${r.x1}, y ${r.y0}–${r.y1}, verschiebe um ${dx}, ${dy}`);
if (schalter === "--nur-messen" || (dx === 0 && dy === 0)) process.exit(0);
const neu = { w: 64, h: 64, px: Buffer.alloc(64 * 64 * 4) };
for (let y = 0; y < 64; y++) for (let x = 0; x < 64; x++) {
  const nx = x + dx, ny = y + dy;
  if (nx < 0 || ny < 0 || nx > 63 || ny > 63) continue;
  klein.px.copy(neu.px, (ny * 64 + nx) * 4, (y * 64 + x) * 4, (y * 64 + x) * 4 + 4);
}
schreibe(pfad, neu);
