import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/edit_animal_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/view_models/edit_animal_view_model.dart';
import 'package:intl/intl.dart';

class AnimalsAnimalDetailPage extends StatelessWidget {
  final Animal initialAnimal;

  const AnimalsAnimalDetailPage({super.key, required this.initialAnimal});

  @override
  Widget build(BuildContext context) {
    final animalProvider = StateNotifierProvider.family<EditAnimalViewModel, Animal, Animal>(
      (ref, animal) => EditAnimalViewModel(ref.read(editAnimalRepositoryProvider), ref, animal),
    );

    return Consumer(
      builder: (context, ref, child) {
        final appUser = ref.read(appUserProvider);
        final deviceSettings = ref.watch(deviceSettingsViewModelProvider);
        final animal = ref.watch(animalProvider(initialAnimal));

        // Helper method to format the intake date
        String getFormattedDate(Timestamp? timestamp) {
          if (timestamp == null) return 'Unknown';
          final date = timestamp.toDate();
          return '${date.day}/${date.month}/${date.year}';
        }

        void showFullScreenImage(BuildContext context, String imageUrl) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                body: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Image.network(imageUrl),
                  ),
                ),
              ),
            ),
          );
        }

        bool isAdmin() {
          // Replace with actual logic to check if the user is an admin
          return appUser?.type == "admin" &&
              deviceSettings.value!.deviceSettings?.mode == "Admin";
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(animal.name), // Display the animal's name at the top
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photos in a horizontal scrollable slideshow view
                  SizedBox(
                    height: 200.0, // Adjust the height as needed
                    child: animal.photos.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: animal.photos.length,
                            itemBuilder: (context, index) {
                              final photo = animal.photos[index];
                              final scaledUrl = photo.url.replaceFirst('.jpeg',
                                  '_250x250.jpeg'); // Assuming the image format is always .jpeg
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          showFullScreenImage(context, photo.url),
                                      child: Image.network(
                                        scaledUrl, // Use the scaled down version of the image
                                        fit: BoxFit.cover,
                                        loadingBuilder: (BuildContext context,
                                            Widget child,
                                            ImageChunkEvent? loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          } else {
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        (loadingProgress
                                                                .expectedTotalBytes ??
                                                            1)
                                                    : null,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    if (isAdmin())
                                      Positioned(
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            // Show confirmation dialog
                                            final shouldDelete = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Confirm Delete'),
                                                content: const Text(
                                                    'Are you sure you want to delete this photo?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(false), // Do not delete
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true), // Proceed to delete
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
            
                                            if (shouldDelete == true) {
                                              ref
                                                  .read(animalProvider(initialAnimal)
                                                      .notifier)
                                                  .deleteItemOptimistically(
                                                    appUser!.shelterId,
                                                    animal.species,
                                                    animal.id,
                                                    'photos',
                                                    photo.id,
                                                  );
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No photos available'),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16.0),
            
                  // Animal details section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Name'),
                    subtitle: Text(animal.name),
                  ),
                  ListTile(
                    title: const Text('Sex'),
                    subtitle: Text(animal.sex),
                  ),
                  ListTile(
                    title: const Text('Species'),
                    subtitle: Text(animal.species),
                  ),
                  ListTile(
                    title: const Text('Breed'),
                    subtitle: Text(animal.breed),
                  ),
                  ListTile(
                    title: const Text('Description'),
                    subtitle: Text(animal.description),
                  ),
                  ListTile(
                    title: const Text('Intake Date'),
                    subtitle: Text(getFormattedDate(animal.intakeDate)),
                  ),
                  const SizedBox(height: 16.0),
            
                  // Tags section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  animal.tags.isNotEmpty
                      ? Column(
                          children: animal.tags.map((tag) {
                            return ListTile(
                              title: Text(tag.title ?? ''),
                              trailing: isAdmin()
                                  ? IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        // Show confirmation dialog
                                        final shouldDelete = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirm Delete'),
                                            content: const Text(
                                                'Are you sure you want to delete this tag?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false), // Do not delete
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true), // Proceed to delete
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
            
                                        if (shouldDelete == true) {
                                          ref
                                              .read(animalProvider(initialAnimal)
                                                  .notifier)
                                              .deleteItemOptimistically(
                                                appUser!.shelterId,
                                                animal.species,
                                                animal.id,
                                                'tags',
                                                tag.id,
                                              );
                                        }
                                      },
                                    )
                                  : null,
                            );
                          }).toList(),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No tags available'),
                        ),
            
                  // Notes section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  animal.notes.isNotEmpty
                      ? Column(
                          children: animal.notes.map((note) {
                            return ListTile(
                              title: Text(note.note ?? 'Note'),
                              trailing: isAdmin()
                                  ? IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        // Show confirmation dialog
                                        final shouldDelete = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirm Delete'),
                                            content: const Text(
                                                'Are you sure you want to delete this note?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false), // Do not delete
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true), // Proceed to delete
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
            
                                        if (shouldDelete == true) {
                                          ref
                                              .read(animalProvider(initialAnimal)
                                                  .notifier)
                                              .deleteItemOptimistically(
                                                appUser!.shelterId,
                                                animal.species,
                                                animal.id,
                                                'notes',
                                                note.id,
                                              );
                                        }
                                      },
                                    )
                                  : null,
                            );
                          }).toList(),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No notes available'),
                        ),
            
                  // Logs section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Logs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  animal.logs.isNotEmpty
                    ? Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: animal.logs.map((log) {
                        return LogChip(
                          log: log,
                          isAdmin: isAdmin(),
                          onDelete: () async {
                            // Show confirmation dialog
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text(
                                    'Are you sure you want to delete this log?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false), // Do not delete
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true), // Proceed to delete
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete == true) {
                              ref
                                  .read(animalProvider(initialAnimal).notifier)
                                  .deleteItemOptimistically(
                                    appUser!.shelterId,
                                    animal.species,
                                    animal.id,
                                    'logs',
                                    log.id,
                                  );
                            }
                          },
                        );
                      }).toList(),
                    )
                    : const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No logs available'),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LogChip extends StatelessWidget {
  final Log log;
  final bool isAdmin;
  final VoidCallback? onDelete;

  const LogChip({
    Key? key,
    required this.log,
    required this.isAdmin,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final startTime = log.startTime?.toDate();
    final endTime = log.endTime?.toDate();
    final duration = startTime != null && endTime != null
        ? endTime.difference(startTime).inMinutes
        : null;

    return Chip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (duration != null)
            Row(
              children: [
          const Icon(Icons.timer, size: 16.0),
          const SizedBox(width: 4.0),
          Text('$duration minutes'),
              ],
            ),
          Row(
            children: [
              const Icon(Icons.category, size: 16.0),
              const SizedBox(width: 4.0),
              Text(log.type),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.person, size: 16.0),
              const SizedBox(width: 4.0),
              Text(log.author),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16.0),
              const SizedBox(width: 4.0),
              Text(endTime != null ? DateFormat('MMM d').format(endTime) : ''),
            ],
          ),
        ],
      ),
      deleteIcon: isAdmin ? const Icon(Icons.delete, color: Colors.red) : null,
      onDeleted: isAdmin ? onDelete : null,
    );
  }
}
