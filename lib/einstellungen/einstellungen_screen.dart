import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_effects.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'einstellungen.dart';

/// **Die Einstellungen** (13.11.2026): Lautstärke und die Seite der
/// Fähigkeiten im Kampf. Geöffnet über das Zahnrad auf der Startseite —
/// nur dort, damit es einen festen Ort hat.
class EinstellungenScreen extends ConsumerWidget {
  const EinstellungenScreen({super.key});

  static const Key lautstaerkeKey = ValueKey<String>('einstellung-laut');
  static const Key linksKey = ValueKey<String>('einstellung-links');
  static const Key rechtsKey = ValueKey<String>('einstellung-rechts');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(einstellungenProvider);
    final steuer = ref.read(einstellungenProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Palette.surface,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: <Widget>[
                HolzKarte(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _Kopf(icon: Icons.volume_up, text: 'Ton'),
                      Row(
                        children: <Widget>[
                          Icon(
                            e.lautstaerke <= 0
                                ? Icons.volume_off
                                : Icons.volume_down,
                            color: Palette.textDim,
                            semanticLabel: 'leise',
                          ),
                          Expanded(
                            child: Slider(
                              key: lautstaerkeKey,
                              value: e.lautstaerke,
                              divisions: 10,
                              label: '${(e.lautstaerke * 100).round()} %',
                              semanticFormatterCallback: (v) =>
                                  'Lautstärke ${(v * 100).round()} Prozent',
                              onChanged: steuer.setzeLautstaerke,
                              // Probe: einmal hören, wie laut es jetzt ist.
                              onChangeEnd: (_) => ref
                                  .read(soundPlayerProvider)
                                  .play(SoundEffect.ton3),
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${(e.lautstaerke * 100).round()} %',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Palette.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HolzKarte(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _Kopf(
                        icon: Icons.auto_awesome,
                        text: 'Fähigkeiten im Kampf',
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _Seite(
                              key: linksKey,
                              icon: Icons.west,
                              text: 'Links',
                              gewaehlt: e.faehigkeitenLinks,
                              onTap: () => steuer.setzeFaehigkeitenLinks(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Seite(
                              key: rechtsKey,
                              icon: Icons.east,
                              text: 'Rechts',
                              gewaehlt: !e.faehigkeitenLinks,
                              onTap: () => steuer.setzeFaehigkeitenLinks(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Kopf extends StatelessWidget {
  const _Kopf({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: Palette.accent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Eine Seite zum Wählen; die gewählte ist golden umrandet.
class _Seite extends StatelessWidget {
  const _Seite({
    required this.icon,
    required this.text,
    required this.gewaehlt,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String text;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: gewaehlt,
      button: true,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: gewaehlt ? Palette.accent : Palette.textDim),
        label: Text(
          text,
          style: TextStyle(
            fontWeight: gewaehlt ? FontWeight.bold : FontWeight.normal,
            color: gewaehlt ? Palette.text : Palette.textDim,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(
            color: gewaehlt ? Palette.accent : Palette.muted,
            width: gewaehlt ? 2 : 1,
          ),
        ),
      ),
    );
  }
}
