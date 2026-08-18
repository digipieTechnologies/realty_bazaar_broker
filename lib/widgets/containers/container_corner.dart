// File: lib/widgets/containers/container_corner.dart
// Purpose: Reference layout container supporting gradients, borders, shadows, and click responses.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ContainerCorner extends StatelessWidget {
  final void Function()? onTap;
  final Function? onDoubleTap;
  final Function? onLongPress;
  final Function? onLongPressEnd;
  final Widget? child;
  final Color? color;
  final Color? shadowColor;
  final List<Color> colors;
  final Color? borderColor;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final double? borderWidth;
  final double? width;
  final double? height;
  final double? borderRadius;
  final double? marginAll;
  final Alignment? alignment;
  final double? marginTop;
  final double? marginLeft;
  final double? marginRight;
  final double? marginBottom;
  final double? radiusTopRight;
  final double? radiusBottomRight;
  final double? radiusTopLeft;
  final double? radiusBottomLeft;
  final double? blurRadius;
  final double? spreadRadius;
  final bool? setShadowToBottom;
  final double? shadowColorOpacity;
  final double? imageOpacity;
  final String? imageDecoration;
  final EdgeInsets? padding;
  final List<double>? steps;
  final String? tooltip;
  final BorderRadius? borderRadiusShape;

  const ContainerCorner({
    super.key,
    this.child,
    this.alignment,
    this.marginAll,
    this.marginTop = 0,
    this.marginLeft = 0,
    this.marginRight = 0,
    this.marginBottom = 0,
    this.imageDecoration,
    this.width,
    this.height,
    this.color,
    this.colors = const [Colors.transparent, Colors.transparent],
    this.shadowColor,
    this.borderColor = Colors.transparent,
    this.borderRadius,
    this.radiusTopRight = 0,
    this.radiusBottomRight = 0,
    this.radiusTopLeft = 0,
    this.radiusBottomLeft = 0,
    this.borderWidth = 1,
    this.blurRadius = 2,
    this.spreadRadius = 1,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    this.borderRadiusShape,
    this.setShadowToBottom = false,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressEnd,
    this.imageOpacity = 1,
    this.shadowColorOpacity = 1,
    this.padding,
    this.steps,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topRight: Radius.circular(
        borderRadius != null ? borderRadius! : radiusTopRight!,
      ),
      bottomRight: Radius.circular(
        borderRadius != null ? borderRadius! : radiusBottomRight!,
      ),
      topLeft: Radius.circular(
        borderRadius != null ? borderRadius! : radiusTopLeft!,
      ),
      bottomLeft: Radius.circular(
        borderRadius != null ? borderRadius! : radiusBottomLeft!,
      ),
    );

    Widget normalChild = Container(
      padding: padding,
      height: height,
      width: width,
      alignment: alignment,
      margin: EdgeInsets.only(
        left: marginAll != null ? marginAll! : marginLeft!,
        top: marginAll != null ? marginAll! : marginTop!,
        bottom: marginAll != null ? marginAll! : marginBottom!,
        right: marginAll != null ? marginAll! : marginRight!,
      ),
      decoration: BoxDecoration(
        image: imageDecoration != null
            ? DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage(imageDecoration!),
                opacity: imageOpacity ?? 1.0,
              )
            : null,
        color: color,
        gradient: color != null
            ? null
            : LinearGradient(
                colors: colors,
                begin: begin,
                end: end,
                stops: steps ?? const [0.0, 1.0],
                tileMode: TileMode.clamp,
              ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: shadowColor != null
                ? shadowColor!.withOpacity(shadowColorOpacity!)
                : Colors.transparent,
            blurRadius: blurRadius!,
            spreadRadius: spreadRadius!,
            offset: setShadowToBottom!
                ? const Offset(0, 2)
                : const Offset(0.0, 0.75),
          ),
        ],
        borderRadius: borderRadiusShape ?? radius,
        border: Border.all(
          width: borderColor != Colors.transparent ? borderWidth! : 0,
          color: borderColor ?? Colors.transparent,
        ),
      ),
      child: child,
    );

    if (onTap != null || onDoubleTap != null || onLongPress != null) {
      final kChild = GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap as void Function()?,
        onLongPress: onLongPress as void Function()?,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: normalChild,
        ),
      );
      normalChild = kChild;
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip, child: normalChild);
    }

    return normalChild;
  }
}
