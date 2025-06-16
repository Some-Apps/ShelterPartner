import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';

class ChatService {
  final Ref ref;
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';
  static const String _apiKey = 'API_KEY';

  ChatService(this.ref);

  Future<String> sendMessage(String message, List<Animal> animals) async {
    try {
      final authState = ref.read(authViewModelProvider);
      if (authState.status != AuthStatus.authenticated) {
        throw Exception('User not authenticated');
      }

      final shelterId = authState.user?.shelterId;
      if (shelterId == null) {
        throw Exception('Shelter ID not found');
      }

      // Get current token count and limit
      final shelterSettings = ref.read(shelterSettingsViewModelProvider).value;
      if (shelterSettings == null) {
        throw Exception('Shelter settings not found');
      }

      final tokenCount = shelterSettings.shelterSettings.tokenCount;
      final tokenLimit = shelterSettings.shelterSettings.tokenLimit;

      if (tokenCount >= tokenLimit) {
        throw Exception(
          'Monthly token limit of $tokenLimit reached. Please try again next month.',
        );
      }

      // Prepare the system message with animal context
      // Limit to 100 animals for context if the list is long
      const maxAnimals = 250;
      final animalsToShow = animals.length > maxAnimals
          ? animals.sublist(0, maxAnimals)
          : animals;
      final animalContext = animalsToShow
          .map((animal) {
            final settings = shelterSettings.shelterSettings;
            final List<String> animalInfo = ['Name: ${animal.name}'];
            if (animal.notes.isNotEmpty) {
              final notesText = animal.notes
                  .map((note) => note.note)
                  .join(', ');
              animalInfo.add('Notes: $notesText');
            }
            animalInfo.add('Age: ${animal.monthsOld} months old');
            animalInfo.add('Other Info: $animal');
            if (settings.showSpecies) {
              animalInfo.add('Species: ${animal.species}');
            }
            if (settings.showBreed) animalInfo.add('Breed: ${animal.breed}');
            if (settings.showDescription) {
              animalInfo.add('Description: ${animal.description}');
            }
            if (settings.showLocation) {
              animalInfo.add('Location: ${animal.location}');
            }
            if (settings.showMedicalInfo) {
              animalInfo.add('Medical Category: ${animal.medicalCategory}');
            }
            if (settings.showBehaviorInfo) {
              animalInfo.add('Behavior Category: ${animal.behaviorCategory}');
            }
            return animalInfo.join(', ');
          })
          .join('\n');
      final moreText = animals.length > maxAnimals
          ? '\n...and more animals available.'
          : '';

      final systemMessage =
          '''
You are a helpful assistant for a pet shelter. Please provide accurate and concise information about the animals in the shelter based on the user's query.


Available animals:\n$animalContext$moreText
''';

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': systemMessage},
                {'role': 'user', 'content': message},
              ],
              'temperature': 0.7,
              'max_tokens': 1000,
              'presence_penalty': 0.0,
              'frequency_penalty': 0.0,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timed out. Please try again.');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = data['usage']['total_tokens'] as int;

        // Update token count in Firestore
        await ref
            .read(shelterSettingsViewModelProvider.notifier)
            .incrementTokenCount(shelterId, tokens);

        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please contact support.');
      } else if (response.statusCode == 429) {
        throw Exception(
          'Rate limit exceeded. Please try again in a few moments.',
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'API Error: ${errorData['error']?['message'] ?? response.body}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred: $e');
    }
  }
}

final chatServiceProvider = Provider((ref) => ChatService(ref));
