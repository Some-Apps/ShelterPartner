import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/ad.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/view_models/animals_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/views/components/animal_card_view.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:shelter_partner/views/components/put_back_confirmation_view.dart';
import 'package:shelter_partner/views/components/take_out_confirmation_view.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimalsPage extends ConsumerStatefulWidget {
  const AnimalsPage({super.key});

  @override
  ConsumerState<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends ConsumerState<AnimalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;


  // State variables for search and attribute selection
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // For attribute dropdown
  String selectedAttributeDisplayName = 'Name'; // Default display name
  String selectedAttribute = 'name'; // Corresponding attribute key
  Map<String, String> attributeDisplayNames = {
    'Name': 'name',
    'Notes': 'notes',
    'Tags': 'tags',
    'Sex': 'sex',
    'Breed': 'breed',
    'Location': 'location',
    'Description': 'description',
    'Take Out Alert': 'takeOutAlert',
    'Put Back Alert': 'putBackAlert',
    'Adoption Category': 'adoptionCategory',
    'Behavior Category': 'behaviorCategory',
    'Location Category': 'locationCategory',
    'Medical Category': 'medicalCategory',
    'Volunteer Category': 'volunteerCategory',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Remove the listener since we're using TabBarView
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to check if a field contains the query
  bool _containsQuery(String? field) {
    return field != null && field.toLowerCase().contains(searchQuery);
  }

  // Method to filter animals based on the selected attribute
  List<Animal> _filterAnimals(List<Animal> animals) {
    if (searchQuery.isEmpty) {
      return animals;
    } else {
      return animals.where((animal) {
        String? fieldValue;
        switch (selectedAttribute) {
          case 'name':
            fieldValue = animal.name;
            break;
          case 'sex':
            fieldValue = animal.sex;
            break;
          case 'notes':
            fieldValue = animal.notes.map((note) => note.note).join(' ');
            break;
          case 'tags':
            fieldValue = animal.tags.map((tag) => tag.title).join(' ');
            break;
          case 'breed':
            fieldValue = animal.breed;
            break;
          case 'location':
            fieldValue = animal.location;
            break;
          case 'description':
            fieldValue = animal.description;
            break;
          case 'takeOutAlert':
            fieldValue = animal.takeOutAlert;
            break;
          case 'putBackAlert':
            fieldValue = animal.putBackAlert;
            break;
          case 'adoptionCategory':
            fieldValue = animal.adoptionCategory;
            break;
          case 'behaviorCategory':
            fieldValue = animal.behaviorCategory;
            break;
          case 'locationCategory':
            fieldValue = animal.locationCategory;
            break;
          case 'medicalCategory':
            fieldValue = animal.medicalCategory;
            break;
          case 'volunteerCategory':
            fieldValue = animal.volunteerCategory;
            break;
          default:
            fieldValue = '';
        }
        return _containsQuery(fieldValue.toLowerCase());
      }).toList();
    }
  }

Widget _buildAnimalGridView(String animalType, AsyncValue<List<Ad>> adsAsyncValue) {
  final appUser = ref.watch(appUserProvider);
  final animalsMap = ref.watch(animalsViewModelProvider);
  final animals = animalsMap[animalType] ?? [];
  final filteredAnimals = _filterAnimals(animals);

  if (animals.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  } else if (filteredAnimals.isEmpty) {
    return const Center(child: Text('No animals found'));
  } else {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int columns = (constraints.maxWidth / 400).floor();
          final double aspectRatio = constraints.maxWidth / (columns * 200);

          // Adjust item count based on whether ads are removed
          int itemCount = filteredAnimals.length;
          if (!appUser!.removeAds) {
            itemCount += filteredAnimals.length ~/ 10;
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: aspectRatio,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (!appUser.removeAds && (index + 1) % 11 == 0) {
                // This is an ad position
                return _buildAdCard(adsAsyncValue);
              } else {
                // Adjust the index to account for the ads
                int adjustedIndex = index;
                if (!appUser.removeAds) {
                  adjustedIndex = index - (index ~/ 11);
                }
                final animal = filteredAnimals[adjustedIndex];
                return AnimalCardView(animal: animal);
              }
            },
          );
        },
      ),
    );
  }
}

