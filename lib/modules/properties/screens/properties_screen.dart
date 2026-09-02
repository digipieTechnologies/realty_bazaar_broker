import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../util/common_ext.dart';
import 'properties_mobile_view.dart';
import 'properties_web_view.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On Web or Desktop screens (unless screen width is a small mobile phone < 600px)
    if (kIsWeb || context.isDesktop) {
      if (context.width >= 720) {
        return const PropertiesWebView();
      }
    }
    return const PropertiesMobileView();
  }
}
