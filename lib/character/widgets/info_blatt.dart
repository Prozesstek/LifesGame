import 'package:flutter/material.dart';

import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// Wo Datenschutz, Gesundheitshinweis und Lizenzen stehen.
///
/// **Das Blatt ist die Ausnahme von ADR-0060**: Diese Texte sind Pflicht
/// und müssen gelesen werden. Der Zugang bleibt ein Zeichen oben im
/// Charakter; erst im Blatt stehen drei Zeilen mit Zeichen.
const String datenschutzAdresse =
    'https://prozesstek.de/LifesGame/datenschutz.html';

const String datenschutzText =
    'Lifes Game erhebt keine personenbezogenen Daten. Es gibt kein Konto, '
    'keine Werbung und keine Analyse- oder Absturzdienste. Die App hat keine '
    'Berechtigung für das Internet und sendet nichts an uns oder an Dritte.\n\n'
    'Alles, was du eingibst und erspielst, liegt nur auf deinem Gerät. '
    'Deinstallierst du die App, ist es gelöscht. Wenn du die Datensicherung '
    'von Android aktiviert hast, kann Google den Stand deines Geräts '
    'sichern; darauf haben wir keinen Einfluss.\n\n'
    'Den Spielstand als Text und das Ergebnis der Tagesgrube gibst du nur '
    'weiter, wenn du sie selbst kopierst und einfügst.\n\n'
    'Verantwortlich: Frederik Leckebusch (FRENO Studios), Geraer Straße 21, '
    '99099 Erfurt, lifesgamestudios@gmail.com.\n\n'
    'Die ganze Erklärung steht unter $datenschutzAdresse';

const String gesundheitsText =
    'Die Seiten im Wissensbaum (Kraft, Ausdauer, Schlaf, Psychologie und '
    'mehr) sind allgemeine Informationen zur Bildung und Motivation. Sie '
    'ersetzen keine ärztliche, therapeutische oder sonstige professionelle '
    'Beratung.\n\n'
    'Sprich bei Beschwerden, Vorerkrankungen oder vor einer starken '
    'Veränderung deines Trainings mit einer Ärztin oder einem Arzt.';

/// Öffnet das Blatt mit den drei Zeilen.
Future<void> showInfoBlatt(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => const _InfoBlatt(),
  );
}

class _InfoBlatt extends StatelessWidget {
  const _InfoBlatt();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: HolzBlatt(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Zeile(
                key: const Key('info-datenschutz'),
                icon: Icons.lock_outline,
                name: 'Datenschutz',
                onTap: () =>
                    _zeigeText(context, 'Datenschutz', datenschutzText),
              ),
              _Zeile(
                key: const Key('info-gesundheit'),
                icon: Icons.favorite_border,
                name: 'Gesundheit',
                onTap: () => _zeigeText(context, 'Gesundheit', gesundheitsText),
              ),
              _Zeile(
                key: const Key('info-lizenzen'),
                icon: Icons.description_outlined,
                name: 'Lizenzen',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Lifes Game',
                  applicationLegalese: 'FRENO Studios',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _zeigeText(
    BuildContext context,
    String titel,
    String text,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => HolzDialog(
        child: AlertDialog(
          title: Text(titel),
          content: SingleChildScrollView(child: Text(text)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.icon,
    required this.name,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Druck(
      child: ListTile(
        leading: Icon(icon, color: Palette.accent),
        title: Text(name),
        trailing: const Icon(Icons.chevron_right, color: Palette.muted),
        onTap: onTap,
      ),
    );
  }
}
