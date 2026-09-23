import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/gold_icon.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

/// Die Zeichnung der Truhe — Raven fc6 (`assets/RAVEN.md`).
const String truhenBild = 'assets/Items/Truhe.png';

/// **Die Tagestruhe** auf der Tagesliste (ADR-0044).
///
/// Sichtbar, sobald heute alles erledigt ist — dann mit Knopf. Nach dem
/// Öffnen bleibt eine schmale Karte, die sagt, was drin war. An einem Tag,
/// an dem noch etwas offen ist, steht sie **nicht** da: Die Tagesform-Karte
/// nennt sie dort als Ziel, statt eine leere Truhe vorzuzeigen.
class DailyChestCard extends StatelessWidget {
  const DailyChestCard({
    required this.canOpen,
    required this.opened,
    required this.onOpen,
    super.key,
  });

  /// Ob sie heute noch zu öffnen ist.
  final bool canOpen;

  /// Was heute darin war — null, solange sie zu ist.
  final ChestContent? opened;

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final inhalt = opened;
    if (canOpen) return _Zu(onOpen: onOpen);
    if (inhalt != null) return _Offen(inhalt: inhalt);
    return const SizedBox.shrink();
  }
}

class _Zu extends StatelessWidget {
  const _Zu({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      edgeColor: Palette.gold,
      child: Row(
        children: <Widget>[
          // Einmal hereinspringen, nicht dauernd wackeln: Eine Endlos-
          // Animation liesse `pumpAndSettle` in jedem Test hängen, der
          // einen erledigten Tag zeigt.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: const PixelArt(
              assetPath: truhenBild,
              side: 52,
              fallback: Icon(Icons.inventory_2, color: Palette.gold, size: 40),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Deine Tagestruhe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Palette.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Alles erledigt. Mal sehen, was drin ist.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Palette.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onOpen, child: const Text('Öffnen')),
        ],
      ),
    );
  }
}

class _Offen extends StatelessWidget {
  const _Offen({required this.inhalt});

  final ChestContent inhalt;

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      color: Palette.surfaceRaised,
      child: Row(
        children: <Widget>[
          const Opacity(
            opacity: 0.6,
            child: PixelArt(
              assetPath: truhenBild,
              side: 28,
              fallback: Icon(Icons.inventory_2, color: Palette.muted),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Tagestruhe: ${chestSummary(inhalt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

/// „+18 Gold" oder „+5 Gold und ein Streak-Eis".
String chestSummary(ChestContent inhalt) {
  final eis = switch (inhalt.freezes) {
    0 => '',
    1 => ' und ein Streak-Eis',
    final n => ' und $n Streak-Eis',
  };
  return '+${inhalt.gold} Gold$eis';
}

/// Das Blatt beim Öffnen: Die Truhe springt auf, darunter der Inhalt.
Future<void> showChestReveal(BuildContext context, ChestContent inhalt) {
  return showDialog<void>(
    context: context,
    builder: (context) => HolzDialog(child: _Enthuellung(inhalt: inhalt)),
  );
}

class _Enthuellung extends StatelessWidget {
  const _Enthuellung({required this.inhalt});

  final ChestContent inhalt;

  String get _titel => switch (inhalt.tier) {
    ChestTier.schlicht => 'Ein paar Münzen',
    ChestTier.gut => 'Gut gefüllt!',
    ChestTier.eis => 'Ein Streak-Eis!',
    ChestTier.schatz => 'Ein Schatz!',
  };

  bool get _selten => inhalt.tier != ChestTier.schlicht;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surface,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.2, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: const PixelArt(
              assetPath: truhenBild,
              side: 96,
              fallback: Icon(Icons.inventory_2, color: Palette.gold, size: 80),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _titel,
            style: TextStyle(
              fontSize: _selten ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: _selten ? Palette.gold : Palette.text,
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - t)),
                child: child,
              ),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const GoldIcon(size: 22),
                    const SizedBox(width: 6),
                    Text(
                      '+${inhalt.gold} Gold',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Palette.gold,
                      ),
                    ),
                  ],
                ),
                if (inhalt.freezes > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.ac_unit, color: Palette.accent),
                      const SizedBox(width: 6),
                      Text(
                        '+${inhalt.freezes} ${StreakFreeze.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Palette.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Morgen wartet eine neue — wenn wieder alles erledigt ist.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Palette.muted),
          ),
        ],
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Einsacken'),
        ),
      ],
    );
  }
}
