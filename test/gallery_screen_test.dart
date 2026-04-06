import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/screens/gallery_screen.dart';

void main() {
  group('GalleryScreen', () {
    testWidgets('has no AppBar (headerless full-screen design)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: GalleryScreen(
          title: 'Intricate',
          imagePaths: [],
        ),
      ));

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: GalleryScreen(
          title: 'Cosmic',
          imagePaths: [],
        ),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('renders PageView for swiping', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: GalleryScreen(
          title: 'Cosmic',
          imagePaths: [
            'assets/images/cosmic/01.jpg',
            'assets/images/cosmic/02.jpg',
          ],
        ),
      ));

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('can be navigated to and screen is visible', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GalleryScreen(
                  title: 'Majestic',
                  imagePaths: [],
                ),
              ),
            ),
            child: const Text('Open Gallery'),
          );
        }),
      ));

      await tester.tap(find.text('Open Gallery'));
      await tester.pumpAndSettle();

      expect(find.byType(GalleryScreen), findsOneWidget);
      // No in-app back button — users use the phone's native back gesture
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('each image is wrapped in InteractiveViewer for pinch-to-zoom',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: GalleryScreen(
          title: 'Cosmic',
          imagePaths: ['assets/images/cosmic/01.jpg'],
        ),
      ));

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('shows "No images yet" when imagePaths is empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: GalleryScreen(
          title: 'Intricate',
          imagePaths: [],
        ),
      ));

      expect(find.text('No images yet'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });
  });
}
