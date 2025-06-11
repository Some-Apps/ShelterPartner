import 'dart:async';
import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:shelter_partner/models/ad.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/view_models/enrichment_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/views/components/animal_card_view.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:shelter_partner/views/components/put_back_confirmation_view.dart';
import 'package:shelter_partner/views/components/simplistic_animal_card_view.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';
import 'package:shelter_partner/views/components/take_out_confirmation_view.dart';
import 'package:shelter_partner/views/pages/main_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class EnrichmentPage extends ConsumerStatefulWidget {
  const EnrichmentPage({super.key});

  @override
  ConsumerState<EnrichmentPage> createState() => _EnrichmentPageState();
}

class _EnrichmentPageState extends ConsumerState<EnrichmentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedGroupingCategory = 'None';

  // State variables for search and attribute selection
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  int selectedLocationTierCount = 4; // Default to 2 location tiers
  final List<int> locationTierOptions = [1, 2, 3, 4];

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
    'Let Out Type': 'letOutType',
    'Early Put Back Reason': 'earlyPutBackReason',
  };

  // PagingControllers for infinite scrolling
  final PagingController<int, dynamic> _dogsPagingController = PagingController(
    firstPageKey: 0,
  );
  final PagingController<int, dynamic> _catsPagingController = PagingController(
    firstPageKey: 0,
  );

  static const int _pageSize = 500;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    PaintingBinding.instance.imageCache.maximumSize = 1000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;

    _scrollController = ScrollController();

    _tabController = TabController(length: 2, vsync: this);

    _dogsPagingController.addPageRequestListener((pageKey) {
      _fetchPage(animalType: 'dogs', pageKey: pageKey);
    });

    _catsPagingController.addPageRequestListener((pageKey) {
      _fetchPage(animalType: 'cats', pageKey: pageKey);
    });

    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _dogsPagingController.dispose();
    _catsPagingController.dispose();
    _scrollController.dispose();

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
          case 'letOutType':
            fieldValue = animal.logs.isNotEmpty ? animal.logs.last.type : '';

            break;
          case 'earlyPutBackReason':
            fieldValue = animal.logs.isNotEmpty
                ? animal.logs.last.earlyReason
                : '';
            break;
          // Add more cases for other attributes as needed
          default:
            fieldValue = '';
        }
        return _containsQuery(fieldValue?.toLowerCase());
      }).toList();
    }
  }

  Map<String, List<Animal>> _groupAnimalsByCategory(
    List<Animal> animals,
    String category,
  ) {
    SplayTreeMap<String, List<Animal>> groupedAnimals = SplayTreeMap();

    for (var animal in animals) {
      String? key;

      switch (category) {
        case 'Adoption Category':
          key = animal.adoptionCategory;
          break;
        case 'Behavior Category':
          key = animal.behaviorCategory;
          break;
        // case 'Location Category':
        //   key = animal.locationCategory;
        //   break;
        case 'Medical Category':
          key = animal.medicalCategory;
          break;
        case 'Volunteer Category':
          key = animal.volunteerCategory;
          break;
        default:
          key = null;
      }

      if (key != null && key.isNotEmpty) {
        groupedAnimals.putIfAbsent(key, () => []).add(animal);
      }
    }

    return groupedAnimals;
  }

  Future<void> _fetchPage({
    required String animalType,
    required int pageKey,
  }) async {
    try {
      final animalsMapAsync = ref.watch(enrichmentViewModelProvider);
      final animalsMap = animalsMapAsync[animalType];
      if (animalsMap == null || animalsMap.isEmpty) {
        // Data is still loading, retry after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _fetchPage(animalType: animalType, pageKey: pageKey);
        });
        return;
      }

      final animals = animalsMap;
      final filteredAnimals = _filterAnimals(animals);

      final int totalItemCount = filteredAnimals.length;

      final bool isLastPage = pageKey + _pageSize >= totalItemCount;
      final newItems = filteredAnimals.skip(pageKey).take(_pageSize).toList();

      if (animalType == 'dogs') {
        if (isLastPage) {
          _dogsPagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _dogsPagingController.appendPage(newItems, nextPageKey);
        }
      } else {
        if (isLastPage) {
          _catsPagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _catsPagingController.appendPage(newItems, nextPageKey);
        }
      }
    } catch (error) {
      if (animalType == 'dogs') {
        _dogsPagingController.error = error;
      } else {
        _catsPagingController.error = error;
      }
    }
  }

  Widget _buildAnimalGridView(String animalType, String category) {
    final pagingController = animalType == 'dogs'
        ? _dogsPagingController
        : _catsPagingController;

    final animalsMap = ref.watch(enrichmentViewModelProvider);
    final accountSettings = ref.watch(accountSettingsViewModelProvider);

    if (animalsMap[animalType] == null || animalsMap[animalType]!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (category == 'None') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double minWidth =
                accountSettings.value!.accountSettings!.simplisticMode
                ? 600.0
                : 625.0;
            final double itemHeight =
                accountSettings.value!.accountSettings!.simplisticMode
                ? 160.0
                : 235.0;
            return PagedGridView<int, dynamic>(
              pagingController: pagingController,
              scrollController: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              builderDelegate: PagedChildBuilderDelegate<dynamic>(
                itemBuilder: (context, item, index) {
                  if (item is Animal) {
                    if (accountSettings
                            .value!
                            .accountSettings
                            ?.simplisticMode ??
                        true) {
                      return SimplisticAnimalCardView(animal: item);
                    } else {
                      return AnimalCardView(
                        animal: item,
                        maxLocationTiers: selectedLocationTierCount,
                      );
                    }
                  } else if (item is Ad) {
                    return CustomAffiliateAd(ad: item);
                  } else {
                    return const SizedBox.shrink();
                  }
                },
                firstPageProgressIndicatorBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                newPageProgressIndicatorBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                noItemsFoundIndicatorBuilder: (_) =>
                    const Center(child: Text('No animals found')),
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: minWidth,
                mainAxisExtent: itemHeight,
                crossAxisSpacing: 0.0,
                mainAxisSpacing: 0.0,
              ),
            );
          },
        ),
      );
    } else {
      List<Animal> allAnimals = List.from(animalsMap[animalType]!);
      List<Animal> filteredAnimals = _filterAnimals(allAnimals);

      Map<String, List<Animal>> groupedAnimals = _groupAnimalsByCategory(
        filteredAnimals,
        category,
      );

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView.builder(
          itemCount: groupedAnimals.keys.length,
          itemBuilder: (context, index) {
            String sectionTitle = groupedAnimals.keys.elementAt(index);
            List<Animal> sectionAnimals = groupedAnimals[sectionTitle]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sectionTitle,
                        key: ValueKey('sectionHeader_$sectionTitle'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const Divider(
                        thickness: 2,
                        color: Color.fromARGB(222, 158, 158, 158),
                      ),
                      const SizedBox(height: 3),
                    ],
                  ),
                ),

                // Grid for Animals in this Section
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        accountSettings.value!.accountSettings!.simplisticMode
                        ? 600.0
                        : 625.0,
                    mainAxisExtent:
                        accountSettings.value!.accountSettings!.simplisticMode
                        ? 160.0
                        : 235.0,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: sectionAnimals.length,
                  itemBuilder: (context, itemIndex) {
                    Animal animal = sectionAnimals[itemIndex];

                    return accountSettings
                                .value!
                                .accountSettings
                                ?.simplisticMode ??
                            true
                        ? SimplisticAnimalCardView(animal: animal)
                        : AnimalCardView(
                            animal: animal,
                            maxLocationTiers: selectedLocationTierCount,
                          );
                  },
                ),
              ],
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(appUserProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final accountSettings = ref.watch(accountSettingsViewModelProvider);
    selectedLocationTierCount =
        accountSettings.value?.accountSettings?.locationTierCount ??
        selectedLocationTierCount;

    ref.listen<AsyncValue<List<Ad>>>(adsProvider, (previous, next) {
      next.when(
        data: (ads) {
          // Update the adsStateProvider
          ref.read(adsStateProvider.notifier).state = ads;
        },
        loading: () {},
        error: (error, stackTrace) {},
      );
    });

    // Handle loading and error states
    if (appUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    ref.listen<Map<String, List<Animal>>>(enrichmentViewModelProvider, (
      previous,
      next,
    ) {
      // Refresh the paging controllers when the data changes
      _dogsPagingController.refresh();
      _catsPagingController.refresh();
    });

    // Listen for note additions
    ref.listen<bool>(noteAddedProvider, (previous, next) {
      if (next == true) {
        Fluttertoast.showToast(
          msg: 'Note added',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
        );
        // Reset the provider
        ref.read(noteAddedProvider.notifier).state = false;
      }
    });

    // Listen for log additions
    ref.listen<bool>(logAddedProvider, (previous, next) {
      if (next == true) {
        Fluttertoast.showToast(
          msg: 'Log added',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
        );
        // Reset the provider
        ref.read(logAddedProvider.notifier).state = false;
      }
    });

    // Extract values with null safety
    ref.listen<bool>(scrollToTopProvider, (previous, next) {
      if (next == true) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        // Reset the provider value to false
        ref.read(scrollToTopProvider.notifier).state = false;
      }
    });

    final isAdmin = appUser.type == 'admin';
    final isVolunteer = appUser.type == 'volunteer';
    final accountAllowsBulkTakeOut =
        accountSettings.value?.accountSettings?.allowBulkTakeOut ?? false;
    final shelterAllowsBulkTakeOut =
        shelterSettings.value?.volunteerSettings.allowBulkTakeOut ?? false;

    return SafeArea(
      child: Scaffold(
        // backgroundColor: Colors.grey[200],
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
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        SwitchToggleView(
                          title: "Simplistic Mode",
                          value:
                              accountSettings
                                  .value
                                  ?.accountSettings
                                  ?.simplisticMode ??
                              true,
                          onChanged: (bool newValue) {
                            final user = ref.read(appUserProvider);
                            if (user != null) {
                              ref
                                  .read(
                                    accountSettingsViewModelProvider.notifier,
                                  )
                                  .toggleAttribute(user.id, "simplisticMode");
                            }
                          },
                        ),

                        Row(
                          children: [
                            // Toggle simplistic mode

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
                                    // Refresh paging controllers
                                    _dogsPagingController.refresh();
                                    _catsPagingController.refresh();
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
                                  // Refresh paging controllers
                                  _dogsPagingController.refresh();
                                  _catsPagingController.refresh();
                                });
                              },
                              items: attributeDisplayNames.keys
                                  .map<DropdownMenuItem<String>>((String key) {
                                    return DropdownMenuItem<String>(
                                      value: key,
                                      child: Text(key),
                                    );
                                  })
                                  .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'No. of location tiers shown:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value:
                                        accountSettings
                                            .value
                                            ?.accountSettings
                                            ?.locationTierCount ??
                                        2,
                                    isExpanded: true,
                                    onChanged: (int? newValue) async {
                                      final user = ref.read(appUserProvider);
                                      if (newValue != null && user != null) {
                                        await ref
                                            .read(
                                              accountSettingsViewModelProvider
                                                  .notifier,
                                            )
                                            .updateLocationTierCount(
                                              user.id,
                                              newValue,
                                            );
                                        setState(() {
                                          selectedLocationTierCount = newValue;
                                          _dogsPagingController.refresh();
                                          _catsPagingController.refresh();
                                        });
                                      }
                                    },
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    items: locationTierOptions
                                        .map<DropdownMenuItem<int>>((
                                          int value,
                                        ) {
                                          return DropdownMenuItem<int>(
                                            value: value,
                                            child: Text(
                                              'Last $value tier${value > 1 ? 's' : ''}',
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Group by :',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedGroupingCategory,
                                      isExpanded: true,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedGroupingCategory = newValue!;
                                        });
                                      },
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      items:
                                          [
                                            'None',
                                            'Adoption Category',
                                            'Behavior Category',
                                            // 'Location Category',
                                            'Medical Category',
                                            'Volunteer Category',
                                          ].map<DropdownMenuItem<String>>((
                                            String category,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: category,
                                              child: Text(category),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Navigation button for user filter
                        NavigationButton(
                          title: "User Enrichment Filter",
                          route: '/enrichment/main-filter',
                          extra: FilterParameters(
                            title: "User Enrichment Filter",
                            collection: 'users',
                            documentID: appUser.id,
                            filterFieldPath: 'userFilter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Conditionally show the bulk take out button
                        if ((accountAllowsBulkTakeOut && isAdmin) ||
                            (isVolunteer && shelterAllowsBulkTakeOut))
                          ElevatedButton(
                            onPressed: () {
                              // Determine the animal type based on available data
                              final animalsMap = ref.read(
                                enrichmentViewModelProvider,
                              );

                              final availableAnimalTypes = ['dogs', 'cats']
                                  .where(
                                    (type) =>
                                        (animalsMap[type]?.isNotEmpty ?? false),
                                  )
                                  .toList();

                              if (availableAnimalTypes.isEmpty) {
                                Fluttertoast.showToast(
                                  msg: 'No animals available',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.red,
                                );
                                return;
                              }

                              // Safely determine the animal type
                              final animalType =
                                  availableAnimalTypes[availableAnimalTypes
                                              .length ==
                                          1
                                      ? 0
                                      : _tabController.index];
                              final animals = _filterAnimals(
                                animalsMap[animalType] ?? [],
                              );

                              if (animals.isEmpty) {
                                Fluttertoast.showToast(
                                  msg: 'No animals available',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.red,
                                );
                                return;
                              }

                              // Determine the majority inKennel status
                              final inKennelCount = animals
                                  .where((animal) => animal.inKennel)
                                  .length;
                              final majorityInKennel =
                                  inKennelCount > animals.length / 2;

                              // Show the appropriate dialog
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
                            child: Consumer(
                              builder: (context, watch, child) {
                                final animalsMap = ref.watch(
                                  enrichmentViewModelProvider,
                                );

                                final availableAnimalTypes = ['dogs', 'cats']
                                    .where(
                                      (type) =>
                                          (animalsMap[type]?.isNotEmpty ??
                                          false),
                                    )
                                    .toList();

                                if (availableAnimalTypes.isEmpty) {
                                  return const Text('No animals available');
                                }

                                final animalType =
                                    availableAnimalTypes[availableAnimalTypes
                                                .length ==
                                            1
                                        ? 0
                                        : _tabController.index];
                                final animals = _filterAnimals(
                                  animalsMap[animalType] ?? [],
                                );

                                return Text(
                                  animals.isNotEmpty &&
                                          animals
                                                  .where(
                                                    (animal) => animal.inKennel,
                                                  )
                                                  .length >
                                              (animals.length / 2)
                                      ? "Take Out All Visible ${animalType == 'dogs' ? 'Dogs' : 'Cats'}"
                                      : "Put Back All Visible ${animalType == 'dogs' ? 'Dogs' : 'Cats'}",
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // Conditionally show the TabBar if there are animals in both categories
              if ((ref.watch(enrichmentViewModelProvider)['dogs']?.isNotEmpty ??
                      false) &&
                  (ref.watch(enrichmentViewModelProvider)['cats']?.isNotEmpty ??
                      false))
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Dogs'),
                    Tab(text: 'Cats'),
                  ],
                  onTap: (index) {
                    // Refresh the appropriate paging controller when switching tabs
                    if (index == 0) {
                      _dogsPagingController.refresh();
                    } else {
                      _catsPagingController.refresh();
                    }
                  },
                ),
              // Conditionally show the TabBarView if there are animals in both categories
              if ((ref.watch(enrichmentViewModelProvider)['dogs']?.isNotEmpty ??
                      false) &&
                  (ref.watch(enrichmentViewModelProvider)['cats']?.isNotEmpty ??
                      false))
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Dogs
                      _buildAnimalGridView('dogs', selectedGroupingCategory),
                      // Cats
                      _buildAnimalGridView('cats', selectedGroupingCategory),
                    ],
                  ),
                )
              // Show only dogs if there are no cats
              else if (ref
                      .watch(enrichmentViewModelProvider)['dogs']
                      ?.isNotEmpty ??
                  false)
                Expanded(
                  child: _buildAnimalGridView('dogs', selectedGroupingCategory),
                )
              // Show only cats if there are no dogs
              else if (ref
                      .watch(enrichmentViewModelProvider)['cats']
                      ?.isNotEmpty ??
                  false)
                Expanded(
                  child: _buildAnimalGridView('cats', selectedGroupingCategory),
                )
              // Show a message if there are no animals
              else
                const Expanded(
                  child: Center(child: Text('No animals available')),
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

  const CustomAffiliateAd({super.key, required this.ad});

  @override
  _CustomAffiliateAdState createState() => _CustomAffiliateAdState();
}

class _CustomAffiliateAdState extends State<CustomAffiliateAd>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;
  late final List<String> _imageUrls;
  final double _scrollSpeed = 0.25;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Duplicate the images to create a seamless loop
    _imageUrls = [
      ...widget.ad.imageUrls,
      ...widget.ad.imageUrls,
      ...widget.ad.imageUrls,
    ];

    // Set the initial scroll position to the start of the second set of images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final initialPosition = _scrollController.position.maxScrollExtent / 3;
        _scrollController.jumpTo(initialPosition);
      }
    });

    // Set up the AnimationController
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            seconds: 10,
          ), // Adjust the duration as needed
        )..addListener(() {
          if (_scrollController.hasClients) {
            double maxScrollExtent = _scrollController.position.maxScrollExtent;
            double currentScroll = _scrollController.position.pixels;
            double delta = _scrollSpeed; // Adjust scroll speed here

            if (currentScroll + delta >= maxScrollExtent) {
              double resetPosition = maxScrollExtent / 3;
              _scrollController.jumpTo(resetPosition);
            } else {
              _scrollController.jumpTo(currentScroll + delta);
            }
          }
        });

    // Repeat the animation indefinitely
    _animationController.repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
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
    final resizedImages = _imageUrls.map((url) {
      final proxyUrl =
          'https://us-central1-production-10b3e.cloudfunctions.net/cors-images?url=${Uri.encodeComponent(url)}';
      return CachedNetworkImage(
        imageUrl: proxyUrl,
        cacheKey: url,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    }).toList();

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
                    itemCount: resizedImages.length,
                    itemBuilder: (context, index) {
                      return AspectRatio(
                        aspectRatio: 1, // Square aspect ratio
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: resizedImages[index],
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('ads')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Ad.fromMap(doc.data(), doc.id)).toList(),
      );
});

final noteAddedProvider = StateProvider<bool>((ref) => false);
final logAddedProvider = StateProvider<bool>((ref) => false);

final adsStateProvider = StateProvider<List<Ad>?>((ref) => null);
