// File: lib/widgets/inputs/property_typeahead_field.dart
// Purpose: Reusable TypeAhead autocomplete selector field for properties scoped by broker.

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:the_realty_bazaar/app/app_text_styles.dart';
import 'package:the_realty_bazaar/core/localization/app_localizations.dart';
import 'package:the_realty_bazaar/providers/property/property_provider.dart';
import 'package:the_realty_bazaar/widgets/images/cached_image.dart';

import '../../app/app_colors.dart';
import '../../models/property_enums.dart';
import '../../models/property_model.dart';

class PropertyTypeAheadField extends StatefulWidget {
  final String? brokerId;
  final String? selectedPropertyId;
  final TextEditingController? controller;
  final ValueChanged<PropertyModel?> onPropertyChanged;
  final String? label;
  final String? hintText;
  final bool isRequired;
  final String? Function(String?)? validator;

  const PropertyTypeAheadField({
    super.key,
    required this.brokerId,
    this.selectedPropertyId,
    this.controller,
    required this.onPropertyChanged,
    this.label,
    this.hintText,
    this.isRequired = false,
    this.validator,
  });

  @override
  State<PropertyTypeAheadField> createState() => _PropertyTypeAheadFieldState();
}

class _PropertyTypeAheadFieldState extends State<PropertyTypeAheadField> {
  late final TextEditingController _controller;
  bool _isInternalController = false;
  PropertyModel? _selectedProperty;
  String? _selectedPropertyTitle;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isInternalController = true;
    }
  }

  @override
  void didUpdateWidget(covariant PropertyTypeAheadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If broker changed, clear the property if it doesn't belong to the new broker
    if (oldWidget.brokerId != widget.brokerId) {
      if (_selectedProperty != null && _selectedProperty?.brokerId?.id != widget.brokerId) {
        _selectedProperty = null;
        _selectedPropertyTitle = null;
        _controller.clear();
        widget.onPropertyChanged(null);
      }
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBroker = widget.brokerId != null && widget.brokerId!.isNotEmpty;

    final displayLabel = widget.label ?? context.tr('leads_dialog_property_details');
    final displayHint = hasBroker
        ? (widget.hintText ?? context.tr('leads_dialog_property_details_hint'))
        : 'Select broker first to pick property';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (displayLabel.isNotEmpty) ...[
          Text(widget.isRequired ? '$displayLabel *' : displayLabel, style: AppTextStyles.label),
          const SizedBox(height: 6.0),
        ],
        TypeAheadField<PropertyModel>(
          controller: _controller,
          builder: (context, controller, focusNode) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: hasBroker,
              validator: widget.validator,
              onTap: () {
                if (controller.text.isNotEmpty) {
                  controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
                }
              },
              style: context.textTheme.titleSmall?.copyWith(
                color: hasBroker ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
              decoration: InputDecoration(
                hintText: displayHint,
                hintStyle: context.textTheme.bodySmall?.copyWith(
                  color: isDark ? colorScheme.onSurfaceVariant : AppColors.slate400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.apartment_rounded,
                  size: 20.0,
                  color: hasBroker ? context.theme.primaryColor : null,
                ),
                suffixIcon: hasBroker && controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _selectedProperty = null;
                          _selectedPropertyTitle = null;
                          controller.clear();
                          widget.onPropertyChanged(null);
                        },
                      )
                    : (hasBroker ? const Icon(Icons.arrow_drop_down, size: 22) : null),
                filled: true,
                fillColor: hasBroker ? colorScheme.surface : context.theme.colorScheme.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            );
          },
          suggestionsCallback: (pattern) async {
            if (!hasBroker) return [];

            final trimmed = pattern.trim();
            final isCurrentSelection =
                _selectedProperty != null && (trimmed == _selectedPropertyTitle || trimmed.isEmpty);

            final searchTerm = isCurrentSelection ? null : (trimmed.isNotEmpty ? trimmed : null);

            final result = await PropertyProvider().fetchPropertiesByBroker(
              brokerId: widget.brokerId!,
              searchQuery: searchTerm,
            );

            if (result.error != null) {
              // Handle error, maybe log or show a message
              return [];
            }

            final list = result.properties?.toList() ?? [];

            if (_selectedProperty != null && isCurrentSelection) {
              final listCopy = List<PropertyModel>.from(list);
              final idx = listCopy.indexWhere((p) => p.id == _selectedProperty!.id);
              if (idx > 0) {
                final item = listCopy.removeAt(idx);
                listCopy.insert(0, item);
              } else if (idx == -1) {
                listCopy.insert(0, _selectedProperty!);
              }
              return listCopy;
            }

            return list;
          },
          itemBuilder: (context, property) {
            final isSelected =
                property.id == _selectedProperty?.id ||
                property.propertyTitle.toLowerCase() == _controller.text.trim().toLowerCase();

            final imageUrl = property.medias.isNotEmpty ? property.medias.first.url : null;

            return ListTile(
              dense: true,
              tileColor: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null,
              leading: CachedImage(imageUrl, height: 40, width: 40, borderRadius: BorderRadius.circular(30)),
              title: Text(
                property.propertyTitle,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                '₹${property.price.toStringAsFixed(0)} • ${property.propertyType.displayName} • ${property.bedrooms} BHK',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              trailing: isSelected ? Icon(Icons.check, size: 18, color: colorScheme.primary) : null,
            );
          },
          onSelected: (property) {
            _selectedProperty = property;
            _selectedPropertyTitle = property.propertyTitle;
            _controller.text = property.propertyTitle;
            widget.onPropertyChanged(property);
          },
          loadingBuilder: (context) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          emptyBuilder: (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _controller.text.isEmpty
                  ? 'No properties found for this broker'
                  : 'No properties found matching "${_controller.text}"',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
