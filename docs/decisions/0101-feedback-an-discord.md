# ADR-0101: Feedback aus der App geht an einen Discord-Webhook

**Datum:** 11.11.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Für die Testphase sollen Tester von jedem Screen aus in unter fünfzehn
Sekunden Feedback senden können, samt Screenshot, Gerät und App-Version.
Gesammelt werden soll es an einem Ort, bei dem das Team ohnehin ist:
dem Discord. Die App hat **kein Backend** (offline-first, ADR-0010).

## Entscheidung

Eine Sprechblase schwebt oben rechts über der ganzen App
(`FeedbackHuelle` im `builder` von `MaterialApp`). Ein Tipp nimmt den
Screen auf und öffnet ein Blatt: Kategorie, Text, Screenshot. Gesendet
wird per HTTP-POST an einen **Discord-Webhook** — Text als Embed,
Screenshot als Anhang — über eine Naht (`FeedbackDienst`), hinter der
sich das Ziel später austauschen lässt. Die URL steht nicht im Code,
sondern kommt beim Bauen aus `feedback.json` (gitignored,
`--dart-define-from-file`).

## Begründung

Ohne Backend ist ein Webhook der kürzeste Weg: kein Konto, kein Server,
keine Regeln. Discord zeigt Embed und Bild sofort lesbar an.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Firebase oder Supabase | ein Backend nur für Feedback; Konto, Regeln, Datenschutz-Prüfung |
| Kleiner Cloudflare Worker vor dem Webhook | hielte die URL geheim, braucht aber ein Konto und Pflege — für die Testphase nicht nötig |
| Ohne Pakete (dart:io, Gerätemodell über Kotlin) | ginge nur in der APK und wäre mehr eigener Code |
| Knopf in jeder Titelzeile | rund zehn Stellen, die Startseite hat keine |
| Blase im Dungeon und Tutorial ausblenden | AktivesBrett: sie soll überall da sein, damit man von überall melden kann |

## Konsequenzen

- **Die URL steckt in der fertigen APK** und lässt sich mit Mühe
  auslesen. Wird der Kanal zugespammt: Webhook in Discord löschen, neuen
  anlegen, `feedback.json` tauschen, neu bauen.
- **Ein Build ohne `feedback.json`** (etwa die Web-Fassung aus der CI)
  zeigt die Blase trotzdem; Senden meldet dann „Feedback ist in dieser
  Fassung nicht eingerichtet.“
- Drei neue Pakete: `http`, `device_info_plus`, `package_info_plus`.
- Die Release-APK braucht jetzt `android.permission.INTERNET`; Flutter
  setzt sie nur im Debug-Build von selbst.
- Gerät, System, Spielername, Level und der Screenshot gehen an Discord.
  Das Blatt sagt es; **für den Play Store gehört es in die
  Datenschutzerklärung**.
- Der Screenshot ist ein PNG, höchstens 540 Bildpunkte breit. Ein
  JPEG wäre kleiner, bräuchte aber ein weiteres Paket.
- Der Name des Screens wird aus dem Widget-Baum gelesen (der letzte
  `…Screen`). Im Web-Release sind die Namen verkürzt und damit
  unbrauchbar, in der APK nicht.
