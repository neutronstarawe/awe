import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/screens/orientation_gate_screen.dart';

void main() {
  testWidgets('shows rotate animation in portrait orientation', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920); // portrait
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrientationGateScreen(
          child: Scaffold(body: Text('Landscape Content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('rotate_animation')), findsOneWidget);
    expect(find.text('Landscape Content'), findsNothing);
  });

  testWidgets('shows child content in landscape orientation', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080); // landscape
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrientationGateScreen(
          child: Scaffold(body: Text('Landscape Content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Landscape Content'), findsOneWidget);
    expect(find.byKey(const ValueKey('rotate_animation')), findsNothing);
  });

  testWidgets('switches to content when orientation changes to landscape',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920); // start portrait
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrientationGateScreen(
          child: Scaffold(body: Text('Landscape Content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('rotate_animation')), findsOneWidget);

    // Simulate rotating to landscape
    tester.view.physicalSize = const Size(1920, 1080);
    await tester.pump();

    expect(find.text('Landscape Content'), findsOneWidget);
    expect(find.byKey(const ValueKey('rotate_animation')), findsNothing);
  });
}
