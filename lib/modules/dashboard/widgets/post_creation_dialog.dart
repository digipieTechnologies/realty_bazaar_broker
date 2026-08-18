// File: lib/modules/dashboard/widgets/post_creation_dialog.dart
// Purpose: Wrapper delegating to PostPropertyDialog for social posting flow.

import 'package:flutter/material.dart';
import '../../properties/widgets/post_property_dialog.dart';

class PostCreationDialog extends StatelessWidget {
  final String brokerId;

  const PostCreationDialog({super.key, required this.brokerId});

  @override
  Widget build(BuildContext context) {
    return PostPropertyDialog(brokerId: brokerId);
  }
}
