/// Ein Kalendertag ohne Uhrzeit.
///
/// Ein Habit wird an einem Tag abgehakt, nicht um 21:43 Uhr. `DateTime`
/// direkt zu benutzen wäre hier ein Fehler: Zwei Häkchen am selben Tag
/// hätten unterschiedliche Werte, und Rechnen mit lokalen `DateTime`s
/// verschluckt bei Zeitumstellung einen Tag. Deshalb dieser eigene Typ —
/// intern wird ausschließlich in UTC gerechnet.
class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.day);

  /// Der Kalendertag, auf den ein Zeitpunkt fällt — lokale Zeit, denn der
  /// Nutzer hakt in seiner Zeitzone ab.
  factory Day.from(DateTime time) => Day(time.year, time.month, time.day);

  /// Liest die ISO-Form aus [toString] zurück. Null bei allem, was nicht
  /// passt.
  ///
  /// Bewusst nachsichtig statt werfend: Der Aufrufer ist ein
  /// Speicherstand, der von einer älteren Programmversion stammen kann.
  /// Ein einzelner unlesbarer Tag darf einen Ladevorgang nicht abbrechen —
  /// sonst kostet ein Formatfehler den ganzen Fortschritt.
  static Day? tryParse(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    // Fängt den 31. Februar: Die Grenzen oben lassen ihn durch, aber
    // `DateTime.utc` schiebt ihn auf den 3. März, und dann stimmt der
    // normalisierte Tag nicht mehr mit dem gelesenen überein.
    final parsed = Day(year, month, day);
    final normalised = Day.from(DateTime.utc(year, month, day));
    return normalised == parsed ? parsed : null;
  }

  final int year;
  final int month;
  final int day;

  /// Mitternacht dieses Tages in UTC. Nur für Rechnungen gedacht, nicht
  /// zum Anzeigen.
  DateTime get _utc => DateTime.utc(year, month, day);

  Day get previous => _shifted(-1);

  Day get next => _shifted(1);

  Day _shifted(int days) {
    return Day.from(_utc.add(Duration(days: days)));
  }

  /// Wie viele Tage von hier bis [other]. Negativ, wenn [other] früher ist.
  int daysUntil(Day other) => other._utc.difference(_utc).inDays;

  @override
  int compareTo(Day other) => _utc.compareTo(other._utc);

  bool operator <(Day other) => compareTo(other) < 0;

  bool operator <=(Day other) => compareTo(other) <= 0;

  bool operator >(Day other) => compareTo(other) > 0;

  bool operator >=(Day other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    return other is Day &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO-Form, `2026-08-12`. Stabil genug, um später als Datenbank-
  /// Schlüssel zu dienen.
  @override
  String toString() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }
}
