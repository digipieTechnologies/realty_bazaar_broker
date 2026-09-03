import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_navigator.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/extensions/currency_extensions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/models.dart';
import '../../../providers/visit/visit_provider.dart';
import '../../../util/app_date_utils.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/user_avatar_widget.dart';
import '../../../widgets/images/cached_image.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/cancel_visit_dialog.dart';
import '../widgets/reschedule_visit_dialog.dart';
import '../widgets/visit_history_timeline.dart';
import '../widgets/visit_status_badge.dart';

class ViewVisitScreen extends StatefulWidget {
  final PropertyVisitModel? visit;
  final String? visitId;

  const ViewVisitScreen({super.key, this.visit, this.visitId});

  @override
  State<ViewVisitScreen> createState() => _ViewVisitScreenState();
}

class _ViewVisitScreenState extends State<ViewVisitScreen> {
  PropertyVisitModel? _visit;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.visit != null) {
      _visit = widget.visit;
      // Also fetch fresh copy in background to ensure history is updated
      if (widget.visit?.id != null) {
        _fetchVisit(widget.visit!.id!, isSilent: true);
      }
    } else if (widget.visitId != null && widget.visitId!.isNotEmpty) {
      _isLoading = true;
      _fetchVisit(widget.visitId!);
    }
  }

  @override
  void didUpdateWidget(covariant ViewVisitScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visit != oldWidget.visit && widget.visit != null) {
      _visit = widget.visit;
    }
  }

  Future<void> _fetchVisit(String id, {bool isSilent = false}) async {
    if (!isSilent) {
      setState(() => _isLoading = true);
    }
    try {
      final provider = context.read<VisitProvider>();
      final fetched = await provider.fetchVisitById(id);
      if (mounted) {
        setState(() {
          if (fetched != null) {
            _visit = fetched;
          }
          _isLoading = false;
          if (fetched == null && !isSilent && _visit == null) {
            _errorMessage = 'Visit details not found.';
          }
        });
      }
    } catch (e) {
      if (mounted && !isSilent) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading visit details.';
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[ViewVisitScreen] Error launching url: $e');
    }
  }

  void _handleShare(PropertyVisitModel visit) {
    final propName = visit.property?.propertyTitle ?? 'Property';
    final dateStr = AppDateUtils.formatDate(visit.visitDate);
    final text =
        'Site Visit for $propName with ${visit.clientName} scheduled on $dateStr (${visit.timeSlot}). Contact: ${visit.contactNumber}';
    Clipboard.setData(ClipboardData(text: text));
    AppToast.showSuccess(context.tr('site_visits'), 'Visit details copied to clipboard');
  }

  Future<void> _handleStatusUpdate(String newStatus) async {
    final targetId = _visit?.id ?? widget.visitId;
    if (targetId == null) return;
    try {
      final updated = await context.read<VisitProvider>().updateVisitStatus(
        visitId: targetId,
        newStatus: newStatus,
      );
      if (mounted) {
        setState(() => _visit = updated);
        AppToast.showSuccess(context.tr('site_visits'), context.tr('visit_status_updated_success'));
        _fetchVisit(targetId, isSilent: true);
      }
    } catch (e) {
      if (mounted) AppToast.showError('Error', e.toString());
    }
  }

  Future<void> _handleReschedule() async {
    final target = _visit;
    if (target == null) return;
    final updated = await showDialog<PropertyVisitModel>(
      context: context,
      builder: (context) => RescheduleVisitDialog(visit: target),
    );
    if (updated != null && mounted) {
      setState(() => _visit = updated);
      if (updated.id != null) {
        _fetchVisit(updated.id!, isSilent: true);
      }
    }
  }

  Future<void> _handleCancel() async {
    final target = _visit;
    if (target == null) return;
    final updated = await showDialog<PropertyVisitModel>(
      context: context,
      builder: (context) => CancelVisitDialog(visit: target),
    );
    if (updated != null && mounted) {
      setState(() => _visit = updated);
      if (updated.id != null) {
        _fetchVisit(updated.id!, isSilent: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(title: context.tr('visit_details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final provider = context.watch<VisitProvider>();
    final targetId = _visit?.id ?? widget.visitId;
    PropertyVisitModel? liveVisit;
    if (targetId != null) {
      for (final v in provider.visits) {
        if (v.id == targetId) {
          liveVisit = v;
          break;
        }
      }
    }
    final visit = liveVisit ?? _visit;

    if (_errorMessage != null || visit == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(title: context.tr('visit_details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Visit details not found.', style: AppTextStyles.body1),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final property = visit.property;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(title: context.tr('visit_details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            final clientCard = _buildClientHeroCard(visit);
            final scheduleCard = _buildScheduleCard(visit);
            final propertyCard = property != null ? _buildPropertyCard(property) : null;
            final timelineCard = VisitHistoryTimelineWidget(history: visit.history);

            if (isDesktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Client Info, Schedule & Actions, Timeline
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            clientCard,
                            const SizedBox(height: 20.0),
                            scheduleCard,
                            const SizedBox(height: 20.0),
                            timelineCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24.0),
                      // Right Column: Property Card
                      if (propertyCard != null) Expanded(flex: 4, child: propertyCard),
                    ],
                  ),
                ),
              );
            } else {
              // Mobile Layout: Stacked
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  clientCard,
                  const SizedBox(height: 16.0),
                  scheduleCard,
                  if (propertyCard != null) ...[const SizedBox(height: 16.0), propertyCard],
                  const SizedBox(height: 16.0),
                  timelineCard,
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildClientHeroCard(PropertyVisitModel visit) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20.0),

            child: Row(
              children: [
                UserAvatarWidget(name: visit.clientName, radius: 28.0),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.clientName,
                        style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4.0),
                      Text(visit.contactNumber, style: AppTextStyles.body2.copyWith()),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20.0),
                  onPressed: () => _handleShare(visit),
                  tooltip: 'Share',
                ),
              ],
            ),
          ),

          // Action buttons: WhatsApp & Call
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'WhatsApp',
                    icon: SvgPicture.asset(
                      'assets/icons/ic_whatsapp.svg',
                      width: 20.0,
                      height: 20.0,
                      colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                    ),
                    color: const Color(0xFF16A34A),
                    onPressed: () => _launchUrl(visit.buildWhatsappUrl()),
                    height: 44.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: AppButton(
                    text: 'Call Client',
                    icon: SvgPicture.asset(
                      'assets/icons/ic_call.svg',
                      width: 20.0,
                      height: 20.0,
                      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    ),
                    variant: AppButtonVariant.outline,
                    onPressed: () => _launchUrl('tel:${visit.clientPhone}'),
                    height: 44.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(PropertyVisitModel visit) {
    final dateStr = AppDateUtils.formatDate(visit.visitDate);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VISIT DETAILS',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              VisitStatusBadge(status: visit.status),
            ],
          ),
          const SizedBox(height: 16.0),

          // Date & Slot details
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('preferred_date'),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16.0, color: AppColors.primary),
                          const SizedBox(width: 6.0),
                          Text(dateStr, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1.0, height: 40.0, color: AppColors.border),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('preferred_time_slot'),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16.0, color: AppColors.primary),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              visit.timeSlot,
                              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (visit.rescheduleCount > 0) ...[
            const SizedBox(height: 12.0),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16.0, color: Color(0xFF7E22CE)),
                const SizedBox(width: 6.0),
                Text(
                  context.tr(
                    'reschedule_count_label',
                    arguments: {'count': visit.rescheduleCount.toString()},
                  ),
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF7E22CE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (visit.rescheduleReason != null && visit.rescheduleReason!.isNotEmpty) ...[
                  const SizedBox(width: 6.0),
                  Flexible(
                    child: Text(
                      '("${visit.rescheduleReason}")',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],

          if (visit.notes != null && visit.notes!.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Text(
              'Notes / Client Remarks',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(visit.notes!, style: AppTextStyles.body2),
          ],
          const SizedBox(height: 20.0),

          // Action Buttons according to current status
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              if (visit.isPending)
                AppButton(
                  text: context.tr('confirm_visit'),
                  iconData: Icons.check_circle_outline,
                  color: const Color(0xFF0369A1),
                  onPressed: () => _handleStatusUpdate('confirmed'),
                ),
              if (!visit.isCompleted && !visit.isCancelled) ...[
                AppButton(
                  text: context.tr('reschedule_site_visit'),
                  iconData: Icons.update_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: _handleReschedule,
                ),
                AppButton(
                  text: context.tr('mark_completed'),
                  iconData: Icons.task_alt_rounded,
                  color: const Color(0xFF15803D),
                  onPressed: () => _handleStatusUpdate('completed'),
                ),
                AppButton(
                  text: context.tr('mark_no_show'),
                  iconData: Icons.person_off_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _handleStatusUpdate('no_show'),
                ),
                AppButton(
                  text: context.tr('cancel_visit'),
                  iconData: Icons.cancel_outlined,
                  variant: AppButtonVariant.danger,
                  onPressed: _handleCancel,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    final media = property.medias;
    final coverUrl = media.isNotEmpty ? media.first.url : null;
    final city = property.address?.city ?? '';
    final fullAddr = property.address?.fullAddress ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
              child: CachedImage(coverUrl, height: 180.0, width: double.infinity, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      property.price.toCompactCurrency(),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (property.bedrooms > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '${property.bedrooms} BHK',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  property.propertyTitle,
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fullAddr.isNotEmpty || city.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14.0, color: AppColors.textSecondary),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          fullAddr.isNotEmpty ? fullAddr : city,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16.0),
                AppButton(
                  text: 'View Property Details',
                  variant: AppButtonVariant.outline,
                  width: double.infinity,
                  onPressed: () {
                    AppNavigator.navigateToPropertyDetails(context, property);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
