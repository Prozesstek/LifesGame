@echo off
setlocal

REM ---------------------------------------------------------------
REM  Lifes Game im Browser starten.
REM
REM  Doppelklick genuegt. Das Fenster bleibt offen und nimmt danach
REM  Tastenbefehle an:
REM     r  Hot Reload   (Aenderung sofort im Bild)
REM     R  Hot Restart  (noetig bei Aenderungen an main.dart)
REM     q  Beenden
REM
REM  Optional ein fester Port:  start-app.bat 8095
REM  Ohne Angabe wird der erste freie aus der Liste unten genommen.
REM
REM  Bewusst ueber den PATH und nicht ueber einen festen Pfad --
REM  sonst laeuft die Datei nur auf einem der beiden Rechner.
REM ---------------------------------------------------------------

pushd "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 goto :kein_flutter

set "PORT=%~1"
if not "%PORT%"=="" goto :port_steht

REM Freien Port suchen. Ein belegter Port liess Flutter frueher
REM kommentarlos abbrechen -- das war der haeufigste Grund, warum
REM diese Datei "abgestuerzt" ist.
REM Absichtlich NICHT auf "LISTENING" gefiltert: Auf einem deutschen
REM Windows schreibt netstat "ABHOEREN". Ein Filter auf das englische
REM Wort findet nie etwas, haelt jeden Port fuer frei -- und die Datei
REM stuerzt wieder auf dem belegten Port ab. Die Adresse selbst steht
REM in jeder Sprache gleich da.
for %%P in (8080 8081 8082 8083 8084 8090 8095 8100) do (
    netstat -ano | findstr ":%%P " >nul 2>nul
    if errorlevel 1 (
        set "PORT=%%P"
        goto :port_steht
    )
)

echo.
echo   FEHLER: Alle vorgesehenen Ports sind belegt.
echo   Gib einen eigenen an, zum Beispiel:  start-app.bat 8123
echo.
goto :ende_mit_fehler

:port_steht
echo.
echo   Lifes Game startet auf http://localhost:%PORT%
echo   Chrome oeffnet sich gleich von selbst.
echo.
echo   Danach in diesem Fenster:  r = Reload   R = Neustart   q = Ende
echo.

flutter run -d chrome --web-port=%PORT%
if errorlevel 1 goto :start_fehlgeschlagen

popd
endlocal
exit /b 0

:start_fehlgeschlagen
echo.
echo   Der Start ist fehlgeschlagen. Die Meldung dazu steht oben.
echo.
echo   Haeufigste Ursache: Port %PORT% wurde belegt, waehrend die
echo   Datei lief. Einfach erneut starten oder einen Port angeben:
echo.
echo       start-app.bat 8123
echo.
goto :ende_mit_fehler

:kein_flutter
echo.
echo   FEHLER: "flutter" wurde nicht gefunden.
echo.
echo   Das Flutter-SDK ist entweder nicht installiert, oder sein
echo   bin-Ordner steht nicht im PATH. Pruefen mit:
echo.
echo       where flutter
echo.
echo   Nach dem Eintragen in den PATH ist ein NEUES Fenster noetig --
echo   bereits offene Terminals behalten den alten PATH.
echo.
goto :ende_mit_fehler

:ende_mit_fehler
popd
endlocal
echo   Fenster bleibt offen, damit die Meldung lesbar ist.
pause
exit /b 1
