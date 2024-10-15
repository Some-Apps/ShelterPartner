import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/view_models/visitors_view_model.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

class VisitorPage extends ConsumerStatefulWidget {
  const VisitorPage({super.key});

  @override
  ConsumerState<VisitorPage> createState() => _VisitorPageState();
}

class _VisitorPageState extends ConsumerState<VisitorPage>
    with SingleTickerProviderStateMixin {
  final int preloadImageCount = 50;
  late ScrollController _scrollController;

  Timer? _throttleTimer;
  final Duration throttleDuration = const Duration(milliseconds: 200);

  final double maxItemExtent = 250;

  // Available resized image sizes
  final List<int> availableSizes = [100, 250, 500, 750];

  // TabController for the TabBar
  late TabController _tabController;

  // Selected animal type ('cats' or 'dogs')
  String selectedAnimalType = 'cats';

  @override
void initState() {
  super.initState();
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      500 * 1024 * 1024; // 500 MB

  _scrollController = ScrollController();
  _scrollController.addListener(_onScroll);

  _tabController = TabController(length: 2, vsync: this);
  _tabController.addListener(_onTabChanged);

  // Remove this line
  // WidgetsBinding.instance.addPostFrameCallback((_) {
  //   _preloadImages();
  // });
}


  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        selectedAnimalType = _tabController.index == 0 ? 'cats' : 'dogs';
        // Reset scroll position
        _scrollController.jumpTo(0);
        // Preload images for the new selection
        _preloadImages();
      });
    }
  }

  void _onScroll() {
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(throttleDuration, () {
      _preloadImages();
    });
  }

  void _preloadImages() {
    if (!mounted) return;

  final animalsMap = ref.watch(visitorsViewModelProvider);
  final animals = animalsMap[selectedAnimalType] ?? [];

  if (animals.isEmpty) return;

    double scrollOffset = _scrollController.position.pixels;
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / maxItemExtent).ceil();

    double itemWidth = screenWidth / crossAxisCount;
    double itemHeight = itemWidth;
    double itemSizeWithPadding = itemHeight + 16.0;

    int currentRow = (scrollOffset / itemSizeWithPadding).floor();
    int currentIndex = currentRow * crossAxisCount;

    int startIndex = currentIndex - preloadImageCount;
    int endIndex = currentIndex + preloadImageCount;

    startIndex = startIndex.clamp(0, animals.length - 1);
    endIndex = endIndex.clamp(0, animals.length - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      final animal = animals[i];
      final imageUrl = getResizedImageUrl(animal, itemWidth.toInt());

      if (imageUrl.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(imageUrl), context);
      }
    }
  }

  String getResizedImageUrl(Animal animal, int targetWidth) {
    if (animal.photos.isEmpty) return '';

    String originalUrl = animal.photos.first.url;
    Uri uri = Uri.parse(originalUrl);
    String fileName = uri.pathSegments.last;

    // Determine the closest available size
    int closestSize = availableSizes.reduce((a, b) =>
        (a - targetWidth).abs() < (b - targetWidth).abs() ? a : b);

    // Modify the filename to include the size suffix
    String resizedFileName = fileName.replaceFirstMapped(
      RegExp(r'(.+)(\.\w+)$'),
      (match) =>
          '${match.group(1)}_${closestSize}x$closestSize${match.group(2)}',
    );

    // Construct the new path segments
    List<String> newPathSegments = List.from(uri.pathSegments);
    newPathSegments[newPathSegments.length - 1] = resizedFileName;

    // Build the new URI
    Uri resizedUri = uri.replace(pathSegments: newPathSegments);

    return resizedUri.toString();
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

  // Listen for changes in the animals data
  ref.listen<Map<String, List<Animal>>>(visitorsViewModelProvider, (prev, next) {
    if (prev != next) {
      _preloadImages();
    }
  });

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / maxItemExtent).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitor (only admin accounts)"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cats'),
            Tab(text: 'Dogs'),
          ],
        ),
      ),
      body: CustomScrollView(
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
                    getResizedImageUrl(animal, maxItemExtent.toInt());

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {},
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Container(
                          color: Colors.grey[300],
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.error, color: Colors.red),
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
                  onPressed: () {}, // Does nothing for now
                  child: const Text('Start Slideshow'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
