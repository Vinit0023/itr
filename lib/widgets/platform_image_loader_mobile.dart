import 'dart:io';
import 'package:flutter/material.dart';

Widget platformFileImage(String path, {BoxFit fit = BoxFit.cover, int? cacheWidth, Widget Function()? errorBuilder}) {
  return Image.file(
    File(path),
    fit: fit,
    cacheWidth: cacheWidth,
    errorBuilder: errorBuilder != null ? (context, error, stackTrace) => errorBuilder() : null,
  );
}
