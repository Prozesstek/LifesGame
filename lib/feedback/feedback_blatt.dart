import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ui/druck.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'feedback_bericht.dart';
import 'feedback_dienst.dart';
import 'geraete_info.dart';

/// Öffnet das Feedback-Blatt. Gibt `true` zurück, wenn es angekommen
/// ist; sonst `null` (geschlossen, ohne zu senden).
Future<bool?> zeigeFeedbackBlatt(
  BuildContext context, {
  required FeedbackDienst dienst,
  Uint8List? screenshot,
  String? screen,
  String? spieler,
  int? level,
  Future<FeedbackUmgebung> Function() umgebung = leseUmgebung,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => FeedbackBlatt(
      dienst: dienst,
      screenshot: screenshot,
      screen: screen,
      spieler: spieler,
      level: level,
      umgebung: umgebung,
    ),
  );
}

/// **Das Feedback-Blatt** (11.11.2026): Kategorie, ein Satz, das Bild des
/// Screens — in unter fünfzehn Sekunden abgeschickt. Scheitert das
/// Senden, bleibt das Blatt offen und der Text stehen.
class FeedbackBlatt extends StatefulWidget {
  const FeedbackBlatt({
    required this.dienst,
    required this.umgebung,
    this.screenshot,
    this.screen,
    this.spieler,
    this.level,
    super.key,
  });

  final FeedbackDienst dienst;
  final Future<FeedbackUmgebung> Function() umgebung;
  final Uint8List? screenshot;
  final String? screen;
  final String? spieler;
  final int? level;

  static const Key sendenKey = ValueKey<String>('feedback-senden');
  static const Key textKey = ValueKey<String>('feedback-text');
  static const Key bildWegKey = ValueKey<String>('feedback-bild-weg');

  @override
  State<FeedbackBlatt> createState() => _FeedbackBlattState();
}

class _FeedbackBlattState extends State<FeedbackBlatt> {
  final TextEditingController _text = TextEditingController();
  FeedbackArt? _art;
  Uint8List? _bild;
  bool _sendet = false;
  String? _fehler;

  @override
  void initState() {
    super.initState();
    _bild = widget.screenshot;
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  static const double _vorschauHoehe = 150;
  static const double _vorschauBreite = 72;

  bool get _bereit => _art != null && _text.text.trim().isNotEmpty;

  Future<void> _senden() async {
    final art = _art;
    if (art == null || !_bereit || _sendet) return;
    setState(() {
      _sendet = true;
      _fehler = null;
    });
    try {
      final umgebung = await widget.umgebung();
      await widget.dienst.senden(
        FeedbackBericht(
          art: art,
          text: _text.text.trim(),
          zeitpunkt: DateTime.now(),
          umgebung: umgebung,
          screenshot: _bild,
          screen: widget.screen,
          spieler: widget.spieler,
          level: widget.level,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FeedbackFehler catch (f) {
      if (mounted) {
        setState(() {
          _sendet = false;
          _fehler = f.meldung;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unten = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: unten),
      child: HolzBlatt(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Feedback',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Palette.text,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Schließen',
                      icon: const Icon(Icons.close, color: Palette.textDim),
                      onPressed: _sendet
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final art in FeedbackArt.values)
                      ChoiceChip(
                        label: Text(art.beschriftung),
                        selected: _art == art,
                        onSelected: _sendet
                            ? null
                            : (_) => setState(() => _art = art),
                        selectedColor: Palette.goldOnDark,
                        labelStyle: const TextStyle(color: Palette.text),
                        showCheckmark: false,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: FeedbackBlatt.textKey,
                  controller: _text,
                  enabled: !_sendet,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Was ist passiert?',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (_bild case final bild?) ...<Widget>[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    // **Feste Größe**, im Hochformat des Handys: Solange
                    // das Bild dekodiert, hätte es sonst keine, und das X
                    // läge außerhalb, wo es keinen Tipp annimmt.
                    child: SizedBox(
                      width: _vorschauBreite,
                      height: _vorschauHoehe,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ColoredBox(
                              color: Palette.background,
                              child: Image.memory(
                                bild,
                                fit: BoxFit.contain,
                                semanticLabel: 'Bild des Screens',
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Tooltip(
                              message: 'Bild entfernen',
                              child: Druck(
                                child: GestureDetector(
                                  key: FeedbackBlatt.bildWegKey,
                                  onTap: _sendet
                                      ? null
                                      : () => setState(() => _bild = null),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Palette.background,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Palette.goldOnDark,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Palette.goldOnDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Gerätemodell, Android-Version und App-Version werden '
                  'mitgesendet.',
                  style: TextStyle(fontSize: 12, color: Palette.textDim),
                ),
                if (_fehler case final f?) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    f,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Palette.enemy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  key: FeedbackBlatt.sendenKey,
                  onPressed: _bereit && !_sendet ? _senden : null,
                  child: _sendet
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Senden'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
