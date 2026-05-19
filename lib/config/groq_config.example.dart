// Copy this file to groq_config.dart and fill in your real API key.
// Get a free key at https://console.groq.com → API Keys
//
//   cp lib/config/groq_config.example.dart lib/config/groq_config.dart
//
// groq_config.dart is gitignored — your key will never be committed.

class GroqConfig {
  static const String apiKey = 'YOUR_GROQ_API_KEY_HERE';

  // Model — llama-3.3-70b-versatile is fast, free-tier friendly, and multilingual
  static const String model = 'llama-3.3-70b-versatile';
}
