// File: lib/modules/chat/widgets/message_type/file_message_widget.dart
// Purpose: Document and file attachment message bubble component featuring extension badge box, filename, preview action (eye icon), and download action.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/utils/common_ext.dart';
import '../../../../util/app_utils.dart';
import '../../../../widgets/dialogs/app_file_preview_dialog.dart';

class FileMessageWidget extends StatelessWidget {
  final String mediaUrl;
  final String? fileName;
  final String? fileSize;
  final bool isMe;

  const FileMessageWidget({
    super.key,
    required this.mediaUrl,
    this.fileName,
    this.fileSize,
    required this.isMe,
  });

  IconData _getFileIcon(String ext) {
    if (mediaUrl.isCsvUrl || ext == 'csv' || ext == 'tsv') {
      return Icons.table_chart_rounded;
    } else if (mediaUrl.isSqlUrl || ext == 'sql') {
      return Icons.code_rounded;
    } else if (mediaUrl.isPdfUrl || ext == 'pdf') {
      return Icons.picture_as_pdf_rounded;
    } else if (mediaUrl.isExcelUrl || ext == 'xls' || ext == 'xlsx') {
      return Icons.table_view_rounded;
    } else if (mediaUrl.isDocUrl || ext == 'doc' || ext == 'docx') {
      return Icons.description_rounded;
    } else if (mediaUrl.isArchiveUrl || ext == 'zip' || ext == 'rar') {
      return Icons.folder_zip_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final rawName = (fileName != null && fileName!.trim().isNotEmpty)
        ? fileName!
        : mediaUrl.fileNameFromUrl;
    final name = rawName.isNotEmpty ? rawName : 'Attachment';
    final ext = name.fileExtension.isNotEmpty ? name.fileExtension.toLowerCase() : 'file';
    final extLabel = ext.toUpperCase();
    final fileIcon = _getFileIcon(ext);
    final typeSubtitle = fileSize ?? name.fileTypeLabel;

    final Color badgeBg = isMe
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFFE8F1FF);
    final Color badgeIconColor = isMe ? Colors.white : AppColors.primary;
    final Color textColor = isMe ? Colors.white : AppColors.textPrimary;
    final Color subtitleColor = isMe ? Colors.white.withValues(alpha: 0.8) : AppColors.textMuted;
    final Color actionIconColor = isMe ? Colors.white : AppColors.primary;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isMe
              ? Colors.white.withValues(alpha: 0.2)
              : const Color(0xFFE1E8F0),
        ),
      ),
      child: Row(
        children: [
          /// Left File Extension Badge Container
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  fileIcon,
                  color: badgeIconColor,
                  size: 20.0,
                ),
                const SizedBox(height: 2.0),
                Text(
                  extLabel,
                  style: TextStyle(
                    color: badgeIconColor,
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),

          /// Middle File Information Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body1.copyWith(
                    fontSize: 13.0,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),
                Text(
                  typeSubtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.0,
                    color: subtitleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6.0),

          /// Right Action Icon: Eye Preview Icon
          InkWell(
            borderRadius: BorderRadius.circular(20.0),
            onTap: () {
              AppFilePreviewDialog.show(
                context,
                fileUrl: mediaUrl,
                fileName: name,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                Icons.visibility_outlined,
                color: actionIconColor,
                size: 20.0,
              ),
            ),
          ),

          /// Right Action Icon: Download / External Launch Icon
          InkWell(
            borderRadius: BorderRadius.circular(20.0),
            onTap: () => AppUtils.launchAppUrl(mediaUrl),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                Icons.file_download_outlined,
                color: actionIconColor,
                size: 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
