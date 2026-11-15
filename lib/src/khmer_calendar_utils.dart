/// Khmer weekday names starting from Sunday.
const List<String> khmerWeekdays = [
  'អាទិត្យ', // Sun
  'ចន្ទ', // Mon
  'អង្គារ', // Tue
  'ពុធ', // Wed
  'ព្រហស្បតិ៍', // Thu
  'សុក្រ', // Fri
  'សៅរ៍', // Sat
];

/// Converts an integer into Khmer numerals.
String convertToKhmerNumber(int number) {
  const khmerDigits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];

  return number
      .toString()
      .split('')
      .map((e) => khmerDigits[int.parse(e)])
      .join();
}

/// Returns the Khmer Buddhist Era (ព.ស.) year for a given [date].
int getKhmerBuddhistYear(DateTime date) {
  final khmerNewYear = DateTime(date.year, 4, 14);
  if (date.isBefore(khmerNewYear)) {
    return date.year + 543;
  }
  return date.year + 544;
}
