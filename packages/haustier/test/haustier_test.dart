import 'package:haustier/haustier.dart';
import 'package:test/test.dart';

/// Das Haustier, Prototyp vom 22.10.2026: Es wächst an Tagen mit Häkchen,
/// verliert nie etwas, und sein Zubehör kostet Gold oder wird verdient.
void main() {
  group('Wachstum', () {
    test('jedes Level kostet einen Tag mehr als das vorige', () {
      expect(HaustierWachstum.levelFuer(0), 1);
      expect(HaustierWachstum.levelFuer(1), 2);
      expect(HaustierWachstum.levelFuer(2), 2);
      expect(HaustierWachstum.levelFuer(3), 3);
      expect(HaustierWachstum.levelFuer(10), 5);
      expect(HaustierWachstum.levelFuer(45), 10);
      expect(HaustierWachstum.levelFuer(351), 27);
      for (var level = 2; level < 40; level++) {
        expect(
          HaustierWachstum.tageFuer(level + 1) -
              HaustierWachstum.tageFuer(level),
          level,
        );
      }
    });

    test('die Stufen folgen dem Level: schlüpft nach drei Tagen', () {
      expect(HaustierWachstum.stufeFuer(0), HaustierStufe.ei);
      expect(HaustierWachstum.stufeFuer(2), HaustierStufe.ei);
      expect(HaustierWachstum.stufeFuer(3), HaustierStufe.schluepfling);
      expect(HaustierWachstum.stufeFuer(15), HaustierStufe.jung);
      expect(HaustierWachstum.stufeFuer(45), HaustierStufe.ausgewachsen);
      expect(HaustierWachstum.stufeFuer(136), HaustierStufe.praechtig);
      expect(HaustierWachstum.stufeFuer(351), HaustierStufe.uralt);
      expect(HaustierWachstum.stufeFuer(5000), HaustierStufe.uralt);
    });

    test('jede Stufe kommt später als die vorige', () {
      const stufen = HaustierStufe.values;
      for (var i = 1; i < stufen.length; i++) {
        expect(stufen[i].abTagen, greaterThan(stufen[i - 1].abTagen));
      }
      expect(HaustierWachstum.naechsteStufe(HaustierStufe.uralt), isNull);
    });

    test('was bis zum nächsten Level fehlt, ist nie null', () {
      for (var tage = 0; tage < 400; tage++) {
        expect(HaustierWachstum.tageBisNaechstes(tage), greaterThan(0));
      }
    });
  });

  group('Laune', () {
    HaustierLaune laune(int faellig, int erledigt, [int stunde = 12]) =>
        HaustierLaune.aus(faellig: faellig, erledigt: erledigt, stunde: stunde);

    test('ohne Häkchen wartet es — es leidet nie', () {
      expect(laune(3, 0), HaustierLaune.wartet);
    });

    test('ein Häkchen macht es munter, alles erledigt lässt es spielen', () {
      expect(laune(3, 1), HaustierLaune.munter);
      expect(laune(3, 3), HaustierLaune.spielt);
    });

    test('an einem Ruhetag ruht es', () {
      expect(laune(0, 0), HaustierLaune.ruht);
    });

    test('nachts schläft es, egal was erledigt ist', () {
      expect(laune(3, 3, 23), HaustierLaune.schlaeft);
      expect(laune(3, 0, 3), HaustierLaune.schlaeft);
      expect(laune(3, 0, 6), HaustierLaune.wartet);
    });
  });

  group('Der Stand', () {
    final strohhut = ZubehoerKatalog.byId('strohhut')!;
    final zauberhut = ZubehoerKatalog.byId('zauberhut')!;
    final krone = ZubehoerKatalog.byId('krone')!;

    test('ein Ei wird genau einmal gewählt', () {
      final stand = const HaustierStand.leer()
          .waehle(HaustierArt.eule)
          .waehle(HaustierArt.drache);
      expect(stand.art, HaustierArt.eule);
      expect(stand.anzeigeName, 'Eule');
    });

    test('ohne Ei lässt sich nichts kaufen', () {
      const stand = HaustierStand.leer();
      expect(stand.kannKaufen(strohhut, verfuegbaresGold: 999), isFalse);
      expect(stand.kaufe(strohhut, verfuegbaresGold: 999), same(stand));
    });

    test('kaufen kostet den Preis und legt auf einen freien Platz an', () {
      final stand = const HaustierStand.leer()
          .waehle(HaustierArt.katze)
          .kaufe(strohhut, verfuegbaresGold: 40);

      expect(stand.spentGold, 40);
      expect(stand.angelegtAuf(ZubehoerPlatz.kopf, HaustierStufe.ei), strohhut);
    });

    test('ein zweiter Hut verdrängt den ersten nicht von selbst', () {
      final stand = const HaustierStand.leer()
          .waehle(HaustierArt.katze)
          .kaufe(strohhut, verfuegbaresGold: 999)
          .kaufe(zauberhut, verfuegbaresGold: 999);

      expect(stand.spentGold, 160);
      expect(stand.angelegtAuf(ZubehoerPlatz.kopf, HaustierStufe.ei), strohhut);
      expect(
        stand
            .lege(zauberhut, HaustierStufe.ei)
            .angelegtAuf(ZubehoerPlatz.kopf, HaustierStufe.ei),
        zauberhut,
      );
    });

    test('zu teuer, schon gekauft oder verdient: kein Kauf', () {
      final stand = const HaustierStand.leer().waehle(HaustierArt.drache);
      expect(stand.kannKaufen(zauberhut, verfuegbaresGold: 119), isFalse);
      final gekauft = stand.kaufe(strohhut, verfuegbaresGold: 40);
      expect(gekauft.kannKaufen(strohhut, verfuegbaresGold: 999), isFalse);
      expect(stand.kannKaufen(krone, verfuegbaresGold: 9999), isFalse);
    });

    test('verdientes Zubehör kommt mit der Stufe und lässt sich anlegen', () {
      final stand = const HaustierStand.leer().waehle(HaustierArt.drache);
      expect(stand.besitzt(krone, HaustierStufe.ausgewachsen), isFalse);
      expect(stand.besitzt(krone, HaustierStufe.praechtig), isTrue);
      expect(stand.lege(krone, HaustierStufe.jung), same(stand));
      expect(
        stand
            .lege(krone, HaustierStufe.uralt)
            .angelegtAuf(ZubehoerPlatz.kopf, HaustierStufe.uralt),
        krone,
      );
    });

    test('ablegen macht den Platz frei', () {
      final stand = const HaustierStand.leer()
          .waehle(HaustierArt.drache)
          .kaufe(strohhut, verfuegbaresGold: 40)
          .ablege(ZubehoerPlatz.kopf);
      expect(stand.angelegtAuf(ZubehoerPlatz.kopf, HaustierStufe.ei), isNull);
      expect(stand.spentGold, 40, reason: 'gekauft bleibt gekauft');
    });

    test('der Name wird gekürzt, ein leerer zeigt die Art', () {
      final stand = const HaustierStand.leer().waehle(HaustierArt.eule);
      expect(stand.benenne('  ').anzeigeName, 'Eule');
      expect(
        stand.benenne('Ein sehr, sehr langer Name für eine Eule').name.length,
        HaustierStand.maxNameLength,
      );
    });

    test('übersteht das Speichern', () {
      final stand = const HaustierStand.leer()
          .waehle(HaustierArt.katze)
          .benenne('Minka')
          .kaufe(strohhut, verfuegbaresGold: 40)
          .kaufe(ZubehoerKatalog.byId('ball')!, verfuegbaresGold: 40);
      final gelesen = HaustierStand.fromJson(stand.toJson());

      expect(gelesen.art, HaustierArt.katze);
      expect(gelesen.name, 'Minka');
      expect(gelesen.spentGold, 65);
      expect(gelesen.angelegt, stand.angelegt);
    });

    test('Unbekanntes beim Laden wird übersprungen, nicht geworfen', () {
      final gelesen = HaustierStand.fromJson(<String, Object?>{
        'art': 'einhorn',
        'gekauft': <String, Object?>{'gibt-es-nicht': 10, 'strohhut': 'viel'},
        'angelegt': <String, Object?>{'kopf': 'ball', 'schwanz': 'strohhut'},
      });

      expect(gelesen.isEmpty, isTrue);
    });

    test('ein leerer Stand schreibt nichts', () {
      expect(const HaustierStand.leer().toJson(), isEmpty);
    });
  });

  group('Der Katalog', () {
    test('jede Id einmal, jeder Platz mit gekauften und verdienten Stücken',
        () {
      final ids = ZubehoerKatalog.alle.map((z) => z.id).toSet();
      expect(ids, hasLength(ZubehoerKatalog.alle.length));
      for (final platz in ZubehoerPlatz.values) {
        final stuecke = ZubehoerKatalog.fuer(platz);
        expect(stuecke.where((z) => z.istVerdient), isNotEmpty);
        expect(stuecke.where((z) => !z.istVerdient), isNotEmpty);
      }
    });

    test('kein Preis über fünf Tage Gold (25 am Tag)', () {
      for (final z in ZubehoerKatalog.alle.where((z) => !z.istVerdient)) {
        expect(z.preis, inInclusiveRange(1, 5 * 25), reason: z.id);
      }
    });
  });
}
