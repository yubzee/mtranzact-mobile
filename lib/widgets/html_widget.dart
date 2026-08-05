import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class HtmlWidget extends StatelessWidget {
  const HtmlWidget({super.key, required this.data});

  final String data;

  @override
  Widget build(context) {
    return Html(
      data: data,
    );
  }
}
