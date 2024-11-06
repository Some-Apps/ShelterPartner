import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _loading = true;
  // Add a variable to track the subscription status
  final bool _isSubscribed = false;
  final Set<String> _kProductIds = {'RemoveAds'};

  @override
  void initState() {
    super.initState();
    // Initialize in-app purchase
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchases) {
      _listenToPurchaseUpdated(purchases);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Handle error here.
    });
    _initStoreInfo();
  }

  Future<void> _initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    setState(() {
      _isAvailable = isAvailable;
      _loading = false;
    });

    if (!isAvailable) {
      // The store cannot be reached or accessed. Update UI accordingly.
      return;
    }

    ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds);

    if (productDetailResponse.error != null) {
      // Handle the error.
    } else if (productDetailResponse.productDetails.isEmpty) {
      // No products found.
    } else {
      setState(() {
        _products = productDetailResponse.productDetails;
      });
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        bool valid = await _verifyPurchase(purchase);
        if (valid) {
          _deliverProduct(purchase);
        } else {
          _handleInvalidPurchase(purchase);
          return;
        }
      } else if (purchase.status == PurchaseStatus.error) {
        // Handle the error.
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
  final appUser = ref.read(appUserProvider);
  String receiptData = purchase.verificationData.serverVerificationData;
  String platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  final functions = FirebaseFunctions.instance;
  HttpsCallable callable = functions.httpsCallable('validateReceipt');
  final result = await callable.call({
    'platform': platform,
    'receiptData': receiptData,
    'userId': appUser?.id,
  });

  return result.data['isValid'] ?? false;
}



  void _deliverProduct(PurchaseDetails purchase) async {

  // Store receipt data and platform
  final appUser = ref.read(appUserProvider);
  final firestore = FirebaseFirestore.instance;

  String receiptData = purchase.verificationData.serverVerificationData;
  String platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  if (appUser?.id != null) {
    await firestore.collection('users').doc(appUser!.id).update({
      'isSubscribed': true,
      'receiptData': receiptData,
      'platform': platform,
      'purchaseDate': FieldValue.serverTimestamp(),
    });
  }

  // Call the cloud function to validate the receipt
  await _validateReceipt(receiptData, platform, appUser!.id);
}


Future<void> _validateReceipt(String receiptData, String platform, String userId) async {
  final functions = FirebaseFunctions.instance;
  HttpsCallable callable = functions.httpsCallable('validateReceipt');
  final result = await callable.call({
    'platform': platform,
    'receiptData': receiptData,
    'userId': userId,
  });

  // Handle the result
  if (result.data['isValid']) {
    // Update Firestore with the expiration date
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'subscriptionExpirationDate': result.data['expirationDate'],
    });
  } else {
    // Handle invalid purchase
    _handleInvalidPurchase(null);
  }
}




  void _handleInvalidPurchase(PurchaseDetails? purchase) {
    // Handle invalid purchase here.
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterDetailsViewModelProvider);
    final appUser = ref.watch(appUserProvider);

    return shelterAsyncValue.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  // Text("Settings",
                  //     style: Theme.of(context).textTheme.titleLarge),
                  Card.outlined(
                    child: ListView(
                      shrinkWrap: true,
                      
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        if (appUser?.type == 'admin') ...[
                          ListTile(
                            leading: const Icon(Icons.home_outlined),
                            title: const Text("Shelter Settings"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              context.push('/settings/shelter-settings');
                            },
                          ),
                          Divider(
                            color: Colors.black.withOpacity(0.1),
                            height: 0,
                            thickness: 1,
                          ),
                          ListTile(
                            leading: const Icon(Icons.devices),
                            title: const Text("Device Settings"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              context.push('/settings/device-settings');
                            },
                          ),
                          Divider(
                            color: Colors.black.withOpacity(0.1),
                            height: 0,
                            thickness: 1,
                          ),
                        ],
                        ListTile(
                          leading: const Icon(Icons.swap_horiz),
                          title: Text("Toggle Account Type: ${appUser?.type}"),
                          onTap: () async {
                            final currentType = appUser?.type;
                            final newType =
                                currentType == 'admin' ? 'volunteer' : 'admin';
                            try {
                              final firestore = FirebaseFirestore.instance;
                              final userId = appUser?.id;

                              if (userId != null) {
                                await firestore
                                    .collection('users')
                                    .doc(userId)
                                    .update({'type': newType});
                                ref.read(appUserProvider.notifier).state =
                                    appUser?.copyWith(type: newType);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Account type changed to $newType')),
                                );
                              } else {
                                throw Exception('User ID is null');
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error changing account type: $e')),
                              );
                            }
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text("Logout"),
                          onTap: () {
                            ref
                                .read(authViewModelProvider.notifier)
                                .logout(context);
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text("Delete Account"),
                          subtitle: const Text(
                              "This won't be in the final app but I'd recommend deleting your account and recreating it every once in a while because the organization of the app is going to change a lot so stuff may break for old accounts."),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm Deletion"),
                                content: const Text(
                                    "Are you sure you want to delete your account? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Delete",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final emailController = TextEditingController();
                              final passwordController =
                                  TextEditingController();

                              final credentialsConfirmed =
                                  await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Enter Credentials"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: emailController,
                                        decoration: const InputDecoration(
                                            labelText: "Email"),
                                      ),
                                      TextField(
                                        controller: passwordController,
                                        decoration: const InputDecoration(
                                            labelText: "Password"),
                                        obscureText: true,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text("Confirm"),
                                    ),
                                  ],
                                ),
                              );

                              if (credentialsConfirmed == true) {
                                final email = emailController.text;
                                final password = passwordController.text;
                                try {
                                  await ref
                                      .read(authViewModelProvider.notifier)
                                      .deleteAccount(context, email, password);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error reauthenticating user: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Text("About", style: Theme.of(context).textTheme.titleLarge),
                  Card.outlined(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) 
                          ListTile(
                          leading: const Icon(Icons.favorite_border),
                          title: const Text("Support Us And Remove Ads"),
                          onTap: () async {
                            if (_isAvailable && _products.isNotEmpty) {
                            setState(() {
                              _loading = true;
                            });
                            final ProductDetails product = _products.firstWhere((product) => product.id == 'RemoveAds');
                            final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
                            await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
                            setState(() {
                              _loading = false;
                            });
                            } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Store is unavailable or products not loaded')),
                            );
                            }
                          },
                          ),

                        // ListTile(
                        //   leading: const Icon(Icons.restore),
                        //   title: const Text("Restore Purchases"),
                        //   onTap: () {
                        //     _inAppPurchase.restorePurchases();
                        //   },
                        // ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text("Wiki"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            launchUrl(
                                Uri.parse('https://shelterpartner.org/wiki'));
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text("Acknowledgements"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/settings/acknowledgements');
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        const ListTile(
                          leading: Icon(Icons.numbers, color: Colors.grey),
                          title: Text("Version 2.0.0",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        const ListTile(
                          leading: Icon(Icons.pets, color: Colors.grey),
                          title: Text("Dedicated to Aslan",
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
