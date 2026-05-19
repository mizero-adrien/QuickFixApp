import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quickfix/config/groq_config.dart';

class GroqService {
  static const _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Generates an improved job description from the homeowner's rough notes.
  /// Throws an [Exception] on API or network errors.
  static Future<String> improveJobDescription({
    required String category,
    required String title,
    required String roughNotes,
  }) async {
    if (GroqConfig.apiKey.isEmpty ||
        GroqConfig.apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw Exception(
        'Groq API key not set.\n'
        'Open lib/config/groq_config.dart and replace '
        'YOUR_GROQ_API_KEY_HERE with your key from console.groq.com.',
      );
    }

    final prompt = '''You are helping a homeowner in Rwanda post a job on QuickFix, a home services marketplace.
Based on the details below, write a clear professional job description that skilled artisans can act on.

Service category: $category
Job title: $title
Homeowner's rough notes: $roughNotes

Rules:
- 2 to 4 sentences, no bullet points
- Be specific about the problem and where in the home it is (e.g. kitchen, bathroom, roof)
- Mention any urgency if implied by the notes
- State what outcome the homeowner expects
- No greetings, no sign-offs, no section headers or labels
- Reply in the same language the homeowner used (English, French, or Kinyarwanda)''';

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer ${GroqConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': GroqConfig.model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'max_tokens': 220,
            'temperature': 0.65,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = (body['error'] as Map?)?['message'] ?? 'Unknown error';
      throw Exception('Groq API error (${response.statusCode}): $msg');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        data['choices'][0]['message']['content'] as String;
    return content.trim();
  }
}
