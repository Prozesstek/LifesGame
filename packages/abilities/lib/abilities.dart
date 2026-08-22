/// Woher eine Faehigkeit kommt und wann sie offen ist.
///
/// Reines Dart: kein Flutter, keine Dependencies. Dieses Package kennt
/// weder `combat` (was eine Faehigkeit *tut*) noch `gear` oder `habits`
/// (woher der Fortschritt kommt). Es haelt ausschliesslich Ids und
/// Bedingungen; die App fuegt beides zusammen (ADR-0017).
library;

export 'src/ability.dart';
export 'src/ability_catalog.dart';
export 'src/chosen_abilities.dart';
