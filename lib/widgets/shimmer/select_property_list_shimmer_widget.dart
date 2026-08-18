// File: lib/widgets/shimmer/select_property_list_shimmer_widget.dart
// Purpose: Separate shimmer loading placeholder widget for SelectPropertyForVideoRequestDialog.

import 'package:flutter/material.dart';
import 'app_shimmer_container.dart';

class SelectPropertyListShimmerWidget extends StatelessWidget {
  final int itemCount;

  const SelectPropertyListShimmerWidget({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: AppShimmerContainer(
            height: 76.0,
            borderRadius: 12.0,
          ),
        ),
      ),
    );
  }
}
