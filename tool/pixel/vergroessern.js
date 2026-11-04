// Legt ein Bild aus pxl als Asset ab: 64 × 64 hart auf 256 × 256, wie
// jedes gezeichnete Bild im Projekt (`PixelArt`). pxl vergrössert nur
// seine Vorschau, `sprites/<name>.png` bleibt in Originalgrösse.
//   node tool/pixel/vergroessern.js <quelle.png> <ziel.png>
const fs = require("fs");
const zlib = require("zlib");

const FAKTOR = 4;

function lies(pfad) {
  const d = fs.readFileSync(pfad);
  let o = 8, w, h, tiefe, art, pal, trns, idat = [];
  while (o < d.length) {
    const n = d.readUInt32BE(o), typ = d.toString("latin1", o + 4, o + 8);
    const c = d.subarray(o + 8, o + 8 + n);
    if (typ === "IHDR") {
      w = c.readUInt32BE(0); h = c.readUInt32BE(4); tiefe = c[8]; art = c[9];
      if (c[12] !== 0) throw new Error("Interlace wird nicht gelesen");
    } else if (typ === "PLTE") pal = c;
    else if (typ === "tRNS") trns = c;
    else if (typ === "IDAT") idat.push(c);
    o += 12 + n;
  }
  const kanaele = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[art];
  const bits = kanaele * tiefe, zeile = Math.ceil((w * bits) / 8);
  const bpp = Math.max(1, bits >> 3);
  const roh = zlib.inflateSync(Buffer.concat(idat));
  const raus = Buffer.alloc(w * h * 4);
  let vorher = Buffer.alloc(zeile);
  for (let y = 0; y < h; y++) {
    const f = roh[y * (zeile + 1)];
    const z = Buffer.from(roh.subarray(y * (zeile + 1) + 1, (y + 1) * (zeile + 1)));
    for (let i = 0; i < zeile; i++) {
      const a = i >= bpp ? z[i - bpp] : 0, b = vorher[i];
      const c = i >= bpp ? vorher[i - bpp] : 0;
      if (f === 1) z[i] += a;
      else if (f === 2) z[i] += b;
      else if (f === 3) z[i] += (a + b) >> 1;
      else if (f === 4) {
        const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        z[i] += pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      }
    }
    vorher = z;
    for (let x = 0; x < w; x++) {
      const q = (y * w + x) * 4;
      if (art === 3) {
        const pro = 8 / tiefe, byte = z[Math.floor(x / pro)];
        const i = (byte >> (8 - tiefe - (x % pro) * tiefe)) & ((1 << tiefe) - 1);
        raus[q] = pal[i * 3]; raus[q + 1] = pal[i * 3 + 1]; raus[q + 2] = pal[i * 3 + 2];
        raus[q + 3] = trns && i < trns.length ? trns[i] : 255;
      } else if (art === 6 && tiefe === 8) {
        z.copy(raus, q, x * 4, x * 4 + 4);
      } else throw new Error("Farbart " + art + "/" + tiefe + " wird nicht gelesen");
    }
  }
  return { w, h, px: raus };
}

const crcTafel = Array.from({ length: 256 }, (_, n) => {
  for (let k = 0; k < 8; k++) n = n & 1 ? 0xedb88320 ^ (n >>> 1) : n >>> 1;
  return n >>> 0;
});
function crc(b) {
  let c = 0xffffffff;
  for (const x of b) c = crcTafel[(c ^ x) & 255] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function stueck(typ, daten) {
  const kopf = Buffer.alloc(4); kopf.writeUInt32BE(daten.length);
  const rumpf = Buffer.concat([Buffer.from(typ, "latin1"), daten]);
  const ende = Buffer.alloc(4); ende.writeUInt32BE(crc(rumpf));
  return Buffer.concat([kopf, rumpf, ende]);
}
function schreibe(pfad, { w, h, px }) {
  const W = w * FAKTOR, H = h * FAKTOR, roh = Buffer.alloc(H * (W * 4 + 1));
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const q = (Math.floor(y / FAKTOR) * w + Math.floor(x / FAKTOR)) * 4;
      px.copy(roh, y * (W * 4 + 1) + 1 + x * 4, q, q + 4);
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 6;
  fs.writeFileSync(pfad, Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    stueck("IHDR", ihdr),
    stueck("IDAT", zlib.deflateSync(roh, { level: 9 })),
    stueck("IEND", Buffer.alloc(0)),
  ]));
}

module.exports = { lies, schreibe };
if (require.main === module) {
  const [quelle, ziel] = process.argv.slice(2);
  schreibe(ziel, lies(quelle));
}
