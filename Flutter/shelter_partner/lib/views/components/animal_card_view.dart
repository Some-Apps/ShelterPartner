import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/animal_card_repository.dart';
import 'package:shelter_partner/view_models/animal_card_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/take_out_confirmation_view_model.dart';
import 'package:shelter_partner/views/components/add_log_view.dart';
import 'package:shelter_partner/views/components/add_note_view.dart';
import 'package:shelter_partner/views/components/animal_card_image.dart';
import 'package:shelter_partner/views/components/put_back_confirmation_view.dart';
import 'package:shelter_partner/views/components/take_out_confirmation_view.dart';
import 'package:uuid/uuid.dart';

/// Helper method to calculate time ago from a given DateTime.
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

class AnimalCardView extends ConsumerStatefulWidget {
  final Animal animal;
  final int maxLocationTiers;

  const AnimalCardView(
      {super.key, required this.animal, required this.maxLocationTiers});

  @override
  _AnimalCardViewState createState() => _AnimalCardViewState();
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

    // Print the account type on appear.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appUser = ref.read(appUserProvider);
      print("Account type on appear: ${appUser?.type}");
    });

    // Handle automatic put back after the first frame.
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
      duration: const Duration(seconds: 2),
    );

    // Use a non-linear curve (easeIn) for a gradual start.
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Listen for animation completion.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        print("DEBUG: AnimationStatus completed triggered");
        _controller.reset();
        final currentAnimal = widget.animal;
        print("DEBUG: currentAnimal.inKennel: ${currentAnimal.inKennel}");
        if (currentAnimal.inKennel) {
          final accountDetails =
              ref.read(accountSettingsViewModelProvider).value;
          print("DEBUG: accountDetails: $accountDetails");
          if (accountDetails != null) {
            final appUser = ref.read(appUserProvider);
            print("DEBUG: appUser: $appUser");
            final shelterSettings =
                ref.read(shelterDetailsViewModelProvider).value;
            print("DEBUG: shelterSettings: $shelterSettings");
            bool requireName;
            bool requireLetOutType;
            if (appUser?.type == "admin") {
              requireName = accountDetails.accountSettings!.requireName;
              requireLetOutType =
                  accountDetails.accountSettings!.requireLetOutType;
              print(
                  "DEBUG: Admin account - requireName: $requireName, requireLetOutType: $requireLetOutType");
            } else {
              requireName = shelterSettings!.volunteerSettings.requireName;
              requireLetOutType =
                  shelterSettings.volunteerSettings.requireLetOutType;
              print(
                  "DEBUG: Volunteer account - requireName: $requireName, requireLetOutType: $requireLetOutType");
            }
            if (requireName || requireLetOutType) {
              print("DEBUG: Showing take out confirmation dialog");
              _showTakeOutConfirmationDialog();
            } else {
              print("DEBUG: Directly taking out animal");
              ref
                  .read(takeOutConfirmationViewModelProvider(widget.animal)
                      .notifier)
                  .takeOutAnimal(
                    widget.animal,
                    Log(
                      id: const Uuid().v4().toString(),
                      type: '',
                      author: '',
                      authorID: '',
                      earlyReason: '',
                      startTime: Timestamp.now(),
                      endTime: widget.animal.logs.last.endTime,
                    ),
                  );
            }
          } else {
            print("DEBUG: accountDetails is null");
          }
        } else {
          print(
              "DEBUG: Animal not in kennel, showing put back confirmation dialog");
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

  Future<void> _showTakeOutConfirmationDialog() async {
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
      color:
          animal.inKennel ? Colors.lightBlue.shade100 : Colors.orange.shade100,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      shadowColor: Colors.black,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image and details.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animal image with tap interactions.
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
                  child: AnimalCardImage(
                    curvedAnimation: _curvedAnimation,
                    isPressed: isPressed,
                    animal: animal,
                  ),
                ),
                const SizedBox(width: 10),
                // Animal details.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row with name and icons.
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                animal.name,
                                style: const TextStyle(
                                  fontFamily: 'CabinBold',
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          // Wrap the icon and menu button in a Row that takes only its natural size.
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildIcon(animal.symbol, animal.symbolColor),
                              PopupMenuButton<String>(
                                offset: const Offset(0, 40),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'Details':
                                      context.push('/enrichment/details',
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
                                            AddLogView(animal: animal),
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  final appUser = ref.read(appUserProvider);
                                  final accountSettings = ref
                                      .read(accountSettingsViewModelProvider)
                                      .value;
                                  final menuItems = {'Details', 'Add Note'};
                                  if (appUser?.type == "admin" &&
                                      accountSettings!.accountSettings?.mode ==
                                          "Admin" &&
                                      animal.inKennel) {
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
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Info chips wrapped in a Wrap.
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (animal.location.isNotEmpty &&
                              animal.locationTiers.isEmpty)
                            _buildInfoChip(
                              icon: Icons.location_on,
                              label: animal.location,
                            ),
                          if (animal.locationTiers.isNotEmpty)
                            for (var tier in animal.locationTiers.sublist(
                              animal.locationTiers.length > widget.maxLocationTiers
                                  ? animal.locationTiers.length -
                                      widget.maxLocationTiers
                                  : 0, // Clamp to 0 if not enough tiers
                            ))
                              _buildInfoChip(
                                icon: Icons.location_on,
                                label: tier,
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
                          // Add the top 3 tags as info chips.
                          for (var tag in (animal.tags
                                ..sort((a, b) => b.count.compareTo(a.count)))
                              .take(3))
                            _buildInfoChip(
                              icon: Icons.label,
                              label: tag.title,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Bottom row: Time and author information.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (animal.logs.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            "${_timeAgo(
                              widget.animal.inKennel
                                  ? animal.logs.last.endTime.toDate()
                                  : animal.logs.last.startTime.toDate(),
                              widget.animal.inKennel,
                            )}${animal.logs.last.type.isNotEmpty ? ' (${animal.logs.last.type})' : ''}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    if (animal.logs.isNotEmpty &&
                        animal.logs.last.author.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.person_2_outlined,
                              size: 16, color: Colors.grey.shade600),
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

/// Builds an info chip that scales its text down if needed.
/// If the [label] is "Unknown" (ignoring case and whitespace), nothing is rendered.
Widget _buildInfoChip({
  required IconData icon,
  required String label,
  double textSize = 10.0,
}) {
  if (label.trim().toLowerCase() == 'unknown') {
    return const SizedBox.shrink();
  }
  return ConstrainedBox(
    // Constrain the chip’s max width to prevent unbounded growth.
    constraints: const BoxConstraints(maxWidth: 250),
    child: Container(
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
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(color: Colors.black, fontSize: textSize),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildIcon(String symbol, String symbolColor) {
  IconData? iconData;

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
      return const SizedBox.shrink(); // No icon for default case
  }

  return DecoratedIcon(
    icon: Icon(
      iconData,
      color: _parseColor(symbolColor),
      size: 24, // Original size
    ),
    // decoration: const IconDecoration(
    //   border: IconBorder(
    //     color: Colors.black,
    //     width: 0.75,
    //   )
    // ),
  );
}

/// Parses a color string into a [Color] value.
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
      return Colors.transparent;
  }
}
