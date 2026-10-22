import 'art.dart';
import 'wachstum.dart';
import 'zubehoer.dart';

/// Was am Haustier gespeichert wird — **nur, was der Spieler gewählt
/// hat**: das Ei, den Namen, was gekauft und was angelegt ist.
///
/// Wie weit es gewachsen ist und wie es gelaunt ist, steht nicht hier: Das
/// folgt aus den Häkchen ([HaustierWachstum], `HaustierLaune`). Gold ist
/// wie bei der Ausrüstung eine Rechnung aus der Liste des Gekauften samt
/// bezahltem Preis ([spentGold]).
class HaustierStand {
  const HaustierStand({
    this.art,
    this.name = '',
    Map<String, int> gekauft = const <String, int>{},
    Map<ZubehoerPlatz, String> angelegt = const <ZubehoerPlatz, String>{},
  })  : _gekauft = gekauft,
        _angelegt = angelegt;

  const HaustierStand.leer() : this();

  /// Wie lang ein Name höchstens ist.
  static const int maxNameLength = 20;

  /// Das gewählte Ei — null, solange keins gewählt ist.
  final HaustierArt? art;

  final String name;

  /// Was gekauft wurde, samt bezahltem Preis — eine Historie.
  final Map<String, int> _gekauft;

  /// Was auf welchem Platz angelegt ist.
  final Map<ZubehoerPlatz, String> _angelegt;

  Map<String, int> get gekauft => Map<String, int>.unmodifiable(_gekauft);

  Map<ZubehoerPlatz, String> get angelegt =>
      Map<ZubehoerPlatz, String>.unmodifiable(_angelegt);

  bool get hatEi => art != null;

  bool get isEmpty =>
      art == null && name.isEmpty && _gekauft.isEmpty && _angelegt.isEmpty;

  /// Der Name, oder die Art, solange es keinen hat.
  String get anzeigeName {
    final eigener = name.trim();
    if (eigener.isNotEmpty) return eigener;
    return art?.label ?? '';
  }

  /// Was das Tier an Gold gekostet hat.
  int get spentGold => _gekauft.values.fold(0, (sum, preis) => sum + preis);

  HaustierStand _copyWith({
    HaustierArt? art,
    String? name,
    Map<String, int>? gekauft,
    Map<ZubehoerPlatz, String>? angelegt,
  }) {
    return HaustierStand(
      art: art ?? this.art,
      name: name ?? this.name,
      gekauft: gekauft ?? _gekauft,
      angelegt: angelegt ?? _angelegt,
    );
  }

  /// Wählt ein Ei — **genau einmal**. Wer schon eins hat, behält es.
  HaustierStand waehle(HaustierArt gewaehlt) {
    if (art != null) return this;
    return _copyWith(art: gewaehlt);
  }

  HaustierStand benenne(String neu) {
    final sauber = neu.trim();
    return _copyWith(
      name: sauber.length > maxNameLength
          ? sauber.substring(0, maxNameLength)
          : sauber,
    );
  }

  /// Ob das Tier [stueck] hat: gekauft, oder seine Stufe ist erreicht.
  bool besitzt(Zubehoer stueck, HaustierStufe stufe) {
    final ab = stueck.abStufe;
    if (ab != null) return stufe.index >= ab.index;
    return _gekauft.containsKey(stueck.id);
  }

  /// Ob [stueck] sich für [verfuegbaresGold] kaufen lässt.
  bool kannKaufen(Zubehoer stueck, {required int verfuegbaresGold}) {
    final preis = stueck.preis;
    if (art == null || preis == null) return false;
    if (_gekauft.containsKey(stueck.id)) return false;
    return preis <= verfuegbaresGold;
  }

  /// Kauft [stueck] und legt es gleich an, wenn sein Platz frei ist.
  /// Unverändert, wenn es nicht geht ([kannKaufen]).
  HaustierStand kaufe(Zubehoer stueck, {required int verfuegbaresGold}) {
    if (!kannKaufen(stueck, verfuegbaresGold: verfuegbaresGold)) return this;
    return _copyWith(
      gekauft: <String, int>{..._gekauft, stueck.id: stueck.preis!},
      angelegt: _angelegt.containsKey(stueck.platz)
          ? _angelegt
          : <ZubehoerPlatz, String>{..._angelegt, stueck.platz: stueck.id},
    );
  }

  /// Legt [stueck] an — nur, was das Tier hat.
  HaustierStand lege(Zubehoer stueck, HaustierStufe stufe) {
    if (!besitzt(stueck, stufe)) return this;
    return _copyWith(
      angelegt: <ZubehoerPlatz, String>{..._angelegt, stueck.platz: stueck.id},
    );
  }

  HaustierStand ablege(ZubehoerPlatz platz) {
    if (!_angelegt.containsKey(platz)) return this;
    return _copyWith(
      angelegt: <ZubehoerPlatz, String>{
        for (final e in _angelegt.entries)
          if (e.key != platz) e.key: e.value,
      },
    );
  }

  /// Was auf [platz] sitzt — wenn das Tier es noch hat.
  Zubehoer? angelegtAuf(ZubehoerPlatz platz, HaustierStufe stufe) {
    final stueck = ZubehoerKatalog.byId(_angelegt[platz]);
    if (stueck == null || !besitzt(stueck, stufe)) return null;
    return stueck;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (art != null) 'art': art!.name,
      if (name.isNotEmpty) 'name': name,
      if (_gekauft.isNotEmpty) 'gekauft': _gekauft,
      if (_angelegt.isNotEmpty)
        'angelegt': <String, String>{
          for (final e in _angelegt.entries) e.key.name: e.value,
        },
    };
  }

  /// Liest einen Stand — nachsichtig wie jeder andere: Unbekanntes wird
  /// übersprungen, nie geworfen (ADR-0010).
  factory HaustierStand.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final gekauft = <String, int>{};
    final rohGekauft = json['gekauft'];
    if (rohGekauft is Map) {
      for (final e in rohGekauft.entries) {
        final id = e.key;
        final preis = e.value;
        if (id is String && preis is int && ZubehoerKatalog.byId(id) != null) {
          gekauft[id] = preis;
        }
      }
    }
    final angelegt = <ZubehoerPlatz, String>{};
    final rohAngelegt = json['angelegt'];
    if (rohAngelegt is Map) {
      for (final e in rohAngelegt.entries) {
        for (final platz in ZubehoerPlatz.values) {
          final id = e.value;
          if (platz.name == e.key &&
              id is String &&
              ZubehoerKatalog.byId(id)?.platz == platz) {
            angelegt[platz] = id;
          }
        }
      }
    }
    return HaustierStand(
      art: HaustierArt.tryParse(json['art']),
      name: name is String ? name : '',
      gekauft: gekauft,
      angelegt: angelegt,
    );
  }
}
