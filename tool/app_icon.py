"""Legt das App-Icon aus tool/app_icon/quelle.png nach android/ und docs/store/.

Quelle: Frederiks Bild (ChatGPT, 10.11.2026). Zugeschnitten wird auf die
Bildfläche innerhalb des Rahmens, sodass die gerundeten Ecken wegfallen.
Aufruf: python tool/app_icon.py  (braucht Pillow)
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"
CROP = (232, 231, 1022, 1021)  # inneres Quadrat, ohne Rahmen und Ecken
HINTERGRUND = (20, 39, 79)  # Himmelsblau am Rand
ADAPTIV_ANTEIL = 0.66  # Motiv im Sicherheitskreis (66 von 108 dp)
DICHTEN = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def abrunden(bild: Image.Image, anteil: float) -> Image.Image:
    groesse = bild.size[0]
    maske = Image.new("L", (groesse * 4, groesse * 4), 0)
    ImageDraw.Draw(maske).rounded_rectangle(
        (0, 0, groesse * 4 - 1, groesse * 4 - 1),
        radius=int(groesse * 4 * anteil),
        fill=255,
    )
    maske = maske.resize((groesse, groesse), Image.LANCZOS)
    ergebnis = bild.convert("RGBA")
    ergebnis.putalpha(maske)
    return ergebnis


def main() -> None:
    quelle = Image.open(ROOT / "tool" / "app_icon" / "quelle.png").convert("RGB")
    motiv = quelle.crop(CROP)

    # Store: 512 x 512, Voll-Quadrat (Google rundet selbst)
    store = motiv.resize((512, 512), Image.LANCZOS)
    store.save(ROOT / "docs" / "store" / "icon_512.png")

    for dichte, faktor in DICHTEN.items():
        # Altes Symbol (vor API 26): gerundetes Quadrat, 48 dp
        alt = motiv.resize((int(48 * faktor), int(48 * faktor)), Image.LANCZOS)
        ordner = RES / f"mipmap-{dichte}"
        ordner.mkdir(parents=True, exist_ok=True)
        abrunden(alt, 0.18).save(ordner / "ic_launcher.png")

        # Adaptiv: Vordergrund-Ebene 108 dp, Motiv auf 66 % in der Mitte
        ebene = int(108 * faktor)
        innen = int(ebene * ADAPTIV_ANTEIL)
        vorn = Image.new("RGBA", (ebene, ebene), (0, 0, 0, 0))
        klein = motiv.resize((innen, innen), Image.LANCZOS).convert("RGBA")
        versatz = (ebene - innen) // 2
        vorn.paste(klein, (versatz, versatz))
        vorn.save(ordner / "ic_launcher_foreground.png")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n',
        encoding="utf-8",
        newline="\n",
    )
    (RES / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#%02X%02X%02X</color>\n'
        "</resources>\n" % HINTERGRUND,
        encoding="utf-8",
        newline="\n",
    )


if __name__ == "__main__":
    main()
