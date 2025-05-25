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
      final response = await ref.read(chatServiceProvider).sendMessage(
            message,
            widget.animals,
          );

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

  Widget _buildTokenIndicator() {
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider).value;
    if (shelterSettings == null) {
      return const SizedBox.shrink();
    }

    final tokenCount = shelterSettings.shelterSettings.tokenCount;
    final tokenLimit = shelterSettings.shelterSettings.tokenLimit;
    final tokensLeft = tokenLimit - tokenCount;

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.token, size: 16),
          const SizedBox(width: 4),
          Text(
            'Tokens left: ${tokensLeft.toStringAsFixed(0)} / $tokenLimit',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: tokenCount / tokenLimit,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                tokensLeft < 100000 ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
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
          _buildTokenIndicator(),
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
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Theme.of(context).primaryColor
                          : message.isError
                              ? Colors.red[100]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : message.isError
                                ? Colors.red[900]
                                : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
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
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
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