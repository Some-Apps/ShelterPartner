import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/photo.dart';
import 'package:shelter_partner/repositories/edit_animal_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/view_models/edit_animal_view_model.dart';
import 'package:shelter_partner/views/components/logs_view.dart';
import 'package:shelter_partner/views/components/notes_view.dart';
import 'package:photo_view/photo_view.dart';

class AnimalsAnimalDetailPage extends StatelessWidget {
  final Animal initialAnimal;
  final bool visitorPage;

  const AnimalsAnimalDetailPage({super.key, required this.initialAnimal, required this.visitorPage});

  @override
  Widget build(BuildContext context) {
    final animalProvider =
        StateNotifierProvider.family<EditAnimalViewModel, Animal, Animal>(
      (ref, animal) => EditAnimalViewModel(
          ref.read(editAnimalRepositoryProvider), ref, animal),
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

        void showFullScreenGallery(
            BuildContext context, List<String> imageUrls, int initialIndex) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenGallery(
                imageUrls: imageUrls,
                initialIndex: initialIndex,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(animal.name), // Display the animal's name at the top
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inside your AnimalsAnimalDetailPage widget

// Photos in a horizontal scrollable slideshow view
                  SizedBox(
                    height: 220.0,
                    child: animal.photos.isNotEmpty
                        ? PhotoList(
                            photos: animal.photos,
                            isAdmin: isAdmin(),
                            onDelete: (photoId) {
                              ref
                                  .read(animalProvider(initialAnimal).notifier)
                                  .deleteItemOptimistically(
                                    appUser!.shelterId,
                                    animal.species,
                                    animal.id,
                                    'photos',
                                    photoId,
                                  );
                            },
                            onPhotoTap: (index) {
                              showFullScreenGallery(
                                context,
                                animal.photos
                                    .map((photo) => photo.url)
                                    .toList(),
                                index,
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      animal.description,
                      style: const TextStyle(
                        fontSize: 15.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // Animal details section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  GridView.count(
                        crossAxisCount:
                          (MediaQuery.of(context).size.width / 200).floor(),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 3,
                        children: [
                        Card(
                          child: ListTile(
                          title: const Text('Age', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                          subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                          "${animal.monthsOld} months old",
                          style: const TextStyle(color: Colors.black, fontSize: 15),
                          ),
                          ),
                          ),
                        ),
                        Card(
                          child: ListTile(
                          title: const Text('Sex', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                          subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                          animal.sex == "m" ? "Male" : "Female",
                          style: const TextStyle(color: Colors.black, fontSize: 15),
                          ),
                          ),
                          ),
                        ),
                        Card(
                          child: ListTile(
                          title: const Text('Breed', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                          subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                          animal.breed,
                          style: const TextStyle(color: Colors.black, fontSize: 15),
                          ),
                          ),
                          ),
                        ),
                      ]),
                  const SizedBox(height: 32.0),

                  // Notes section
                  NotesWidget(
                    notes: animal.notes,
                    isAdmin: isAdmin(),
                    onDelete: (String noteId) {
                      ref
                          .read(animalProvider(initialAnimal).notifier)
                          .deleteItemOptimistically(
                            appUser!.shelterId,
                            animal.species,
                            animal.id,
                            'notes',
                            noteId,
                          );
                    },
                  ),

                  
                    if (!visitorPage) ...[
                    const SizedBox(height: 32.0),

                    // Logs section
                    LogsWidget(
                      logs: animal.logs,
                      isAdmin: isAdmin(),
                      onDelete: (String logId) {
                      ref
                        .read(animalProvider(initialAnimal).notifier)
                        .deleteItemOptimistically(
                          appUser!.shelterId,
                          animal.species,
                          animal.id,
                          'logs',
                          logId,
                        );
                      },
                    ),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  _FullScreenGalleryState createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  final _focusNode = FocusNode();

  @override
  void initState() {
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousImage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextImage();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      }
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: isWeb ? _onKey : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return PhotoView(
                  imageProvider: NetworkImage(widget.imageUrls[index]),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.black),
                );
              },
            ),
            if (isWeb && widget.imageUrls.length > 1)
              Positioned(
                left: 16.0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_left,
                      color: Colors.white, size: 48.0),
                  onPressed: _previousImage,
                ),
              ),
            if (isWeb && widget.imageUrls.length > 1)
              Positioned(
                right: 16.0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_right,
                      color: Colors.white, size: 48.0),
                  onPressed: _nextImage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PhotoList extends StatefulWidget {
  final List<Photo> photos;
  final bool isAdmin;
  final Function(String photoId) onDelete;
  final Function(int index) onPhotoTap;

  const PhotoList({
    super.key,
    required this.photos,
    required this.isAdmin,
    required this.onDelete,
    required this.onPhotoTap,
  });

  @override
  _PhotoListState createState() => _PhotoListState();
}

class _PhotoListState extends State<PhotoList> {
  late ScrollController _scrollController;
  double _scrollPosition = 0.0;
  final double _itemWidth = 216.0; // 200 width + 8 padding on each side

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  void _scrollLeft() {
    _scrollPosition = _scrollController.position.pixels - _itemWidth;
    _scrollController.animateTo(
      _scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollPosition = _scrollController.position.pixels + _itemWidth;
    _scrollController.animateTo(
      _scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;
    return Stack(
      alignment: Alignment.center,
      children: [
        ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: widget.photos.length,
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            return PhotoItem(
              photo: photo,
              index: index,
              isAdmin: widget.isAdmin,
              onTap: () => widget.onPhotoTap(index),
              onDelete: () => widget.onDelete(photo.id),
            );
          },
        ),
        if (isWeb && widget.photos.length > 1)
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_left, size: 32.0),
              onPressed: _scrollLeft,
            ),
          ),
        if (isWeb && widget.photos.length > 1)
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_right, size: 32.0),
              onPressed: _scrollRight,
            ),
          ),
      ],
    );
  }
}

class PhotoItem extends StatelessWidget {
  final Photo photo;
  final int index;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PhotoItem({
    super.key,
    required this.photo,
    required this.index,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scaledUrl = photo.url.replaceFirst('.jpeg', '_250x250.jpeg');

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.network(
                    scaledUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          if (isAdmin)
            Positioned(
              top: 4.0,
              right: 4.0,
              child: IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 20.0,
                  color: Colors.red.withOpacity(1),
                ),
                onPressed: onDelete,
              ),
            ),
        ],
      ),
    );
  }
}