Widget _buildAdCard(AsyncValue<List<Ad>> adsAsyncValue) {
  return adsAsyncValue.when(
    data: (ads) {
      if (ads.isEmpty) {
        return const Text('No ads available');
      }
      final randomAd = ads[Random().nextInt(ads.length)];
      return CustomAffiliateAd(
        ad: Ad(id: randomAd.id, imageUrls: randomAd.imageUrls, productName: randomAd.productName, productUrl: randomAd.productUrl),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stackTrace) => const Text('Error loading ads'),
  );
}


  @override
  Widget build(BuildContext context) {
    final adsAsyncValue = ref.watch(adsProvider);
    final appUser = ref.watch(appUserProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final deviceSettings = ref.watch(deviceSettingsViewModelProvider);

    // Handle loading and error states
    if (appUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Proceed even if shelterSettings or deviceSettings are still loading or null

    // Extract values with null safety
    final isAdmin = appUser.type == 'admin';
    final isVolunteer = appUser.type == 'volunteer';
    final deviceAllowsBulkTakeOut =
        deviceSettings.value?.deviceSettings?.allowBulkTakeOut ?? false;
    final shelterAllowsBulkTakeOut =
        shelterSettings.value?.volunteerSettings.allowBulkTakeOut ?? false;

    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              // Collapsible section for search bar, attribute dropdown, and "Take Out All Animals" button
              ExpansionTile(
                title: const Text('Additional Options'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Search bar
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search animals...',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value.toLowerCase();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Attribute dropdown
                            DropdownButton<String>(
                              value: selectedAttributeDisplayName,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedAttributeDisplayName = newValue!;
                                  selectedAttribute =
                                      attributeDisplayNames[newValue]!;
                                });
                              },
                              items: attributeDisplayNames.keys
                                  .map<DropdownMenuItem<String>>(
                                      (String key) {
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(key),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Navigation button for user filter
                        NavigationButton(
                          title: "User Filter",
                          route: '/animals/main-filter',
                          extra: FilterParameters(
                            title: "User Filter",
                            collection: 'users',
                            documentID: appUser.id,
                            filterFieldPath: 'userFilter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Conditionally show the bulk take out button
                        if ((deviceAllowsBulkTakeOut && isAdmin) ||
                            (isVolunteer && shelterAllowsBulkTakeOut))
                          ElevatedButton(
                            onPressed: () {
                              // Get the visible animals in the current tab
                              final animalType =
                                  _tabController.index == 0 ? 'dogs' : 'cats';
                              final animals = _filterAnimals(
                                  ref.watch(animalsViewModelProvider)[
                                          animalType] ??
                                      []);

                              // Determine the majority inKennel status
                              final inKennelCount = animals
                                  .where((animal) => animal.inKennel)
                                  .length;
                              final majorityInKennel =
                                  inKennelCount > animals.length / 2;

                              if (majorityInKennel) {
                                showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return TakeOutConfirmationView(
                                      animals: animals,
                                    );
                                  },
                                );
                              } else {
                                showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return PutBackConfirmationView(
                                      animals: animals,
                                    );
                                  },
                                );
                              }
                            },
                            child: Text(
                              _tabController.index == 0
                                  ? (_filterAnimals(
                                                  ref.watch(
                                                          animalsViewModelProvider)[
                                                      'dogs'] ??
                                                  [])
                                              .where((animal) => animal.inKennel)
                                              .length >
                                          (_filterAnimals(
                                                      ref.watch(
                                                              animalsViewModelProvider)[
                                                          'dogs'] ??
                                                      [])
                                                  .length /
                                              2)
                                      ? "Take Out All Visible Dogs"
                                      : "Put Back All Visible Dogs")
                                  : (_filterAnimals(
                                                  ref.watch(
                                                          animalsViewModelProvider)[
                                                      'cats'] ??
                                                  [])
                                              .where((animal) => animal.inKennel)
                                              .length >
                                          (_filterAnimals(
                                                      ref.watch(
                                                              animalsViewModelProvider)[
                                                          'cats'] ??
                                                      [])
                                                  .length /
                                              2)
                                      ? "Take Out All Visible Cats"
                                      : "Put Back All Visible Cats"),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // TabBar (Cat/Dog switch)
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Dogs'),
                  Tab(text: 'Cats'),
                ],
              ),
              // TabBarView to display content based on selected tab
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Dogs
                          _buildAnimalGridView('dogs', adsAsyncValue),
                    // Cats
                          _buildAnimalGridView('cats', adsAsyncValue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomAffiliateAd extends StatefulWidget {
  final Ad ad;

  const CustomAffiliateAd({
    super.key,
    required this.ad,
  });

  @override
  _CustomAffiliateAdState createState() => _CustomAffiliateAdState();
}

class _CustomAffiliateAdState extends State<CustomAffiliateAd> {
  late final ScrollController _scrollController;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Set up a timer to auto-scroll continuously
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        double maxScrollExtent = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        double delta = 1; // Adjust scroll speed here

        if (currentScroll + delta >= maxScrollExtent) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            currentScroll + delta,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    final uri = Uri.parse(widget.ad.productUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch ${widget.ad.productUrl}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        color: Colors.grey.shade300,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _launchUrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Carousel with continuous scrolling ListView
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final imageUrl = widget.ad.imageUrls[index % widget.ad.imageUrls.length];
                      return AspectRatio(
                        aspectRatio: 1, // Square aspect ratio
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Product name
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget.ad.productName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              // Buy Now button
              ElevatedButton(
                onPressed: _launchUrl,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text('Buy Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final adsProvider = StreamProvider<List<Ad>>((ref) {
  return FirebaseFirestore.instance
      .collection('ads')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Ad.fromMap(doc.data(), doc.id)).toList());
});