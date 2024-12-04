import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/visitors_view_model.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
// Conditional import for platform-specific full-screen functionality
import 'package:shelter_partner/helper/fullscreen_stub.dart' // Import the stub file which will import correct platform-specific file.
  if (dart.library.html) 'package:shelter_partner/helper/fullscreen_web.dart' 
  if (dart.library.io) 'package:shelter_partner/helper/fullscreen_mobile.dart';
import 'package:shelter_partner/views/pages/main_page.dart';
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

  bool _hasPreloadedImages = false; // Flag to control preloading

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.imageCache.maximumSize = 1000; // Increased cache size
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        100 * 1024 * 1024; // 100 MB

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Preload images for both 'cats' and 'dogs'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages('cats');
      _preloadImages('dogs');
      setState(() {
        _hasPreloadedImages = true;
      });
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        selectedAnimalType = _tabController.index == 0 ? 'cats' : 'dogs';
        // No need to reset _hasPreloadedImages if both tabs are preloaded
        // Optionally, you can preload again if needed
        // _preloadImages(selectedAnimalType);
        // Reset scroll position
        _scrollController.jumpTo(0);
      });
    }
  }

  void _onScroll() {
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(throttleDuration, () {
      _preloadImages(selectedAnimalType);
    });
  }

  void _preloadImages(String animalType) {
    if (!mounted) return;

    final animalsMap = ref.read(visitorsViewModelProvider);
    final animals = animalsMap[animalType] ?? [];

    if (animals.isEmpty) return;

    // Preload a subset of images to avoid excessive memory usage
    const start = 0;
    final end = (preloadImageCount < animals.length) ? preloadImageCount : animals.length;

    for (int i = start; i < end; i++) {
      final animal = animals[i];
      final imageUrl = (animal.photos != null && animal.photos!.isNotEmpty)
          ? animal.photos!.first.url ?? ''
          : '';

      if (imageUrl.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(imageUrl),
          context,
        );
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
    final animalsMap = ref.watch(visitorsViewModelProvider);
    final animals = animalsMap[selectedAnimalType] ?? [];

    // Removed on-demand preloading since we're preloading both tabs initially

    ref.listen<bool>(scrollToTopProviderVisitors, (previous, next) {
      if (next == true) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        // Reset the provider value to false
        ref.read(scrollToTopProviderVisitors.notifier).state = false;
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Cats'),
                  Tab(text: 'Dogs'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnimalGrid(animalsMap['cats'] ?? []),
                    _buildAnimalGrid(animalsMap['dogs'] ?? []),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalGrid(List<Animal> animals) {
    if (animals.isEmpty) {
      return const Center(
          child: Icon(Icons.pets, size: 50, color: Colors.grey));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / maxItemExtent).ceil();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxItemExtent,
            childAspectRatio: 1.0,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final animal = animals[index];
              final imageUrl =
                  (animal.photos != null && animal.photos!.isNotEmpty)
                      ? animal.photos!.first.url ?? ''
                      : '';

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
                                imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder: (context, url) =>
                                            const Center(
                                          child: Icon(Icons.pets,
                                              size: 50, color: Colors.grey),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Center(
                                          child: Icon(Icons.error,
                                              color: Colors.red),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.pets,
                                            size: 50, color: Colors.grey),
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
                                          Colors.black.withOpacity(0.7),
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
            },
            childCount: animals.length,
          ),
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
  late Timer _timer;
  late List<Animal> _shuffledAnimals;
  String _currentImageUrl = '';
  Animal? _currentAnimal;

  @override
  void initState() {
    super.initState();

    // Shuffle the list of animals
    _shuffledAnimals = List.from(widget.animals)..shuffle();

    // Set the initial image URL and animal
    _setCurrentImage();

    // Start the slideshow
    _startSlideshow();

    // Enter full-screen mode if appropriate
    enterFullScreen();
  }

  void _setCurrentImage() {
    final animal = _shuffledAnimals[_currentIndex];
    _currentAnimal = animal; // Set the current animal
    if (animal.photos != null && animal.photos!.isNotEmpty) {
      _currentImageUrl = animal.photos!.first.url ?? '';
    } else {
      _currentImageUrl = '';
    }
  }

  void _startSlideshow() {
    // Get the slideshow timer setting from account settings
    final accountSettings = widget.ref.read(accountSettingsViewModelProvider).value?.accountSettings;
    final slideshowTimer = accountSettings?.slideshowTimer ?? 10; // Default to 10 seconds if not set

    // Start the timer to change images based on the slideshow timer setting
    _timer = Timer.periodic(Duration(seconds: slideshowTimer), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _shuffledAnimals.length;
        _setCurrentImage();
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
    final accountSettings = widget.ref.watch(accountSettingsViewModelProvider).value?.accountSettings;

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
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
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
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: imageWidget,
                  ),
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
          duration:
              const Duration(seconds: 2), // Duration of the fade transition
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: content,
        ),
      ),
    );
  }
}
