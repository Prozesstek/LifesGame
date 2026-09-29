import 'package:flutter/material.dart';

import 'palette.dart';

/// Ruhm als Zeichen mit Zahl — überall dasselbe, statt „75 Ruhm“.
class RuhmZahl extends StatelessWidget {
  const RuhmZahl({required this.fame, this.size = 13, super.key});

  final int fame;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$fame Ruhm',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.workspace_premium_rounded,
            size: size + 3,
            color: Palette.textDim,
          ),
          const SizedBox(width: 2),
          Text(
            '$fame',
            style: TextStyle(fontSize: size, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}
