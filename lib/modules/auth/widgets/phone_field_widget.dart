// File: lib/modules/auth/widgets/phone_field_widget.dart
// Purpose: Phone number text field with country flag picker and inline validation.

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../models/country_code.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../util/common_ext.dart';

class PhoneFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<CountryCode> onCountryChanged;
  final CountryCode initialCountry;

  const PhoneFieldWidget({
    super.key,
    required this.controller,
    required this.onCountryChanged,
    required this.initialCountry,
  });

  @override
  State<PhoneFieldWidget> createState() => _PhoneFieldWidgetState();
}

class _PhoneFieldWidgetState extends State<PhoneFieldWidget> {
  late CountryCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: 'Phone Number',
      hint: '99999 88888',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      prefixIcon: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          bottomLeft: Radius.circular(8.0),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<CountryCode>(
            value: _selectedCountry,
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.iconDefault,
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            selectedItemBuilder: (BuildContext context) {
              return CountryCode.countries.map<Widget>((CountryCode c) {
                return Center(
                  child: Text(
                    '${c.flag} ${c.code}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList();
            },
            items: CountryCode.countries.map((CountryCode c) {
              return DropdownMenuItem<CountryCode>(
                value: c,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.flag, style: const TextStyle(fontSize: 18.0)),
                    const SizedBox(width: 8.0),
                    Text(
                      c.code,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (CountryCode? newCountry) {
              if (newCountry != null) {
                setState(() {
                  _selectedCountry = newCountry;
                });
                widget.onCountryChanged(newCountry);
              }
            },
          ),
        ),
      ),
      validator: (val) {
        if (val.isEmptyORNull) {
          return 'Phone number is required';
        }
        // Remove spaces/dashes/parentheses for validation
        final cleanVal = val!.replaceAll(RegExp(r'\D'), '');
        if (cleanVal.length < _selectedCountry.minLength ||
            cleanVal.length > _selectedCountry.maxLength) {
          return 'Enter a valid ${_selectedCountry.minLength}-digit phone number';
        }
        if (!_selectedCountry.validationPattern.hasMatch(cleanVal)) {
          return 'Invalid phone number format for ${_selectedCountry.name}';
        }
        return null;
      },
    );
  }
}
