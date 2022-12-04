import 'package:blur/blur.dart';
import 'package:flutter/material.dart';

import '../main.dart';


Widget blurredImageBuilder(BuildContext context, ImageProvider<Object> imageProvider) => SizedBox.expand(
  child: DecoratedBox(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: imageProvider,
        fit: BoxFit.fitWidth,
      ),
    ),
    child: ClipRRect(
      child: Blur(
        blur: preferences.blurImages ? 20 : 0,
        blurColor: Colors.black,
        colorOpacity: preferences.blurImages ? 0.2 : 0.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
            ),
          ),
        ),
      ),
    ),
  ),
);
