// File: lib/modules/properties/widgets/property_preview_media_gallery.dart
// Purpose: A thin wrapper around MediaCollageWidget for the property preview dialog.

import 'package:flutter/material.dart';

import '../../../models/media_model.dart';
import '../../../widgets/media/full_screen_media_viewer.dart';
import '../../../widgets/media/media_collage_widget.dart';

class PropertyPreviewMediaGallery extends StatelessWidget {
  final List<MediaModel> medias;
  final double height;

  const PropertyPreviewMediaGallery({super.key, required this.medias, this.height = 240.0});

  @override
  Widget build(BuildContext context) {
    return MediaCollageWidget(
      medias: medias,
      height: height,
      onMediaTap: (index) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenMediaViewer(medias: medias, initialIndex: index),
          ),
        );
      },
    );
  }
}
