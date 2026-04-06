import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/app_preferences.dart';
import 'package:awe/screens/hub_screen.dart';
import 'package:awe/screens/gallery_screen.dart';
import 'package:awe/screens/experience_screen.dart';

void main() {
  group('HubScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // All hub tests run in landscape (1920x1080) — the hub is landscape-only
    });

    Future<AppPreferences> makePrefs() async {
      final prefs = AppPreferences();
      await prefs.init();
      return prefs;
    }

    void setLandscape(WidgetTester tester) {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
    }

    testWidgets('renders all 4 tiles with correct labels', (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      expect(find.textContaining('Intricate'), findsOneWidget);
      expect(find.textContaining('Majestic'), findsOneWidget);
      expect(find.textContaining('Cosmic'), findsOneWidget);
      expect(find.textContaining('Stars'), findsOneWidget);
    });

    testWidgets('renders correct sublabels', (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      expect(find.text('The Small'), findsOneWidget);
      expect(find.text('The Grand'), findsOneWidget);
      expect(find.text('The Infinite'), findsOneWidget);
      expect(find.text('Coming Soon'), findsOneWidget);
    });

    testWidgets('shows "awe" title', (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      expect(find.text('awe'), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('shows "Relive the Experience" button', (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      expect(find.textContaining('Relive'), findsOneWidget);
    });

    testWidgets('tapping Intricate navigates to GalleryScreen with title Intricate',
        (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      await tester.tap(find.textContaining('Intricate'));
      await tester.pumpAndSettle();

      expect(find.byType(GalleryScreen), findsOneWidget);
      final gallery = tester.widget<GalleryScreen>(find.byType(GalleryScreen));
      expect(gallery.title, equals('Intricate'));
    });

    testWidgets('tapping Majestic navigates to GalleryScreen with title Majestic',
        (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      await tester.tap(find.textContaining('Majestic'));
      await tester.pumpAndSettle();

      expect(find.byType(GalleryScreen), findsOneWidget);
      final gallery = tester.widget<GalleryScreen>(find.byType(GalleryScreen));
      expect(gallery.title, equals('Majestic'));
    });

    testWidgets('tapping Cosmic navigates to GalleryScreen with title Cosmic',
        (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      await tester.tap(find.textContaining('Cosmic'));
      await tester.pumpAndSettle();

      expect(find.byType(GalleryScreen), findsOneWidget);
      final gallery = tester.widget<GalleryScreen>(find.byType(GalleryScreen));
      expect(gallery.title, equals('Cosmic'));
    });

    testWidgets('tapping Stars Simulation does not navigate away', (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      await tester.tap(find.textContaining('Stars'));
      await tester.pump();

      expect(find.byType(HubScreen), findsOneWidget);
    });

    testWidgets('"Relive the Experience" navigates to ExperienceScreen',
        (tester) async {
      setLandscape(tester);
      final prefs = await makePrefs();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(preferences: prefs),
      ));

      await tester.tap(find.textContaining('Relive'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ExperienceScreen), findsOneWidget);

      // Drain video controller async operations
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration.zero);
      }
    });
  });
}
