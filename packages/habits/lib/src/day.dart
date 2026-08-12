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
