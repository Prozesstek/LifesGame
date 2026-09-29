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

  /// Woran Tests die Knöpfe finden — sie tragen kein Wort mehr.
  static const Key oeffnenKey = ValueKey<String>('truhe-oeffnen');
  static const Key einsackenKey = ValueKey<String>('truhe-einsacken');

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
          const Spacer(),
          FilledButton(
            key: DailyChestCard.oeffnenKey,
            onPressed: onOpen,
            child: const Icon(
              Icons.lock_open_rounded,
              semanticLabel: 'Tagestruhe öffnen',
            ),
          ),
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
          Semantics(
            label: 'Tagestruhe: ${chestSummary(inhalt)}',
            excludeSemantics: true,
            child: _Beute(inhalt: inhalt, groesse: 14),
          ),
        ],
      ),
    );
  }
}

/// Was drin war, als Zeichen und Zahl: Münze +18, Eis +1.
class _Beute extends StatelessWidget {
  const _Beute({required this.inhalt, required this.groesse});

  final ChestContent inhalt;
  final double groesse;

  @override
  Widget build(BuildContext context) {
    final stil = TextStyle(
      fontSize: groesse,
      fontWeight: FontWeight.bold,
      color: Palette.gold,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GoldIcon(size: groesse + 2),
        const SizedBox(width: 4),
        Text('+${inhalt.gold}', style: stil),
        if (inhalt.freezes > 0) ...<Widget>[
          SizedBox(width: groesse * 0.8),
          Icon(Icons.ac_unit, size: groesse + 2, color: Palette.accent),
          const SizedBox(width: 4),
          Text(
            '+${inhalt.freezes}',
            style: stil.copyWith(color: Palette.accent),
          ),
        ],
      ],
    );
  }
}

/// „+18 Gold" oder „+5 Gold und ein Streak-Eis" — für den Vorleser.
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
          const SizedBox(height: 16),
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
            child: Semantics(
              label: chestSummary(inhalt),
              excludeSemantics: true,
              child: _Beute(inhalt: inhalt, groesse: _selten ? 26 : 20),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        FilledButton(
          key: DailyChestCard.einsackenKey,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.check_rounded, semanticLabel: 'Einsacken'),
        ),
      ],
    );
  }
}
