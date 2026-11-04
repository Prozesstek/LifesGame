// Bogen aus verwachsenem Holz — 64 × 64 wie jedes Bild in Lifes Game.
// Ein Schuss in 20 Bildern: Ruhe, Spannen, Halten, Loslassen. Das stehende
// Bild assets/Waffen/Boegen/Wurzelbogen.png ist Bild 0, 4× vergrößert.
pal({
  k: "#1d1410",                                           // Umriss
  W: "#3a2414", w: "#6a4428", v: "#9b6a3c", V: "#c69458", // Holz
  G: "#2c5a2a", g: "#4f9440", l: "#9ad25e",               // Ranke und Blatt
  m: "#a8e8d4",                                           // Sehne
  T: "#1f7a6a", S: "#4fdcb0", s: "#c8fff0", x: "#ffffff", // Geisterlicht
})
ramps("kWwvV", "kGgl", "kTSsx")

sprite("_blatt", `
  ...ll
  .ggl.
  Gggl.
  GGg..
  G....`)
sprite("_blatt_klein", `
  .gl
  Gg.
  G..`)

// ---- Rechnung -------------------------------------------------------------

const BILDER = 20
// Wie weit gespannt (0 locker, 1 voll), wie lange gehalten, wie die Sehne
// nach dem Schuss nachschwingt.
function ablauf(f) {
  if (f < 3) return { zug: 0, schwing: 0, schuss: -1, halten: 0 }
  if (f < 10) {
    const t = (f - 2) / 7
    return { zug: t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) ** 2 / 2, schwing: 0, schuss: -1, halten: 0 }
  }
  if (f < 15) return { zug: 1, schwing: 0, schuss: -1, halten: (f - 9) / 5 }
  const nach = f - 15 // 0..4
  return { zug: 0, schwing: [4, -3, 2, -1, 0][nach], schuss: nach, halten: 0 }
}

const bez = (A, C, B, t) => [
  (1 - t) ** 2 * A[0] + 2 * (1 - t) * t * C[0] + t * t * B[0],
  (1 - t) ** 2 * A[1] + 2 * (1 - t) * t * C[1] + t * t * B[1],
]
const aussen = (A, C, B, t) => {
  const dx = 2 * (1 - t) * (C[0] - A[0]) + 2 * t * (B[0] - C[0])
  const dy = 2 * (1 - t) * (C[1] - A[1]) + 2 * t * (B[1] - C[1])
  const l = Math.hypot(dx, dy)
  return [-dy / l, dx / l]
}
const dicke = (t) => 1.2 + 2.6 * Math.sin(Math.PI * t) ** 0.8
const R = Math.SQRT1_2 // Diagonale, zum Schützen hin (+x, +y)

// ---- Zeichnen -------------------------------------------------------------

