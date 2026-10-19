# Der Play Store am 20.11. — die Liste zum Abhaken

> **Herkunft:** Frederik am 19.10.2026: „Wir wollen bald die App in den
> Android Store kriegen um Feedback zu sammeln. Was müssen wir dafür noch
> machen?“ und danach: „Wir wollen am 20.11 in den Store, halt das fest.“
> Das Ziel steht in [`ziele.md`](../context/ziele.md) als Ziel 9.
>
> **Gelesen als:** am Freitag, 20.11., **öffentlich** im Play Store.
> Das ist Claudes Lesart, nicht bestätigt. Ist der Start der
> Feedbackrunde gemeint, verschiebt sich alles unten um gut drei Wochen
> nach hinten, und die Liste bleibt dieselbe.
>
> **Abhaken:** `[ ]` zu `[x]`, im selben Commit wie die Arbeit. *(Mensch)*
> heißt: Das kann nur einer von euch, nicht Claude.

---

## Warum der 26.10. die eigentliche Frist ist

Ein **neues privates** Play-Konto darf erst öffentlich veröffentlichen,
nachdem ein **geschlossener Test mit mindestens zwölf Testern vierzehn
Tage am Stück** gelaufen ist. Danach prüft Google den Antrag auf
Produktionszugang, nach eigener Angabe meist in bis zu sieben Tagen,
und die erste öffentliche Fassung noch einmal. Keine der drei Fristen
lässt sich abkürzen.

| Wann | Was |
|---|---|
| **Mi 21.10.** | entschieden, Konto angelegt, Tester angefragt |
| **Fr 23.10.** | erste Fassung für den geschlossenen Test eingereicht |
| **Mo 26.10.** | **zwölf Tester eingeschrieben — die vierzehn Tage beginnen** |
| Do 29.10., Mo 02.11. | Fragebogen an Tag 3 und Tag 7 |
| **Mo 09.11.** | vierzehn Tage voll, Fragebogen Tag 14, **Produktionszugang beantragen** |
| bis Mo 16.11. | Zugang erteilt, öffentliche Fassung eingereicht |
| **Fr 20.11.** | öffentlich im Store |

**Jeder Tag, den der Test später beginnt, geht vom Puffer für Googles
Prüfungen ab.** Beginnt er nach dem 26.10., reicht es nur, wenn Google
schneller prüft, als es selbst angibt.

Ein **Organisationskonto** (über Frederik Leckebusch IT) ist von der
Testpflicht ausgenommen, braucht aber eine D-U-N-S-Nummer, und die kann
Wochen dauern. Für den 20.11. trägt das nur, wenn die Nummer schon da ist.

---

## Bis Mi 21.10. — entscheiden und anmelden

- [ ] **AktivesBrett stimmt zu.** Der Store stand bis zum 19.10. auf der
      Sperrliste in `ziele.md`.
- [ ] *(Mensch)* Wem gehört das Konto? Der andere wird in der Play
      Console als Nutzer eingeladen.
- [ ] *(Mensch)* Konto anlegen, 25 $ zahlen, Identität bestätigen; dazu
      gehört ein Android-Gerät mit der Play-Console-App. Dauert Tage, also
      zuerst.
- [ ] *(Mensch)* Händlerstatus angeben (Gesetz über digitale Dienste). Als
      Händler stehen Adresse und Telefon öffentlich im Store.
- [ ] **Name und Paket-Id endgültig.** `dev.prozesstek.lifes_game` lässt
      sich nach dem ersten Upload nie mehr ändern. „Lifes Game“ oder
      „Life's Game“? Im Store nach gleichen Namen suchen.
- [ ] Spiel oder App, und welche Kategorie (Rollenspiel, Gesundheit &
      Fitness, Produktivität)?
- [ ] **Erinnerung ja oder nein** (seit 27.09. zurückgestellt). Empfehlung:
      ja, eine tägliche lokale Benachrichtigung — sonst misst der Test,
      wer die App vergisst, nicht wer sich langweilt. Darf als Update im
      Test kommen.
- [ ] **Absturzberichte.** Empfehlung: in der ersten Runde keine Analytik
      und kein Crashlytics. Dann gilt „keine Daten erhoben“, und die Play
      Console zeigt Abstürze trotzdem (Android Vitals).
- [ ] **Große Schrift.** Auf der Sperrliste steht „für Tester zwingend“ —
      jetzt kommen Tester.
