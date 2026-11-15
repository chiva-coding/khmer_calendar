import 'dart:convert';

import 'package:http/http.dart' as http;

/// Represents a public holiday entry displayed in [KhmerCalendarView].
class KhmerHoliday {
  final DateTime date;
  final String name;
  final String localName;

  const KhmerHoliday({
    required this.date,
    required this.name,
    required this.localName,
  });

  factory KhmerHoliday.fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.parse(json['date'] as String);
    return KhmerHoliday(
      date: DateTime.utc(parsed.year, parsed.month, parsed.day),
      name: (json['name'] as String?) ?? '',
      localName: (json['localName'] as String?) ?? '',
    );
  }
}

/// Fetches Cambodia public holidays from Nager.Date API.
class KhmerHolidayService {
  const KhmerHolidayService._();

  static Future<List<KhmerHoliday>> fetchPublicHolidays(
    int year, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldClose = client == null;
    try {
      final url = Uri.parse(
        'https://date.nager.at/api/v3/PublicHolidays/$year/KH',
      );
      final response = await httpClient.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map(KhmerHoliday.fromJson)
            .toList();
      }
      throw Exception('Error: (${response.statusCode})');
    } finally {
      if (shouldClose) {
        httpClient.close();
      }
    }
  }
}
