// File: lib/modules/dashboard/widgets/grow_plan_carousel_widget.dart
// Purpose: Responsive carousel/grid layout for plan cards.
// Mobile & Tablet: carousel_slider with center-focused popular plan, indicators at bottom.
// Desktop: Full horizontal row of plan cards.

// ignore_for_file: deprecated_member_use

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../models/models.dart';
import 'grow_plan_card_widget.dart';

class GrowPlanCarouselWidget extends StatefulWidget {
  final List<SubscriptionPlanModel> plans;
  final Function(SubscriptionPlanModel)? onSelectPlan;

  const GrowPlanCarouselWidget({
    super.key,
    required this.plans,
    this.onSelectPlan,
  });

  @override
  State<GrowPlanCarouselWidget> createState() => _GrowPlanCarouselWidgetState();
}

class _GrowPlanCarouselWidgetState extends State<GrowPlanCarouselWidget> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    // Default to popular plan index
    final popularIndex =
        widget.plans.indexWhere((p) => p.isPopular);
    if (popularIndex != -1) {
      _currentIndex = popularIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final int planCount = widget.plans.length;
        // Minimum width required to show all cards side-by-side cleanly without squishing
        final double minWidthForStaticRow = (planCount * 250.0) + (14.0 * (planCount - 1));

        if (maxWidth < minWidthForStaticRow) {
          return _buildCarouselLayout(maxWidth: maxWidth);
        }

        return _buildDesktopLayout(maxWidth);
      },
    );
  }

  Widget _buildCarouselLayout({required double maxWidth}) {
    final bool isMobile = maxWidth < 600;
    final bool isTablet = maxWidth >= 600 && maxWidth < 950;
    
    // Smooth viewportFraction based on available screen width
    double viewportFraction = 0.82;
    if (isTablet) {
      viewportFraction = 0.46;
    } else if (!isMobile) {
      viewportFraction = 0.32;
    }

    final double cardHeight = isMobile ? 500.0 : 520.0;

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.plans.length,
            options: CarouselOptions(
              height: cardHeight,
              viewportFraction: viewportFraction,
              enlargeCenterPage: true,
              enlargeFactor: 0.18,
              enlargeStrategy: CenterPageEnlargeStrategy.zoom,
              initialPage: _currentIndex,
              enableInfiniteScroll: false,
              padEnds: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              return GrowPlanCardWidget(
                plan: widget.plans[index],
                onSelect: widget.onSelectPlan != null
                    ? () => widget.onSelectPlan!(widget.plans[index])
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 14.0),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildDesktopLayout(double maxWidth) {
    const double spacing = 12.0;
    const double horizontalPadding = 24.0; // 20-30px padding range

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.plans.length, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < widget.plans.length - 1 ? spacing : 0,
              ),
              child: SizedBox(
                height: 520.0,
                child: GrowPlanCardWidget(
                  plan: widget.plans[index],
                  cardWidth: double.infinity,
                  onSelect: widget.onSelectPlan != null
                      ? () => widget.onSelectPlan!(widget.plans[index])
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.plans.length, (index) {
        final bool isActive = index == _currentIndex;
        return GestureDetector(
          onTap: () {
            _carouselController.animateToPage(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: isActive ? 28.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: isActive
                  ? AppColors.primary
                  : AppColors.border,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
