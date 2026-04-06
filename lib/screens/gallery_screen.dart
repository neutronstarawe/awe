import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  final String title;
  final List<String> imagePaths;

  const GalleryScreen({
    super.key,
    required this.title,
    required this.imagePaths,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: imagePaths.isEmpty
          ? Center(
              child: Text(
                'No images yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            )
          : PageView.builder(
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: SizedBox.expand(child: Image.asset(
                    imagePaths[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 48,
                        ),
                      );
                    },
                  )),
                );
              },
            ),
    );
  }
}
