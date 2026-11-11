// Legt das Startsymbol (`app_icon.px.js`) in alle Größen, die Android und
// die Web-Fassung brauchen. Erst pxl bauen, dann:
//   node tool/pixel/app_icon.js tool/pixel/out/sprites/app_icon.png
//
// Verkleinert und vergrößert wird über Unterabtastung (4 × 4 Proben je
// Bildpunkt, hart aus dem Original): ganze Vielfache bleiben scharf,
// krumme bekommen nur an den Kanten eine Zwischenfarbe.
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const { lies } = require("./vergroessern.js");

const crcTafel = Array.from({ length: 256 }, (_, n) => {
  for (let k = 0; k < 8; k++) n = n & 1 ? 0xedb88320 ^ (n >>> 1) : n >>> 1;
  return n >>> 0;
});
const crc = (b) => {
  let c = 0xffffffff;
  for (const x of b) c = crcTafel[(c ^ x) & 255] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const stueck = (typ, daten) => {
  const kopf = Buffer.alloc(4); kopf.writeUInt32BE(daten.length);
  const rumpf = Buffer.concat([Buffer.from(typ, "latin1"), daten]);
  const ende = Buffer.alloc(4); ende.writeUInt32BE(crc(rumpf));
  return Buffer.concat([kopf, rumpf, ende]);
};
const schreibe = (pfad, W, H, px) => {
  const roh = Buffer.alloc(H * (W * 4 + 1));
  for (let y = 0; y < H; y++) px.copy(roh, y * (W * 4 + 1) + 1, y * W * 4, (y + 1) * W * 4);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 6;
  fs.mkdirSync(path.dirname(pfad), { recursive: true });
  fs.writeFileSync(pfad, Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    stueck("IHDR", ihdr),
    stueck("IDAT", zlib.deflateSync(roh, { level: 9 })),
    stueck("IEND", Buffer.alloc(0)),
  ]));
};

// Ein Bild der Größe `seite`; das Symbol liegt mittig und ist `innen` groß,
// außen herum `grund` (RGBA) oder durchsichtig. `voll` füllt die runden
// Ecken des Symbols mit dem Grund, für Formen, die der Launcher schneidet.
const bild = (src, seite, innen, grund = [0, 0, 0, 0], voll = false) => {
  const px = Buffer.alloc(seite * seite * 4);
  const rand = (seite - innen) / 2, N = 4;
  for (let y = 0; y < seite; y++) for (let x = 0; x < seite; x++) {
    let r = 0, g = 0, b = 0, a = 0;
    for (let sy = 0; sy < N; sy++) for (let sx = 0; sx < N; sx++) {
      const u = ((x + (sx + 0.5) / N) - rand) / innen * src.w;
      const v = ((y + (sy + 0.5) / N) - rand) / innen * src.h;
      let p = grund;
      if (u >= 0 && v >= 0 && u < src.w && v < src.h) {
        const q = (Math.floor(v) * src.w + Math.floor(u)) * 4;
        const s = [src.px[q], src.px[q + 1], src.px[q + 2], src.px[q + 3]];
        p = voll && s[3] < 255 ? grund : s
      }
      // vormultipliziert mitteln
      const al = p[3] / 255;
      r += p[0] * al; g += p[1] * al; b += p[2] * al; a += al;
    }
    const o = (y * seite + x) * 4;
    px[o + 3] = Math.round((a / (N * N)) * 255);
    if (a > 0) { px[o] = Math.round(r / a); px[o + 1] = Math.round(g / a); px[o + 2] = Math.round(b / a); }
  }
  return px;
};

const quelle = lies(process.argv[2] || "tool/pixel/out/sprites/app_icon.png");
const res = "android/app/src/main/res";
// Der Grund hinter dem Symbol: das dunkle Holz des Rahmens
const HOLZ = [0x3b, 0x24, 0x16, 255];

for (const [ordner, f] of [["mdpi", 1], ["hdpi", 1.5], ["xhdpi", 2], ["xxhdpi", 3], ["xxxhdpi", 4]]) {
  // klassisch: das ganze Symbol auf 48 dp
  const s = 48 * f;
  schreibe(`${res}/mipmap-${ordner}/ic_launcher.png`, s, s, bild(quelle, s, s));
  // adaptiv (ab Android 8): 108 dp, sichtbar sind die mittleren 72
  const v = 108 * f;
  schreibe(`${res}/mipmap-${ordner}/ic_launcher_foreground.png`, v, v, bild(quelle, v, 72 * f, [0, 0, 0, 0], true));
}

// Web: normal und „maskable“ (Inhalt in den mittleren 80 %)
schreibe("web/icons/Icon-192.png", 192, 192, bild(quelle, 192, 192));
schreibe("web/icons/Icon-512.png", 512, 512, bild(quelle, 512, 512));
schreibe("web/icons/Icon-maskable-192.png", 192, 192, bild(quelle, 192, 154, HOLZ, true));
schreibe("web/icons/Icon-maskable-512.png", 512, 512, bild(quelle, 512, 410, HOLZ, true));
schreibe("web/favicon.png", 32, 32, bild(quelle, 32, 32));
// für den Play Store: 512 × 512, ohne Durchsichtiges
schreibe("docs/store/app_icon_512.png", 512, 512, bild(quelle, 512, 512, HOLZ, true));
console.log("Startsymbol in allen Größen abgelegt.");
