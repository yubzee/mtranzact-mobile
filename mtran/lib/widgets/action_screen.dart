import 'package:flutter/material.dart';

class ActionScreen extends StatefulWidget {
  const ActionScreen({super.key, required this.action, this.params});
  final Future<void> Function(BuildContext, Map?)? action;
  final Map? params;

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await doAction(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }

  Future<void> doAction(BuildContext context) async {
    if (widget.action != null) {
      await widget.action!(context, widget.params);
    }
  }
}
