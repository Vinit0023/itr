import 'package:flutter/material.dart';

Widget platformFileImage(String path, {BoxFit fit = BoxFit.cover, int? cacheWidth, Widget Function()? errorBuilder}) {
  // On web, we shouldn't even be calling this if logic is correct, 
  // but as a safety fallback:
  return errorBuilder?.call() ?? const Center(child: Icon(Icons.image_not_supported));
}
