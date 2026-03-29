import 'package:shared_preferences/shared_preferences.dart';

class LeadData {
  const LeadData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.whatsapp,
    this.source = 'ai_analysis',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String whatsapp;
  final String source; // "ai_analysis" or "trading_demo"

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'whatsapp': whatsapp,
        'source': source,
      };
}

class LeadService {
  static const _keyFirst = 'lead_first_name';
  static const _keyLast = 'lead_last_name';
  static const _keyEmail = 'lead_email';
  static const _keyWhatsapp = 'lead_whatsapp';

  /// Check if lead data already saved.
  static Future<bool> hasLead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail)?.isNotEmpty == true;
  }

  /// Load saved lead data.
  static Future<LeadData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    if (email == null || email.isEmpty) return null;
    return LeadData(
      firstName: prefs.getString(_keyFirst) ?? '',
      lastName: prefs.getString(_keyLast) ?? '',
      email: email,
      whatsapp: prefs.getString(_keyWhatsapp) ?? '',
    );
  }

  /// Save lead data locally + send to backend (mock).
  static Future<void> save(LeadData lead) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFirst, lead.firstName);
    await prefs.setString(_keyLast, lead.lastName);
    await prefs.setString(_keyEmail, lead.email);
    await prefs.setString(_keyWhatsapp, lead.whatsapp);

    // TODO: бэкендер — отправить на сервер
    // await dio.post('/leads', data: lead.toJson());
  }

  /// Clear saved lead (for testing).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirst);
    await prefs.remove(_keyLast);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyWhatsapp);
  }
}
