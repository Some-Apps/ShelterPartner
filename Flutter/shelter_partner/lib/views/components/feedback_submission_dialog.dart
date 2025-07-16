import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelter_partner/repositories/github_repository.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FeedbackSubmissionDialog extends ConsumerStatefulWidget {
  const FeedbackSubmissionDialog({super.key});

  @override
  FeedbackSubmissionDialogState createState() => FeedbackSubmissionDialogState();
}

class FeedbackSubmissionDialogState extends ConsumerState<FeedbackSubmissionDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GitHubRepository _githubRepository = GitHubRepository();
  
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final logger = ref.read(loggerServiceProvider);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e, s) {
      logger.error('Error picking image', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitFeedback() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and description')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final logger = ref.read(loggerServiceProvider);
    
    try {
      String body = _descriptionController.text.trim();
      
      // Add screenshot info if image is selected
      if (_selectedImage != null) {
        body += '\n\n---\n**Note:** User attempted to include a screenshot with this feedback.';
      }
      
      // Add submission info
      body += '\n\n---\n*Submitted from ShelterPartner app*';

      final response = await _githubRepository.createIssue(
        title: _titleController.text.trim(),
        body: body,
        labels: ['user feedback'],
      );

      if (!mounted) return;

      // Show success message with link
      Navigator.of(context).pop();
      
      // Show toast with success message
      Fluttertoast.showToast(
        msg: "Feedback submitted successfully!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );

      // Show dialog with link to the issue
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Feedback Submitted'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your feedback has been submitted successfully!'),
              const SizedBox(height: 16),
              Text('Issue #${response.number}: ${response.title}'),
              const SizedBox(height: 16),
              const Text('You can track the progress of your feedback using the link below:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (await canLaunchUrl(Uri.parse(response.htmlUrl))) {
                  await launchUrl(Uri.parse(response.htmlUrl));
                }
              },
              child: const Text('View on GitHub'),
            ),
          ],
        ),
      );

    } catch (e, s) {
      logger.error('Error submitting feedback', e, s);
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Feedback'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Brief description of your feedback',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed description of your feedback, bug report, or feature request',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    FutureBuilder<Uint8List>(
                      future: _selectedImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            );
                          } else {
                            return const Icon(Icons.error);
                          }
                        } else {
                          return const SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Screenshot selected')),
                    IconButton(
                      onPressed: _isSubmitting ? null : _removeImage,
                      icon: const Icon(Icons.remove_circle),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Screenshot (Optional)'),
              ),
            if (_isSubmitting) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Submitting feedback...'),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}