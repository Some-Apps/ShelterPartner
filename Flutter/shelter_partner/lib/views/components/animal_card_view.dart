import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shelter_partner/view_models/animal_card_view_model.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/views/components/put_back_confirmation_view.dart';
import 'package:shelter_partner/views/components/take_out_confirmation_view.dart';

class AnimalCardView extends ConsumerStatefulWidget {
  final Animal animal;

  const AnimalCardView({super.key, required this.animal});

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

        // Retrieve the latest animal state
        final currentAnimal =
            ref.read(animalCardViewModelProvider(widget.animal));

        // Animation completed, show confirmation dialog
        if (currentAnimal.inKennel) {
          _showConfirmationDialog();
        } else {
          _showPutBackConfirmationDialog();
        }
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
    // Show the custom confirmation dialog using the helper
    final confirmed = await TakeOutConfirmationView.showConfirmationDialog(
      context: context,
      animalName: widget.animal.name,
      inKennel: widget.animal.inKennel,
    );

    if (confirmed == true) {
      try {
        // User confirmed, call toggleInKennel
        await ref
            .read(animalCardViewModelProvider(widget.animal).notifier)
            .toggleInKennel();
      } catch (e) {
        // Show an error dialog using the helper
        await TakeOutConfirmationView.showErrorDialog(
          context: context,
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _showPutBackConfirmationDialog() async {
    // Show the custom confirmation dialog using the helper
    final confirmed = await PutBackConfirmationView.showConfirmationDialog(
      context: context,
      animalName: widget.animal.name,
      inKennel: widget.animal.inKennel,
    );

    if (confirmed == true) {
      try {
        // User confirmed, call toggleInKennel
        await ref
            .read(animalCardViewModelProvider(widget.animal).notifier)
            .toggleInKennel();
      } catch (e) {
        // Show an error dialog using the helper
        await PutBackConfirmationView.showErrorDialog(
          context: context,
          message: e.toString(),
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
                  // Updated Animal details: name and information grid
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Ensures content aligns to the top
                      children: [
                        Text(
                          animal.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            height:
                                5), // Adjust spacing between name and chips
                        Wrap(
                          spacing: 4, // Horizontal space between chips
                          runSpacing: 4, // Vertical space between chips
                            children: [
                            _buildInfoChip(
                              icon: Icons.location_on,
                              label: animal.location,
                            ),
                            _buildInfoChip(
                              icon: Icons.category,
                              label: animal.adoptionCategory,
                            ),
                            _buildInfoChip(
                              icon: Icons.pets,
                              label: animal.behaviorCategory,
                            ),
                            _buildInfoChip(
                              icon: Icons.place,
                              label: animal.locationCategory,
                            ),
                            _buildInfoChip(
                              icon: Icons.health_and_safety,
                              label: animal.medicalCategory,
                            ),
                            _buildInfoChip(
                              icon: Icons.volunteer_activism,
                              label: animal.volunteerCategory,
                            ),
                          ],
                        ),
                      ],
                    ),
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

  /// Helper method to build information chips
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    double textSize = 10.0, // Default text size
  }) {
    return Chip(
      avatar: Icon(
        icon,
        size: 12,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: textSize),
      ),
      backgroundColor: Colors.grey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
