import 'package:lifes_game/home/erster_start_provider.dart';

/// Der Hinweis auf die Gewohnheiten (`Schritt.gewohnheitenZeigen`) ist
/// schon weggetippt. Für Tests der Startseite, die nach einem Häkchen
/// weitertippen und nicht den Mentor prüfen — sonst fängt seine
/// Tippfläche den Tipp ab.
final hinweisGesehen = gewohnheitenGezeigtProvider.overrideWith(
  () => GewohnheitenGezeigt(schon: true),
);
