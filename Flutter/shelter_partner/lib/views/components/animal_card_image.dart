import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shelter_partner/models/animal.dart';

class AnimalCardImage extends StatelessWidget {
  final Animation<double> _curvedAnimation;
  final bool isPressed;
  final Animal animal;

  const AnimalCardImage({
    super.key,
    required Animation<double> curvedAnimation,
    required this.isPressed,
    required this.animal,
  })  : _curvedAnimation = curvedAnimation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background stroke (semi-transparent)
        CircleAvatar(
          radius: 62.5,
          backgroundColor: Colors.black.withOpacity(0.15),
        ),

        // Animated stroke
        AnimatedBuilder(
          animation: _curvedAnimation,
          builder: (context, child) {
            return SizedBox(
              width: 125,
              height: 125,
              child: CustomPaint(
                painter: CircleProgressPainter(
                  progress: _curvedAnimation.value,
                  color: animal.inKennel
                      ? Colors.orange.shade100
                      : Colors.lightBlue.shade100,
                ),
              ),
            );
          },
        ),

        // Image with shadow, scale effect, faded edges, and scratches
        AnimatedScale(
          scale: isPressed ? 1.0 : 1.025,
          duration: const Duration(milliseconds: 0),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 0.25,
                  spreadRadius: 0,
                  offset: isPressed ? const Offset(0, 0) : const Offset(0, 1.5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Apply ShaderMask for faded edges
                ClipOval(
                  child: animal.photos?.isNotEmpty ?? false
                        ? CachedNetworkImage(
                          imageUrl: animal.photos?.first.url.contains('amazonaws.com') ?? false
                            ? 'https://cors-images-222422545919.us-central1.run.app?url=${animal.photos?.first.url}'
                            : animal.photos?.first.url ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(Icons.pets,
                            size: 50, color: Colors.grey.shade400),
                          errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                        )
                      : Icon(Icons.pets, size: 50, color: Colors.grey.shade400),
                ),
                // Overlay scratch mask
                // ClipOval(
                //   child: Image.asset(
                //     'assets/images/scratch_mask.png',
                //     width: 100,
                //     height: 100,
                //     fit: BoxFit.cover,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class CircleProgressPainter extends CustomPainter {
  final double progress; // Progress from 0.0 to 1.0
  final Color color;

  CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the sweep angle based on progress
    double sweepAngle = 2 * pi * progress;

    // Define the center and radius of the circle
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);

    // Create a paint object
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw the filled arc (sector)
    Path path = Path()
      ..moveTo(center.dx, center.dy) // Move to center
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start angle (top of the circle)
        sweepAngle, // Sweep angle
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}