- [ ] *(Mensch)* **15 bis 20 Tester anfragen**, damit zwölf dabeibleiben.
      Jeder braucht ein Google-Konto, mit dem er auch am Handy angemeldet
      ist.

## Bis Fr 23.10. — die erste Fassung

### Rechner *(Mensch)*

- [ ] Android Studio → SDK Manager → „Android SDK Command-line Tools“.
      `flutter doctor` meldet sie als fehlend.
- [ ] `flutter doctor --android-licenses`
- [ ] USB-Debugging am Handy, `flutter run --release` aufs eigene Gerät.
      Auf diesem Rechner wurde noch nie ein Android-Build gebaut.

### Code

- [ ] Upload-Schlüssel erzeugen, `android/key.properties`, eine
      Release-`signingConfig` in `android/app/build.gradle.kts`. Bisher
      signiert der Release-Build mit dem Debug-Schlüssel.
- [ ] *(Mensch)* Schlüssel und Passwort an zwei Orten sichern. `*.jks` und
      `key.properties` sind gitignored, das bleibt so.
- [ ] Eigenes Startsymbol statt des Flutter-Logos: adaptives Icon in
      allen Dichten, dazu 512 × 512 für den Store.
- [ ] Startbild in der Lederfarbe. Bisher steht dort der helle
      Standardhintergrund (`launch_background.xml`), beim Start blitzt
      Weiß auf.
- [ ] **Zurück-Geste in der Grube.** Das Steuerkreuz nimmt den ganzen
      Bildschirm ein, und `PitScreen` hat kein `PopScope`: Ein Wisch vom
      linken Rand beendet den Lauf. Er soll nachfragen wie die
      Tagesgrube.
- [ ] **Große Bildschirme.** Mit targetSdk 36 hält Android auf Tablets
      und aufgeklappten Faltbaren das Hochformat nicht mehr ein.
      `PhoneFrame` dort einschalten oder Tablets in der Play Console
      ausschließen.
- [ ] Lizenzseite (`showLicensePage`) und die Namen der Asset-Pakete
      erreichbar machen, ohne Satz auf dem Bildschirm (ADR-0060).
- [ ] Mit jedem Upload die Zahl nach dem `+` in `pubspec.yaml` erhöhen
      (`version: 0.1.0+1`).
- [ ] `flutter build appbundle --release` — Play nimmt nur `.aab`.

### Recht und Inhalt

Ein geschlossener Test mit Fremden ist schon eine Verbreitung.

- [ ] *(Mensch)* Raven, die Kampf-Figuren und `UIBundleFree`: Quelle,
      Urheber und Link in die HERKUNFT-Dateien; prüfen, ob eine
      Namensnennung verlangt ist.
- [ ] `Success.mp3`, `Win.mp3`, `Win_2.mp3`, `Win_3.mp3`: Herkunft
      unbekannt. Nachweisen oder durch gerechnete ersetzen
      (`tool/haekchen_klaenge.py` zeigt, wie).
- [ ] Hinweis „keine medizinische Beratung“ bei den Gesundheitsseiten.
- [ ] Datenschutzerklärung als Seite mit fester Adresse; GitHub Pages
      liefert ohnehin aus.
- [ ] *(Mensch)* Impressum und Kontakt klären — Frederik ist gewerblich
      tätig.

### Play Console *(Mensch)*

- [ ] App anlegen: Deutsch, kostenlos. **Kostenlos lässt sich später
      nicht mehr auf kostenpflichtig stellen.**
- [ ] App-Inhalte: Datenschutz-Adresse, Datensicherheit, Werbung,
      Zielgruppe (nicht unter 13, sonst gilt die Familien-Richtlinie),
      Fragebogen zur Altersfreigabe (Fantasy-Gewalt), die Erklärungen zu
      Gesundheit und Finanzen.
- [ ] Länder: Deutschland, Österreich, Schweiz.
- [ ] Store-Eintrag: Titel (höchstens 30 Zeichen), Kurzbeschreibung (80),
      Beschreibung (4.000), Icon 512 × 512, Feature-Grafik 1024 × 500.
- [ ] Mindestens zwei Screenshots. **Die lange Seite darf höchstens
      doppelt so lang sein wie die kurze**: 390 × 844 und die meisten
      Handy-Bildschirme (20 : 9) sind zu schmal. In 1080 × 1920 rendern.
- [ ] Interner Test für euch zwei — geht ohne Prüfung, zeigt, ob die
      Fassung aus dem Store startet.
