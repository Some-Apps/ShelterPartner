// animal_card_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shelter_partner/view_models/animal_card_view_model.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';

class AnimalCardView extends ConsumerStatefulWidget {
  final Animal animal;

  const AnimalCardView({Key? key, required this.animal}) : super(key: key);

  @override
  _AnimalCardViewState createState() => _AnimalCardViewState();
}

class _AnimalCardViewState extends ConsumerState<AnimalCardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2 seconds duration
    );

    // Non-linear progress curve: slow at first, speeding up later
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Listen for animation completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset the animation instantly
        _controller.reset();
        
        // Animation completed, show confirmation dialog
        _showConfirmationDialog();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getScaledDownUrl(String url) {
    final parts = url.split('.');
    if (parts.length > 1) {
      parts[parts.length - 2] += '_100x100';
    }
    return parts.join('.');
  }

  Future<void> _showConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Action'),
          content: Text(
              'Do you want to ${widget.animal.inKennel ? 'take ${widget.animal.name} out of the kennel' : 'put ${widget.animal.name} back in the kennel'}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // User confirmed, call toggleInKennel
        await ref
            .read(animalCardViewModelProvider(widget.animal).notifier)
            .toggleInKennel();
      } catch (e) {
        // Show an error dialog
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss error dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }

    // No need to reset the controller here
  }

  @override
  Widget build(BuildContext context) {
    final animal = ref.watch(animalCardViewModelProvider(widget.animal));
    final shelterDetailsAsync = ref.watch(shelterDetailsViewModelProvider);

    // Determine if shelterID is available
    bool canInteract = false;
    shelterDetailsAsync.when(
      data: (shelter) {
        if (shelter != null && shelter.id.isNotEmpty) {
          canInteract = true;
        }
      },
      loading: () {
        canInteract = false;
      },
      error: (error, stack) {
        canInteract = false;
      },
    );

    return GestureDetector(
      onLongPressStart: canInteract
          ? (_) {
              _controller.forward();
            }
          : null,
      onLongPressEnd: canInteract
          ? (_) {
              _controller.reverse(); // Reverse animation when user lets go
            }
          : null,
      onLongPressCancel: canInteract
          ? () {
              _controller.reverse();
            }
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: animal.inKennel
                ? Colors.lightBlue.shade100
                : Colors.orange.shade100,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animal details: name and location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              animal.location,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Stroke animation with curved, non-linear progression
                      AnimatedBuilder(
                        animation: _curvedAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 110,
                            height: 110,
                            child: CircularProgressIndicator(
                              value: _curvedAnimation.value,
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                animal.inKennel
                                    ? Colors.orange
                                    : Colors.lightBlue,
                              ),
                            ),
                          );
                        },
                      ),
                      // Image inside the stroke
                      ClipOval(
                        child: animal.photos.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl:
                                    getScaledDownUrl(animal.photos.first.url),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              )
                            : const SizedBox(
                                width: 100,
                                height: 100,
                                child: Icon(Icons.pets, size: 50),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Optional: Disabled overlay if cannot interact
          if (!canInteract)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
