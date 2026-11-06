import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/erster_start.dart';
import '../home/erster_start_provider.dart';
import '../ui/aufstieg.dart';

/// **Die Bühne des Tutorials** (06.11.2026): Darunter gilt ein neuer
/// Stand des ersten Starts erst, **wenn man ihn sehen kann** — keine
/// Feier in der Mitte, kein Blatt über dem Bildschirm.
///
/// Sonst flöge nach dem ersten Häkchen alles hinter der großen Flamme und
/// der Errungenschaft herein, und wer sie schließt, stünde vor dem
/// fertigen Bild. Jetzt baut es sich auf, während man hinsieht
/// (`DerReiheNach`).
///
/// Darunter liest jedes Widget den gezeigten Stand über denselben
/// Provider (`ersterStartProvider`, hier überschrieben). Gerechnet wird
/// nichts: Die Bühne hält nur den letzten Stand fest, bis wieder frei ist,
/// und wartet dann noch [ruhe] — zwischen dem Ende der Flamme und dem
/// Blatt der Errungenschaft liegt sonst ein Bild, in dem frei wäre.
class Buehne extends ConsumerStatefulWidget {
  const Buehne({required this.child, super.key});

  final Widget child;

  /// Wie lange es frei sein muss, bevor der neue Stand gilt.
  static const Duration ruhe = Duration(milliseconds: 250);

  @override
  ConsumerState<Buehne> createState() => _BuehneState();
}

/// Ohne Host steht nie etwas in der Mitte.
final ValueNotifier<int> _leer = ValueNotifier<int>(0);

class _BuehneState extends ConsumerState<Buehne>
    with SingleTickerProviderStateMixin {
  ErsterStart? _gezeigt;

  /// Die Wurzel darüber. Wechselt sie (in Tests: ein neuer Stand),
  /// gilt ihr Stand sofort.
  ProviderContainer? _wurzel;

  // Ein Takt, kein Zeitgeber: `pumpAndSettle` wartet auf ihn (`gotchas.md`).
  late final AnimationController _warten;

  @override
  void initState() {
    super.initState();
    _warten = AnimationController(vsync: this, duration: Buehne.ruhe)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() => _gezeigt = ref.read(ersterStartProvider));
      });
  }

  @override
  void dispose() {
    _warten.dispose();
    super.dispose();
  }

  bool _frei(AufstiegHostState? host) {
    final vorn = ModalRoute.of(context)?.isCurrent ?? true;
    return vorn && (host?.inDerMitte.value ?? 0) == 0;
  }

  @override
  Widget build(BuildContext context) {
    final echt = ref.watch(ersterStartProvider);
    final wurzel = ProviderScope.containerOf(context, listen: false);
    if (!identical(wurzel, _wurzel)) {
      _wurzel = wurzel;
      _gezeigt = echt;
    }
    final host = AufstiegHost.maybeOf(context);
    final mitte = host?.inDerMitte ?? _leer;

    return ValueListenableBuilder<int>(
      valueListenable: mitte,
      builder: (context, _, _) {
        final gezeigt = _gezeigt ??= echt;
        if (!identical(gezeigt, echt)) {
          if (!_frei(host)) {
            _warten.stop();
          } else if (!_warten.isAnimating) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_warten.isAnimating) _warten.forward(from: 0);
            });
          }
        }
        return ProviderScope(
          // Eine neue Wurzel darüber (in Tests: ein neuer Stand) bekommt
          // auch eine neue Bühne — sonst wirft Riverpod.
          key: ObjectKey(wurzel),
          overrides: [ersterStartProvider.overrideWithValue(gezeigt)],
          child: widget.child,
        );
      },
    );
  }
}
