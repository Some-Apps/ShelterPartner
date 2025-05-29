import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/services/chat_service.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class ChatInterface extends ConsumerStatefulWidget {
  final List<Animal> animals;

  const ChatInterface({super.key, required this.animals});

  @override
  ConsumerState<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends ConsumerState<ChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isError = false;
  String? _errorMessage;
  static const int _conversationTokenLimit = 5000; // Per-conversation token limit
  int _conversationTokensUsed = 0;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    if (widget.animals.isNotEmpty) {
      final species = widget.animals.first.species;
      _messages.add(ChatMessage(
        text: 'Hello! I can help you learn about our ${species}s. How can I assist you today?',
        isUser: false,
      ));
    } else {
      _messages.add(ChatMessage(
        text: 'Hello! How can I assist you today?',
        isUser: false,
      ));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
      ));
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    _scrollToBottom();

    try {
      // Check if we've reached the conversation limit
      if (_conversationTokensUsed >= _conversationTokenLimit) {
        throw Exception('Conversation limit reached. Please start a new conversation.');
      }

      final response = await ref.read(chatServiceProvider).sendMessage(
            message,
            widget.animals,
          );

      // Update conversation token usage (rough estimate)
      final estimatedTokens = response.length ~/ 4;
      _conversationTokensUsed += estimatedTokens;

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isError = true;
        _isLoading = false;
        _messages.add(ChatMessage(
          text: 'Error: $_errorMessage',
          isUser: false,
          isError: true,
        ));
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isError && _errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.red[100],
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _isError = false;
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_conversationTokensUsed >= _conversationTokenLimit)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.orange[100],
              child: const Text(
                'Conversation limit reached. Please start a new conversation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading && _conversationTokensUsed < _conversationTokenLimit,
                    onSubmitted: (_) => _isLoading || _conversationTokensUsed >= _conversationTokenLimit ? null : _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  onPressed: _isLoading || _conversationTokensUsed >= _conversationTokenLimit
                      ? null
                      : _sendMessage,
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isError ? Colors.red : Colors.black,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
} 