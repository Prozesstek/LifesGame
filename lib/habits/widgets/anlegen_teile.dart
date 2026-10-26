/// Die Bausteine der Fragen beim Anlegen (`GewohnheitAnlegen`) —
/// ausgelagert, damit das Blatt selbst nur den Weg erzählt.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/druck.dart';
import '../../ui/palette.dart';

/// Oben: zurück, wie weit, schließen.
class AnlegenKopf extends StatelessWidget {
  const AnlegenKopf({
    required this.weg,
    required this.wo,
    required this.onZurueck,
    super.key,
  });

  static const Key zurueckKey = ValueKey<String>('anlegen-zurueck');

  final int weg;
  final int wo;
  final VoidCallback onZurueck;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 44,
          child: wo > 0
              ? IconButton(
                  key: zurueckKey,
                  onPressed: onZurueck,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Palette.text,
                  tooltip: 'Zurück',
                )
              : null,
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              for (var i = 0; i < weg; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= wo ? Palette.accent : Palette.surfaceSunken,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          width: 44,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: Palette.textDim,
            tooltip: 'Abbrechen',
          ),
        ),
      ],
    );
  }
}

/// Eine Wahl als große Kachel — ein Tipp genügt.
class AnlegenWahl extends StatelessWidget {
  const AnlegenWahl({
    required this.icon,
    required this.titel,
    required this.onTap,
    this.zeile,
    this.unten,
    this.ende,
    this.gewaehlt = false,
    this.aus = false,
    this.senkrecht = false,
    this.farbe,
    super.key,
  });

  final IconData icon;
  final String titel;
  final String? zeile;
  final Widget? unten;
  final Widget? ende;
  final bool gewaehlt;

  /// Matt, aber tippbar: Der Tipp sagt, warum es nicht geht.
  final bool aus;

  /// Zeichen über dem Namen statt daneben — für das Raster der Gebiete.
  final bool senkrecht;

  /// Die Farbe einer Wahl, die eine hat — ein Gebiet (ADR-0090): Das
  /// Zeichen trägt sie immer, der Rand, wenn sie gewählt ist. Ohne der
  /// Akzent.
  final Color? farbe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = <Widget>[
      Text(
        titel,
        textAlign: senkrecht ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Palette.text,
        ),
      ),
      if (zeile case final z?)
        Text(z, style: const TextStyle(fontSize: 12, color: Palette.textDim)),
      if (unten case final u?) ...<Widget>[const SizedBox(height: 3), u],
    ];
    final zeichen = Icon(
      icon,
      size: senkrecht ? 30 : 26,
      color: farbe ?? (gewaehlt ? Palette.accent : Palette.textDim),
    );

    return Opacity(
      opacity: aus ? 0.5 : 1,
      child: Semantics(
        button: true,
        selected: gewaehlt,
        child: Druck(
          child: Material(
            color: gewaehlt ? Palette.surfaceRaised : Palette.papier,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: gewaehlt
                    ? (farbe ?? Palette.accent)
                    : Palette.surfaceSunken,
                width: gewaehlt ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                onTap();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: senkrecht
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          zeichen,
                          const SizedBox(height: 6),
                          ...text,
                        ],
                      )
                    : Row(
                        children: <Widget>[
                          zeichen,
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: text,
                            ),
                          ),
                          ?ende,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eine Überschrift in der Liste der Vorlagen.
class AnlegenGruppe extends StatelessWidget {
  const AnlegenGruppe(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Palette.textDim,
        ),
      ),
    );
  }
}

class AnlegenFeld extends StatelessWidget {
  const AnlegenFeld({
    required this.controller,
    required this.hint,
    this.label,
    this.zahl = false,
    this.maxLength,
    this.autofocus = false,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool zahl;
  final int? maxLength;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLength: maxLength,
      keyboardType: zahl ? TextInputType.number : TextInputType.text,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      inputFormatters: zahl
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(fontSize: 15, color: Palette.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        isDense: true,
        labelStyle: const TextStyle(fontSize: 13, color: Palette.textDim),
        hintStyle: const TextStyle(fontSize: 14, color: Palette.muted),
        filled: true,
        fillColor: Palette.papier,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Vorschläge zum Antippen, umgebrochen — hier ist Platz.
class AnlegenVorschlaege extends StatelessWidget {
  const AnlegenVorschlaege({
    required this.vorschlaege,
    required this.onGewaehlt,
    super.key,
  });

  final List<String> vorschlaege;
  final ValueChanged<String> onGewaehlt;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final vorschlag in vorschlaege)
          Druck(
            child: ActionChip(
              label: Text(vorschlag, style: const TextStyle(fontSize: 12)),
              onPressed: () => onGewaehlt(vorschlag),
            ),
          ),
      ],
    );
  }
}
