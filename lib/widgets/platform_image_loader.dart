import 'package:flutter/material.dart';

Widget platformFileImage(String path, {BoxFit fit = BoxFit.cover, int? cacheWidth, Widget Function()? errorBuilder}) {
  return errorBuilder?.call() ?? const Center(child: Icon(Icons.broken_image));
}
