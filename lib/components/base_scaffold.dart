import 'package:flutter/material.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget? body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  BaseScaffold({
    required this.title,
    this.body,
    this.floatingActionButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
        ),
        actions: actions ?? [],
      ),
      body: SafeArea(
        child: body ?? Container(),
      ),
      floatingActionButton: floatingActionButton ?? Container(),
    );
  }
}