- [ ] Fassung für den geschlossenen Test einreichen; die erste Prüfung
      einer neuen App kann Tage dauern.

## Bis Mo 26.10. — die vierzehn Tage beginnen

- [ ] *(Mensch)* Zwölf oder mehr Tester haben den Link angenommen. Wer
      eingeladen ist, zählt noch nicht.
- [ ] Euer Spielstand ist aus dem Web in die App umgezogen (als Text
      sichern, einfügen) — eure Ketten hängen daran.
- [ ] Feedback-Kanal steht: eine Gruppe, in die der Text der Tagesgrube
      geteilt wird. Das ist zugleich die Messung aus ADR-0071 — wer nach
      zwei Wochen noch teilt, ist noch dabei.
- [ ] Teilen-Text der Tagesgrube: zeigt er weiter auf die Web-Fassung?

## 26.10. bis 09.11. — der Test läuft

Neue Fassungen dürfen kommen; die Frist hängt an den eingeschriebenen
Testern, nicht an der Fassung. **Fällt ihre Zahl unter zwölf, beginnt
sie neu.**

### Am Handy prüfen

Bisher steht bei fast jedem Block in `state.md` „nicht am Handy“.

- [ ] Status- und Navigationsleiste (seit API 35 zeichnet die App
      darunter): Kopfzeile, Fähigkeitsknöpfe, Blätter von unten.
- [ ] Tagesgrube: Die Zurück-Geste fragt nach und hält den Lauf an.
- [ ] Klänge bei schnellen Treffern — Verzögerung, Knacken; Vibration.
- [ ] Die Grube auf einem älteren Handy.
- [ ] Über Nacht im Hintergrund: Stimmt morgens „heute“ (Ziel 4), läuft
      ein Timer weiter (ADR-0067)?
- [ ] Neu installieren: Kommt der Stand über die Android-Sicherung zurück?

### Feedback

- [ ] Fragebogen Tag 3 (Do 29.10.)
- [ ] Fragebogen Tag 7 (Mo 02.11.)
- [ ] Fragebogen Tag 14 (Mo 09.11.)
- [ ] Was gemeldet wird, steht in `state.md` — ein Eintrag je Woche.

### Inhalt

- [ ] Gesundheitsaussagen gegengelesen: neun Einführungen und zwanzig
      Themen (`state.md`, „Inhalt und Balance“).
- [ ] Gewohnheiten-Seiten nach *Die 1%-Methode*: eigene Worte, das Buch
      als Quelle genannt.

## Ab Mo 09.11. — öffentlich

- [ ] *(Mensch)* Produktionszugang beantragen. Google fragt nach dem Test,
      der App und ob sie bereit ist; die Fragebögen sind die Antwort.
- [ ] *(Mensch)* Nach der Zusage die öffentliche Fassung einreichen.
- [ ] **Fr 20.11.: öffentlich im Store.**
- [ ] `state.md` und `ziele.md` nachziehen, dazu ein ADR zum Store-Start.

---

## Was schon passt

Geprüft am 19.10.:

- `applicationId` und `namespace` `dev.prozesstek.lifes_game`, der Name
  „Lifes Game“, das Hochformat im Manifest.
- **targetSdk 36** über den Standard von Flutter — seit dem 31.08.2026
  Pflicht für neue Apps.
- NDK 28, und kein Plugin bringt eigenen nativen Code mit; die
  16-KB-Pflicht sollte damit erfüllt sein. Die Play Console meldet es,
  wenn nicht.
- **Keine Internet-Berechtigung**: Alles läuft offline, die Angaben zum
  Datenschutz werden kurz.
- Der Release-Build ohne `--dart-define=ENTWICKLERFASSUNG=true` hat
  keinen Entwicklermodus (`lib/dev/dev_controller.dart`).
- Android SDK 36 ist installiert.

## Quellen

- [Target API level requirements](https://developer.android.com/google/play/requirements/target-sdk)
  (developer.android.com)
- [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
  (Google-Play-Hilfe) — zwölf Tester, vierzehn Tage
- [How to Publish an App on Google Play](https://playcode.io/blog/how-to-publish-an-app-on-google-play)
  (Drittquelle) — „meist sieben Tage oder weniger“ für den
  Produktionszugang

Die Fristen stammen aus Claudes Recherche am 19.10. Vor dem Start in der
Play Console gegenprüfen.
