import 'package:flutter/material.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimalCardView extends StatefulWidget {
  final Animal animal;

  const AnimalCardView({Key? key, required this.animal}) : super(key: key);

  @override
  _AnimalCardViewState createState() => _AnimalCardViewState();
}

class _AnimalCardViewState extends State<AnimalCardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Adjust duration as needed
    );
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        _controller.forward();
      },
      onLongPressEnd: (_) {
        _controller.reset();
      },
      onLongPressCancel: () {
        _controller.reset();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final fillHeight = _controller.value;

          // Opposite color fill based on inKennel attribute
          final fillColor = widget.animal.inKennel
              ? Colors.orange.shade100 // Filling from blue to orange
              : Colors.lightBlue.shade100; // Filling from orange to blue

          return Stack(
            children: [
              // The background fill effect
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // The original card background
                    Container(
                      decoration: BoxDecoration(
                        color: widget.animal.inKennel
                            ? Colors.lightBlue.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Overlay for the opposite color fill, filling the card from bottom to top
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: fillHeight,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          color: fillColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // The card content (text and image) stays on top of the background
              Card(
                color: Colors.transparent, // Make the card transparent to avoid covering the fill
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animal details: name and location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.animal.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(
                                  widget.animal.location,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Display the first photo if available, otherwise show a placeholder
                      Transform.scale(
                        scale: 1.0 + (_controller.value * 0.1), // Slight zoom on image
                        child: ClipOval(
                          child: widget.animal.photos.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: getScaledDownUrl(
                                      widget.animal.photos.first.url),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                )
                              : const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Icon(Icons.pets, size: 50),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
