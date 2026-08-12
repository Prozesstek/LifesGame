import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Ein Eintrag auf dem Startbildschirm.
///
/// Ohne [onTap] ist die Kachel gesperrt. Sie wird dann trotzdem angezeigt —
/// der Startbildschirm soll zeigen, was das Spiel vorhat, nicht nur was
/// heute schon geht.
class HubTile extends StatelessWidget {
  const HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.status,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Kurzer Zustand rechts, etwa „2 / 5 Lektionen“.
  final String? status;

  final VoidCallback? onTap;

  bool get _isLocked => onTap == null;

  @override
  Widget build(BuildContext context) {
    final foreground = _isLocked ? Palette.muted : Colors.white;

    return Semantics(
      button: !_isLocked,
      enabled: !_isLocked,
      child: Material(
        color: _isLocked ? Palette.surface : Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 26,
                  color: _isLocked ? Palette.muted : Palette.accent,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Palette.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (status != null)
                  Text(
                    status ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isLocked ? Palette.muted : Palette.textDim,
                    ),
                  )
                else if (!_isLocked)
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Palette.textDim,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
