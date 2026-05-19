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

  static const _assistantSystemPrompt = '''You are QuickFix Assistant, a helpful AI for the QuickFix home services marketplace in Kigali, Rwanda.
You help homeowners and artisans navigate the app and understand local service pricing.

Key facts:
- QuickFix connects homeowners with verified local artisans in Kigali (Gasabo, Kicukiro, Nyarugenge)
- Services: Plumbing, Electrical, Painting, Carpentry, Cleaning, Masonry
- Homeowners post a job → artisans send bids → homeowner picks the best bid
- Typical Kigali price ranges:
  • Plumbing: 5,000–50,000 RWF (minor leak to full installation)
  • Electrical: 8,000–80,000 RWF (socket fix to rewiring)
  • Painting: 10,000–150,000 RWF (one room to full house)
  • Carpentry: 15,000–200,000 RWF (furniture repair to custom build)
  • Cleaning: 5,000–30,000 RWF (deep clean to move-in/out)
  • Masonry: 20,000–500,000 RWF (crack repair to major construction)
- Payment is agreed directly between homeowner and artisan after the bid is accepted
- Artisans on QuickFix are background-verified

How to use the app (homeowner):
- Post a job: tap the "Post a Job" button (bottom of the Home tab)
- Browse artisans: use the Search tab to filter by category, district, rating, or price
- Track a job: tap "Track" on any job card to see live status updates
- Chat: tap the Messages tab to message an artisan directly
- Review: after a job is marked complete you can rate the artisan

How to use the app (artisan):
- Browse open jobs in the "For You" tab and submit a bid
- Accept or decline direct booking invitations in the Invitations tab
- Update job status when you're on the way, working, or done
- Toggle your availability on/off from your profile

Keep answers short (2–4 sentences), friendly and practical. Reply in the same language the user writes in (English, French, or Kinyarwanda).''';

  /// Sends a multi-turn conversation to the QuickFix Assistant.
  /// [history] is a list of prior {role, content} maps (user + assistant turns).
  /// [userMessage] is the new message from the user.
  static Future<String> assistantChat({
    required List<Map<String, String>> history,
    required String userMessage,
  }) async {
    if (GroqConfig.apiKey.isEmpty ||
        GroqConfig.apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw Exception(
        'Groq API key not configured. '
        'Open lib/config/groq_config.dart and add your key.',
      );
    }

    final messages = [
      {'role': 'system', 'content': _assistantSystemPrompt},
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer ${GroqConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': GroqConfig.model,
            'messages': messages,
            'max_tokens': 300,
            'temperature': 0.6,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = (body['error'] as Map?)?['message'] ?? 'Unknown error';
      throw Exception('Groq API error (${response.statusCode}): $msg');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['choices'][0]['message']['content'] as String).trim();
  }
}