anim("bogen", { w: 64, h: 64, frames: BILDER, fps: 12 }, (c) => {
  const f = c.frame
  const { zug, schwing, schuss, halten } = ablauf(f)
  // Wie stark es leuchtet: atmet in Ruhe, wächst beim Spannen.
  const atem = 0.5 + 0.5 * Math.sin((f / BILDER) * Math.PI * 4)
  const licht = Math.min(1, 0.25 + 0.2 * atem + zug * 0.55 + halten * 0.3)

  // Die Spitzen biegen sich beim Spannen zum Schützen hin.
  const A = [54 + 1.5 * zug, 7 + 4 * zug]
  const B = [7 + 4 * zug, 54 + 1.5 * zug]
  const C = [9, 9]
  const P = (t) => bez(A, C, B, t)
  const N = (t) => aussen(A, C, B, t)

  // Sehne: an beiden Spitzen fest, in der Mitte die Kerbe.
  const oben = [Math.round(A[0] - 1), Math.round(A[1] + 2)]
  const unten = [Math.round(B[0] + 2), Math.round(B[1] - 1)]
  const mitte = [(oben[0] + unten[0]) / 2, (oben[1] + unten[1]) / 2]
  const kerbe = [
    Math.round(mitte[0] + R * zug * 10 + schwing * R),
    Math.round(mitte[1] + R * zug * 10 + schwing * R),
  ]
  const sehne = licht > 0.7 ? "s" : "m"
  c.line(oben[0], oben[1], kerbe[0], kerbe[1], sehne)
  c.line(kerbe[0], kerbe[1], unten[0], unten[1], sehne)

  // Das Holz: gedreht, außen hell, innen dunkel.
  for (let t = 0; t <= 1; t += 0.002) {
    const [x, y] = P(t)
    const [nx, ny] = N(t)
    const r = dicke(t)
    for (let d = -r; d <= r; d += 0.4) {
      const drall = (t * 30 + d * 0.22) % 1 < 0.14 && Math.abs(d) < r * 0.8
      const farbe = d > r * 0.55 ? "V" : d > r * 0.1 ? "v" : d < -r * 0.45 ? "W" : "w"
      c.px(Math.round(x + nx * d), Math.round(y + ny * d), drall && farbe !== "V" ? "W" : farbe)
    }
  }
  // Eingerollte Triebe an den Spitzen.
  for (const [tx, ty] of [[A[0] + 2, A[1] - 2], [B[0] - 2, B[1] + 2]]) {
    const [cx, cy] = [Math.round(tx), Math.round(ty)]
    c.ring(cx, cy, 2, "w")
    c.px(cx - 1, cy - 2, "V")
  }
  // Die Ranke windet sich um den Stab.
  for (let t = 0.1; t <= 0.9; t += 0.002) {
    const k = t * Math.PI * 2 * 5.5
    if (Math.cos(k) < -0.2) continue
    const [x, y] = P(t)
    const [nx, ny] = N(t)
    const d = Math.sin(k) * dicke(t) * 0.95
    c.px(Math.round(x + nx * d), Math.round(y + ny * d), Math.sin(k) > 0.3 ? "g" : "G")
  }
  // Blätter, die im Wind wippen — jedes ein wenig versetzt.
  const blaetter = [[0.14, 1], [0.27, -1], [0.36, 1], [0.64, 1], [0.73, -1], [0.86, 1]]
  blaetter.forEach(([t, seite], i) => {
    const [x, y] = P(t)
    const [nx, ny] = N(t)
    const wipp = Math.round(Math.sin((f / BILDER) * Math.PI * 4 + i * 1.7))
    const r = dicke(t) + 1.5 + wipp * 0.8
    const gross = t > 0.25 && t < 0.75
    c.stamp(gross ? "_blatt" : "_blatt_klein",
      Math.round(x + nx * r * seite) - 2 + (wipp > 0 ? 1 : 0),
      Math.round(y + ny * r * seite) - 2,
      { flip: seite < 0 ? "xy" : t > 0.5 ? "x" : undefined })
  })
  // Der Griff: Wurzeln um die Geisterknospe.
  const [gx, gy] = P(0.5).map(Math.round)
  c.circ(gx, gy, 4, "W")
  c.line(gx - 5, gy + 3, gx - 3, gy + 1, "w")
  c.line(gx + 3, gy - 5, gx + 1, gy - 3, "w")

  // Der Pfeil liegt auf, solange gespannt wird.
  const pfeil = zug > 0.05
  const spitze = [kerbe[0] - Math.round(R * 34), kerbe[1] - Math.round(R * 34)]
  if (pfeil) {
    c.line(kerbe[0], kerbe[1], spitze[0] + 2, spitze[1] + 2, "v")
    // Federn aus Blättern am Ende.
    c.px(kerbe[0] - 2, kerbe[1] - 3, "g"); c.px(kerbe[0] - 3, kerbe[1] - 2, "g")
    c.px(kerbe[0] - 1, kerbe[1] - 3, "l"); c.px(kerbe[0] - 3, kerbe[1] - 1, "l")
    c.px(kerbe[0] - 4, kerbe[1] - 5, "G"); c.px(kerbe[0] - 5, kerbe[1] - 4, "G")
  }

  // ---- Umriss um alles Feste, bevor das Licht kommt ----
  const rand = []
  for (let y = 0; y < c.h; y++) for (let x = 0; x < c.w; x++) {
    if (c.is(x, y, "*")) continue
    if (c.is(x - 1, y, "*") || c.is(x + 1, y, "*") || c.is(x, y - 1, "*") || c.is(x, y + 1, "*")) rand.push([x, y])
  }
  for (const [x, y] of rand) c.px(x, y, "k")

  // ---- Licht: ohne Umriss, damit es schwebt ----
  // Schein um die Knospe, wächst mit dem Licht; flimmert von Bild zu Bild.
  const reich = 4 + licht * 5
  for (let y = -9; y <= 9; y++) for (let x = -9; x <= 9; x++) {
    const d = Math.hypot(x, y)
    if (d > reich || c.is(gx + x, gy + y, "*")) continue
    if ((x * 7 + y * 13 + f * 5 + 100) % 3 === 0) c.px(gx + x, gy + y, d < reich * 0.6 ? "S" : "T")
  }
  // Die Knospe selbst.
  c.circ(gx, gy, 3, "T")
  c.circ(gx, gy, 2, "S")
  if (licht > 0.5) c.circ(gx - 1, gy - 1, 1, "s")
  else c.px(gx - 1, gy - 1, "s")
  if (licht > 0.8) c.px(gx - 1, gy - 1, "x")

  // Die Spitze des Pfeils: ein Blatt aus Licht.
  if (pfeil) {
    const [sx, sy] = spitze
    c.poly([sx - 2, sy - 2, sx + 3, sy, sx + 4, sy + 4, sx, sy + 3], "S")
    c.line(sx - 1, sy - 1, sx + 2, sy + 2, "s")
    if (licht > 0.75) c.px(sx - 1, sy - 1, "x")
    // Schein um die Spitze, wenn gehalten wird.
    for (let y = -7; y <= 7; y++) for (let x = -7; x <= 7; x++) {
      const d = Math.hypot(x + 1, y + 1)
      if (d > 3 + halten * 4 || d < 3 || c.is(sx + x, sy + y, "*")) continue
      if ((x * 7 + y * 13 + f * 5 + 100) % 4 === 0) c.px(sx + x, sy + y, d < 5 ? "S" : "T")
    }
  }

  // Funken: steigen in Ruhe vom Holz auf, kreisen beim Halten in die Spitze.
  for (let i = 0; i < 9; i++) {
    const u = ((f / BILDER) * 2 + i / 9) % 1
    let x, y
    if (halten > 0 && pfeil) {
      const winkel = i * 0.7 + u * 6
      const weg = 10 * (1 - u)
      x = spitze[0] + 1 + Math.cos(winkel) * weg
      y = spitze[1] + 1 + Math.sin(winkel) * weg
    } else {
      const t = 0.1 + i * 0.1
      const [bx, by] = P(t)
      const [nx, ny] = N(t)
      x = bx + nx * (5 + u * 6) - u * 2
      y = by + ny * (5 + u * 6) - u * 4
    }
    x = Math.round(x); y = Math.round(y)
    if (c.is(x, y, "*") || u > 0.9) continue
    c.px(x, y, u < 0.3 ? "x" : u < 0.55 ? "s" : u < 0.75 ? "S" : "T")
  }

  // Der Schuss: ein Lichtring am Griff und eine Spur, die nach oben links
  // davonfliegt.
  if (schuss >= 0 && schuss < 4) {
    const weit = 4 + schuss * 7
    const [hx, hy] = [Math.round(mitte[0] - R * (26 + weit)), Math.round(mitte[1] - R * (26 + weit))]
    for (let k = 0; k < 7 - schuss; k++) {
      const [px, py] = [hx + k, hy + k]
      if (px >= 0 && py >= 0 && !c.is(px, py, "kWwvVGgl")) c.px(px, py, k < 2 ? "x" : k < 4 ? "s" : "S")
    }
    if (schuss < 2) {
      for (let a = 0; a < 16; a++) {
        const w = (a / 16) * Math.PI * 2
        const rr = 6 + schuss * 3
        const [px, py] = [Math.round(gx + Math.cos(w) * rr), Math.round(gy + Math.sin(w) * rr)]
        if (!c.is(px, py, "*")) c.px(px, py, schuss === 0 ? "s" : "S")
      }
    }
  }
},
  // Das Licht fällt aufs Holz.
  glow("sSx", { r: 5, strength: 0.6, bands: 3 }))
