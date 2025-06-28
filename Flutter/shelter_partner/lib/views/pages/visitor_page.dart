import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/visitors_view_model.dart';
import 'package:shelter_partner/views/components/chat_interface.dart';
import 'dart:async';
import 'dart:core';
import 'package:cached_network_image/cached_network_image.dart';
// Conditional import for platform-specific full-screen functionality
import 'package:shelter_partner/helper/fullscreen_stub.dart'
    if (dart.library.html) 'package:shelter_partner/helper/fullscreen_web.dart'
    if (dart.library.io) 'package:shelter_partner/helper/fullscreen_mobile.dart';

class VisitorPage extends ConsumerStatefulWidget {
  const VisitorPage({super.key});

  @override
  ConsumerState<VisitorPage> createState() => _VisitorPageState();
}

class _VisitorPageState extends ConsumerState<VisitorPage>
    with SingleTickerProviderStateMixin {
  final int preloadImageCount = 150; // Reduced preload count
  late ScrollController _scrollController;

  Timer? _throttleTimer;
  final Duration throttleDuration = const Duration(milliseconds: 200);

  final double maxItemExtent = 250;

  // TabController for the TabBar
  late TabController _tabController;

  // Selected animal type ('cats' or 'dogs')
  String selectedAnimalType = 'cats';

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.imageCache.maximumSize =
        1000; // Increased cache size
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        100 * 1024 * 1024; // 100 MB

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        selectedAnimalType = _tabController.index == 0 ? 'cats' : 'dogs';
        // Reset scroll position
        _scrollController.jumpTo(0);
      });
    }
  }

  void _onScroll() {
    // Note: Preloading moved to build method since serviceUrls access is needed
  }

  void _preloadImages(String animalType, serviceUrls) {
    if (!mounted) return;

    final animalsMap = ref.read(visitorsViewModelProvider);
    final animals = animalsMap[animalType] ?? [];

    if (animals.isEmpty) return;

    // Preload a subset of images to avoid excessive memory usage
    const start = 0;
    final end = (preloadImageCount < animals.length)
        ? preloadImageCount
        : animals.length;

    for (int i = start; i < end; i++) {
      final animal = animals[i];
      final originalUrl = (animal.photos != null && animal.photos!.isNotEmpty)
          ? animal.photos!.first.url
          : '';

      final formattedUrl = serviceUrls.corsImageUrl(originalUrl);
      if (formattedUrl.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(formattedUrl), context);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _throttleTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceUrls = ref.watch(serviceUrlsProvider);
    final animalsMap = ref.watch(visitorsViewModelProvider);
    final dogs = animalsMap['dogs'] ?? [];
    final cats = animalsMap['cats'] ?? [];

    // Preload images when animals are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cats.isNotEmpty) _preloadImages('cats', serviceUrls);
      if (dogs.isNotEmpty) _preloadImages('dogs', serviceUrls);
    });

    // Determine which tabs to show based on available animals
    final List<Tab> tabs = [];
    final List<Widget> tabViews = [];

    if (dogs.isNotEmpty) {
      tabs.add(const Tab(text: 'Dogs'));
      tabViews.add(_buildAnimalGrid(dogs, serviceUrls));
    }

    if (cats.isNotEmpty) {
      tabs.add(const Tab(text: 'Cats'));
      tabViews.add(_buildAnimalGrid(cats, serviceUrls));
    }

    // If no animals are available, show a message
    if (tabs.isEmpty) {
      return const Scaffold(body: Center(child: Text('No animals available')));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (tabs.length > 1)
                TabBar(controller: _tabController, tabs: tabs),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: tabViews,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final currentAnimals = _tabController.index == 0 ? dogs : cats;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatInterface(animals: currentAnimals),
              ),
            );
          },
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }

  Widget _buildAnimalGrid(List<Animal> animals, serviceUrls) {
    if (animals.isEmpty) {
      return const Center(
        child: Icon(Icons.pets, size: 50, color: Colors.grey),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxItemExtent,
            childAspectRatio: 1.0,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final animal = animals[index];
            final originalUrl =
                (animal.photos != null && animal.photos!.isNotEmpty)
                ? animal.photos!.first.url
                : '';
            final displayUrl = serviceUrls.corsImageUrl(originalUrl);

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {},
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25.0),
                      child: GestureDetector(
                        onTap: () {
                          context.push('/visitors/details', extra: animal);
                        },
                        child: Container(
                          color: Colors.grey[300],
                          child: Stack(
                            children: [
                              displayUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: displayUrl,
                                      cacheKey: originalUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: Icon(
                                              Icons.pets,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Center(
                                            child: Icon(
                                              Icons.pets,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.pets,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    animal.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }, childCount: animals.length),
        ),
        // "Start Slideshow" button at the end of the scroll view
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: animals.isNotEmpty
                    ? () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                SlideshowScreen(animals: animals, ref: ref),
                          ),
                        );
                      }
                    : null,
                child: const Text('Start Slideshow'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SlideshowScreen extends StatefulWidget {
  final List<Animal> animals;
  final WidgetRef ref;
  const SlideshowScreen({super.key, required this.animals, required this.ref});

  @override
  _SlideshowScreenState createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  int _currentIndex = 0;
  int _currentPhotoIndex = 0;
  late Timer _timer;
  late List<Animal> _shuffledAnimals;
  String _currentImageUrl = '';
  Animal? _currentAnimal;

  @override
  void initState() {
    super.initState();

    // Shuffle the list of animals
    _shuffledAnimals = List.from(widget.animals)..shuffle();

    // Get serviceUrls from ref
    final serviceUrls = widget.ref.read(serviceUrlsProvider);

    // Set the initial image URL and animal, ensuring it skips animals without images
    _currentIndex = 0;
    _currentPhotoIndex = 0;
    do {
      _setCurrentImage(serviceUrls);
      if (_currentImageUrl.isEmpty) {
        _currentIndex = (_currentIndex + 1) % _shuffledAnimals.length;
      }
    } while (_currentImageUrl.isEmpty && _currentIndex != 0);

    // Start the slideshow
    _startSlideshow();

    // Enter full-screen mode if appropriate
    enterFullScreen();
  }

  void _setCurrentImage(serviceUrls) {
    final animal = _shuffledAnimals[_currentIndex];
    _currentAnimal = animal; // Set the current animal
    if (animal.photos != null && animal.photos!.isNotEmpty) {
      if (_currentPhotoIndex >= animal.photos!.length) {
        _currentPhotoIndex = 0;
      }
      _currentImageUrl = serviceUrls.corsImageUrl(
        animal.photos![_currentPhotoIndex].url,
      );
    } else {
      _currentImageUrl = '';
    }
  }

  void _startSlideshow() {
    if (_shuffledAnimals.every(
      (animal) => animal.photos == null || animal.photos!.isEmpty,
    )) {
      // No valid slides available
      _currentImageUrl = '';
      return;
    }
    // Get the slideshow timer setting from account settings
    final accountSettings = widget.ref
        .read(accountSettingsViewModelProvider)
        .value
        ?.accountSettings;
    final slideshowTimer = accountSettings?.slideshowTimer ?? 10;

    // Start the timer to change images based on the slideshow timer setting
    _timer = Timer.periodic(Duration(seconds: slideshowTimer), (timer) {
      setState(() {
        final photos = _currentAnimal?.photos;

        if (photos != null && _currentPhotoIndex + 1 < photos.length) {
          // Move to next photo of current animal
          _currentPhotoIndex++;
        } else {
          // Move to next animal that has photos
          int attempts = 0;
          do {
            _currentIndex = (_currentIndex + 1) % _shuffledAnimals.length;
            _currentPhotoIndex = 0;
            _setCurrentImage(widget.ref.read(serviceUrlsProvider));
            attempts++;
          } while (_currentImageUrl.isEmpty &&
              attempts < _shuffledAnimals.length);
          return;
        }

        _setCurrentImage(widget.ref.read(serviceUrlsProvider));
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    exitFullScreen(); // Exit full-screen mode when the slideshow is dismissed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the slideshow size setting from account settings
    final accountSettings = widget.ref
        .watch(accountSettingsViewModelProvider)
        .value
        ?.accountSettings;

    // Determine the BoxFit based on the slideshow size setting
    BoxFit boxFit;
    switch (accountSettings?.slideshowSize) {
      case 'Scaled to Fit':
        boxFit = BoxFit.contain;
        break;
      case 'Scaled to Fill':
        boxFit = BoxFit.cover;
        break;
      case 'Cropped to Square':
        boxFit = BoxFit.cover;
        break;
      default:
        boxFit = BoxFit.cover;
    }

    // Handle the case where there is no image
    Widget imageWidget;
    if (_currentImageUrl.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        key: ValueKey<String>(_currentImageUrl),
        imageUrl: _currentImageUrl,
        fit: boxFit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Center(child: Icon(Icons.pets, color: Colors.grey, size: 50)),
      );
    } else {
      imageWidget = const Center(
        child: Icon(Icons.pets, size: 50, color: Colors.grey),
      );
    }

    // Wrap imageWidget in a Stack to overlay the name
    Widget content = Stack(
      key: ValueKey<String>(_currentImageUrl),
      children: [
        if (accountSettings?.slideshowSize == 'Cropped to Square')
          Container(
            color: Colors.black,
            child: Center(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: AspectRatio(aspectRatio: 1.0, child: imageWidget),
                ),
              ),
            ),
          )
        else
          imageWidget,
        Positioned(
          bottom: 50.0,
          left: 0,
          right: 0,
          child: Text(
            _currentAnimal?.name ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 50,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 3.0,
                  color: Colors.black,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Dismiss the slideshow
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedSwitcher(
          duration: const Duration(seconds: 2),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: content,
        ),
      ),
    );
  }
}
