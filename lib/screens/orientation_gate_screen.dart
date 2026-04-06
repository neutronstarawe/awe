import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Locks the app to portrait orientation and passes through a child widget.
class OrientationGateScreen extends StatefulWidget {
  final Widget child;

  const OrientationGateScreen({
    super.key,
    required this.child,
  });

  @override
  State<OrientationGateScreen> createState() => _OrientationGateScreenState();
}

class _OrientationGateScreenState extends State<OrientationGateScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
