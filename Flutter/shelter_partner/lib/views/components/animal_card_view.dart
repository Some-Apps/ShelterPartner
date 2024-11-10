
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/animal_card_repository.dart';
import 'package:shelter_partner/view_models/animal_card_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/take_out_confirmation_view_model.dart';
import 'package:shelter_partner/views/components/add_log_view.dart';
import 'package:shelter_partner/views/components/add_note_view.dart';
import 'package:shelter_partner/views/components/put_back_confirmation_view.dart';
import 'package:shelter_partner/views/components/take_out_confirmation_view.dart';
import 'package:uuid/uuid.dart';

class AnimalCardView extends ConsumerStatefulWidget {
  final Animal animal;

  const AnimalCardView({super.key, required this.animal});

  @override
  _AnimalCardViewState createState() => _AnimalCardViewState();
}

/// Helper method to calculate time ago from a given DateTime
String _timeAgo(DateTime dateTime, bool inKennel) {
  final Duration difference = DateTime.now().difference(dateTime);

  if (difference.inDays > 8) {
    return '${(difference.inDays / 7).floor()} weeks${inKennel ? ' ago' : ''}';
  } else if (difference.inDays >= 1) {
    return '${difference.inDays} days${inKennel ? ' ago' : ''}';
  } else if (difference.inHours >= 1) {
    return '${difference.inHours} hours${inKennel ? ' ago' : ''}';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes} minutes${inKennel ? ' ago' : ''}';
  } else {
    return inKennel ? 'Just now' : '0 minutes';
  }
}

