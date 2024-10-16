
import 'package:flutter/material.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimalCardView extends StatelessWidget {
  final Animal animal;

  const AnimalCardView({Key? key, required this.animal}) : super(key: key);

  String getScaledDownUrl(String url) {
    final parts = url.split('.');
    if (parts.length > 1) {
      parts[parts.length - 2] += '_100x100';
    }
    return parts.join('.');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: animal.inKennel ? Colors.lightBlue.shade100 : Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the first photo if available, otherwise show a placeholder
            animal.photos.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: getScaledDownUrl(animal.photos.first.url),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  )
                : const SizedBox(
                    width: 100,
                    height: 100,
                    child: Icon(Icons.pets, size: 50),
                  ),
            const SizedBox(width: 10),
            // Animal details: name and location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        animal.location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}
