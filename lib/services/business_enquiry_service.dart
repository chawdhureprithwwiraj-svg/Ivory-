import 'package:supabase_flutter/supabase_flutter.dart';

const int _businessEnquiryWordLimit = 3000;
const int _businessEnquiryCharacterLimit = 100000;

int _businessEnquiryWordCount(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

/// Sends a member's business note to the private inbox function and lets
/// Ivory review submissions through the owner-only Admin screen.
class BusinessEnquiryService {
  BusinessEnquiryService._();

  static final BusinessEnquiryService instance = BusinessEnquiryService._();
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> submit(String message) async {
    final String clean = message.trim();
    if (clean.isEmpty ||
        clean.length > _businessEnquiryCharacterLimit ||
        _businessEnquiryWordCount(clean) > _businessEnquiryWordLimit) {
      throw const BusinessEnquiryError(
        'Please keep your note within 3,000 words.',
      );
    }

    try {
      final FunctionResponse response = await _client.functions.invoke(
        'business-enquiry',
        method: HttpMethod.post,
        body: <String, dynamic>{'message': clean},
      );
      final dynamic data = response.data;
      if (response.status != 200 || data is! Map || data['ok'] != true) {
        throw const BusinessEnquiryError(
          'The note could not be sent just now. Please try again.',
        );
      }
    } on BusinessEnquiryError {
      rethrow;
    } catch (_) {
      throw const BusinessEnquiryError(
        'The note could not be sent just now. Please try again.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchForOwner() async {
    final List<dynamic> rows = await _client
        .from('business_enquiries')
        .select('id, sender_id, message, status, email_status, created_at')
        .order('created_at', ascending: false)
        .limit(100);
    if (rows.isEmpty) return <Map<String, dynamic>>[];

    final List<String> ids = rows
        .map((dynamic row) => row['sender_id'].toString())
        .toSet()
        .toList();
    final List<dynamic> profiles = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', ids);
    final Map<String, String> names = <String, String>{
      for (final dynamic row in profiles)
        row['id'].toString(): row['display_name']?.toString() ?? 'Ivory member',
    };

    return rows.map((dynamic row) {
      final Map<String, dynamic> item = Map<String, dynamic>.from(row);
      item['display_name'] = names[item['sender_id'].toString()] ?? 'Ivory member';
      return item;
    }).toList();
  }

  Future<void> markRead(int id) async {
    await _client
        .from('business_enquiries')
        .update(<String, dynamic>{'status': 'read'})
        .eq('id', id);
  }
}

class BusinessEnquiryError implements Exception {
  const BusinessEnquiryError(this.message);
  final String message;

  @override
  String toString() => message;
}

// END OF FILE - lib/services/business_enquiry_service.dart