class _AnimalCardViewState extends ConsumerState<AnimalCardView>
    with TickerProviderStateMixin {
  bool _automaticPutBackHandled = false;

  late AnimationController _controller;
  late Animation<double> _curvedAnimation;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_automaticPutBackHandled) {
        final shelterDetails = ref.read(shelterDetailsViewModelProvider).value;

        if (shelterDetails != null) {
          final shelterSettings = shelterDetails.shelterSettings;
          final shelterId = shelterDetails.id;
          final animalType = widget.animal.species;

          final viewModel = AnimalCardViewModel(
            repository: AnimalRepository(),
            shelterId: shelterId,
            animalType: animalType,
            shelterSettings: shelterSettings,
          );

          viewModel.handleAutomaticPutBack(widget.animal);
        }
        _automaticPutBackHandled = true;
      }
    });

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
        final currentAnimal = widget.animal;

        // Animation completed, show confirmation dialog
        if (currentAnimal.inKennel) {
          final deviceDetails = ref.read(deviceSettingsViewModelProvider).value;
          if (deviceDetails != null &&
              (deviceDetails.deviceSettings!.requireName ||
                  deviceDetails.deviceSettings!.requireLetOutType)) {
            _showTakeOutConfirmationDialog();
          } else {
            ref
                .read(takeOutConfirmationViewModelProvider(widget.animal)
                    .notifier)
                .takeOutAnimal(
                    widget.animal,
                    Log(
                      id: const Uuid().v4().toString(),
                      type: '',
                      author: '',
                      earlyReason: '',
                      startTime: Timestamp.now(),
                      endTime: widget.animal.logs.last.endTime,
                    ));
          }
        } else {
          _showPutBackConfirmationDialog();
        }
      }
    });

    // Preload images
    _preloadImages();
  }

  void _preloadImages() {
    if (widget.animal.photos?.isNotEmpty ?? false) {
      for (var photo in widget.animal.photos!) {
        precacheImage(NetworkImage(photo.url), context);
      }
    }
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

  Future<void> _showTakeOutConfirmationDialog() async {
    // Show the custom confirmation widget using the ref object
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return TakeOutConfirmationView(
          animals: [widget.animal],
        );
      },
    );
  }

  Future<void> showErrorDialog(
      {required BuildContext context, required String message}) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPutBackConfirmationDialog() async {
    // Show the custom confirmation dialog using the helper
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return PutBackConfirmationView(
          animals: [widget.animal],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
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

    return Card(
      color: animal.inKennel
        ? Colors.lightBlue.shade100
        : Colors.orange.shade100,
      elevation: 1,
      shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
      // side: BorderSide(color: Colors.white, width: 0.25),
      ),
      shadowColor: Colors.black, // Customize shadow color
      child: Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Top Row: Image and details
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Animal image and interaction
          GestureDetector(
            onTapDown: canInteract
              ? (_) {
                setState(() {
                isPressed = true;
                });
                _controller.forward();
                HapticFeedback.mediumImpact();
              }
              : null,
            onTapUp: canInteract
              ? (_) {
                setState(() {
                isPressed = false;
                });
                _controller.reverse();
                HapticFeedback.lightImpact();
              }
              : null,
            onTapCancel: canInteract
              ? () {
                setState(() {
                isPressed = false;
                });
                _controller.reverse();
                HapticFeedback.lightImpact();
              }
              : null,
            child: Stack(
            alignment: Alignment.center,
            children: [
              // Background stroke (semi-transparent)
              CircleAvatar(
              radius: 65,
              backgroundColor: Colors.black.withOpacity(0.2),
              ),

              // Circular progress animation
              AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return SizedBox(
                width: 115,
                height: 115,
                child: CircularProgressIndicator(
                  value: _curvedAnimation.value,
                  strokeWidth: 15,
                  valueColor: AlwaysStoppedAnimation<Color>(
                  animal.inKennel
                    ? Colors.orange.shade100
                    : Colors.lightBlue.shade100,
                  ),
                ),
                );
              },
              ),

              // Image with shadow and scale effect
              AnimatedScale(
              scale: isPressed ? 1.0 : 1.025,
              duration: const Duration(milliseconds: 0),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 0.9,
                  spreadRadius: 0,
                  offset: isPressed
                    ? const Offset(0, 0)
                    : const Offset(1, 1.5),
                  ),
                ],
                ),
                child: ClipOval(
                child: (animal.photos?.isNotEmpty ?? false)
                  ? CachedNetworkImage(
                    imageUrl: animal.photos?.first.url ?? '',
                      // imageUrl: getScaledDownUrl(
                      //   animal.photos?.first.url ?? ''),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                        Icon(
                          Icons.pets,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                      errorWidget: (context, url, error) =>
                        Icon(Icons.pets, size: 50, color: Colors.grey.shade400),
                    )
                  : Icon(
                      Icons.pets,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                ),
              ),
              ),
            ],
            ),
          ),
          const SizedBox(width: 10),
          // Animal details
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name, symbol, and menu
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                children: [
                  Text(
                  animal.name,
                  style: const TextStyle(
                    fontSize: 25.0,
                    // fontWeight: FontWeight.bold,
                  ),
                  ),
                  const SizedBox(width: 5),
                  if (animal.symbol.isNotEmpty)
                  _buildIcon(animal.symbol, animal.symbolColor),
                ],
                ),
                PopupMenuButton<String>(
                offset: const Offset(0, 40),
                onSelected: (value) {
                  // Handle menu item selection
                  switch (value) {
                  case 'Details':
                    context.push('/animals/details',
                      extra: animal);
                    break;
                  case 'Add Note':
                    showDialog(
                    context: context,
                    builder: (context) =>
                      AddNoteView(animal: animal),
                    );
                    break;
                  case 'Add Log':
                    showDialog(
                      context: context,
                      builder: (context) =>
                        AddLogView(animal: animal));
                    break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  final appUser = ref.read(appUserProvider);
                  final deviceSettings = ref
                    .read(deviceSettingsViewModelProvider)
                    .value;

                  final menuItems = {'Details', 'Add Note'};
                  if (appUser?.type == "admin" &&
                    deviceSettings!.deviceSettings?.mode ==
                      "Admin" && animal.inKennel) {
                  menuItems.add('Add Log');
                  }

                  return menuItems.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                  }).toList();
                },
                icon: const Icon(Icons.more_vert),
                ),
              ],
              ),
              const SizedBox(height: 5),
              // Info chips
              Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (animal.location.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.location_on,
                  label: animal.location,
                ),
                if (animal.adoptionCategory.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.shopping_bag,
                  label: animal.adoptionCategory,
                ),
                if (animal.behaviorCategory.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.face,
                  label: animal.behaviorCategory,
                ),
                if (animal.locationCategory.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.location_city,
                  label: animal.locationCategory,
                ),
                if (animal.medicalCategory.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.health_and_safety,
                  label: animal.medicalCategory,
                ),
                if (animal.volunteerCategory.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.volunteer_activism,
                  label: animal.volunteerCategory,
                ),
                // Add the top 3 tags as info chips
                for (int i = 0; i < min(3, animal.tags?.length ?? 0); i++)
                _buildInfoChip(
                  icon: Icons.label,
                  label: animal.tags?[i].title ?? '',
                ),
              ],
              ),
            ],
            ),
          ),
          ],
        ),
        const Spacer(),
        // Spacer(),
        // Author and timeago at the bottom center
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            if (animal.logs.isNotEmpty)
              Row(
              children: [
          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
          "${_timeAgo(widget.animal.inKennel ? animal.logs.last.endTime.toDate() : animal.logs.last.startTime.toDate(), widget.animal.inKennel)}${animal.logs.last.type.isNotEmpty ? ' (${animal.logs.last.type})' : ''}",
          style: TextStyle(color: Colors.grey.shade600),
          ),
              ],
              ),
            if (animal.logs.isNotEmpty &&
              animal.logs.last.author.isNotEmpty)
              Row(
              children: [
          Icon(Icons.person_2_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            animal.logs.last.author,
            style: TextStyle(color: Colors.grey.shade600),
          ),
              ],
              ),
            ],
          ),
          ),
        ),
        ],
      ),
      ),
    );
  }
}

Widget _buildInfoChip({
  required IconData icon,
  required String label,
  double textSize = 10.0,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.black, fontSize: textSize),
        ),
      ],
    ),
  );
}

Icon _buildIcon(String symbol, String symbolColor) {
  IconData iconData;

  switch (symbol) {
    case 'pets':
      iconData = Icons.pets;
      break;
    case 'location_on':
      iconData = Icons.location_on;
      break;
    case 'star':
      iconData = Icons.star;
      break;
    default:
      iconData = Icons.help_outline;
  }

  return Icon(
    iconData,
    color: _parseColor(symbolColor),
    shadows: [
      Shadow(
        blurRadius: 1.0,
        color: Colors.black.withOpacity(0.7),
        offset: const Offset(0.35, 0.35),
      ),
    ],
  );
}

// Color _parseColor(String colorString) {
//   colorString = colorString.replaceAll('#', '');

//   if (colorString.length == 6) {
//     colorString = 'FF$colorString';
//   }

//   return Color(int.parse(colorString, radix: 16));
// }
Color _parseColor(String colorString) {
  switch (colorString.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    case 'grey':
      return Colors.grey;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    default:
      return Colors.transparent; // Default case if color is not recognized
  }
}
