// File: lib/widgets/dialogs/app_file_preview_dialog.dart
// Purpose: Full-screen file preview modal supporting image zoom, text/CSV/SQL preview, video/document viewing, and browser launching.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_realty_bazaar/widgets/buttons/app_button.dart';

import '../../app/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/common_ext.dart';
import '../../app/app_utils.dart';
import '../images/cached_image.dart';
import '../toast/app_toast.dart';

class AppFilePreviewDialog extends StatefulWidget {
  final String? fileUrl;
  final String? filePath;
  final String fileName;

  const AppFilePreviewDialog({super.key, this.fileUrl, this.filePath, required this.fileName});

  static Future<void> show(BuildContext context, {String? fileUrl, String? filePath, required String fileName}) {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => AppFilePreviewDialog(fileUrl: fileUrl, filePath: filePath, fileName: fileName),
    );
  }

  @override
  State<AppFilePreviewDialog> createState() => _AppFilePreviewDialogState();
}

class _AppFilePreviewDialogState extends State<AppFilePreviewDialog> {
  bool _isLoadingContent = false;
  String? _textContent;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAndLoadTextContent();
  }

  bool get _isTextBasedFile {
    final name = widget.fileName;
    return name.isCsvUrl ||
        name.isSqlUrl ||
        ['txt', 'json', 'xml', 'md', 'log', 'yaml', 'yml'].contains(name.fileExtension);
  }

  Future<void> _checkAndLoadTextContent() async {
    if (!_isTextBasedFile) return;

    setState(() {
      _isLoadingContent = true;
      _errorMessage = null;
    });

    try {
      if (widget.filePath != null && File(widget.filePath!).existsSync()) {
        final content = await File(widget.filePath!).readAsString();
        if (mounted) {
          setState(() {
            _textContent = content;
            _isLoadingContent = false;
          });
        }
        return;
      }

      if (widget.fileUrl != null && widget.fileUrl!.isNotEmpty) {
        final response = await Dio().get<String>(widget.fileUrl!, options: Options(responseType: ResponseType.plain));
        if (mounted) {
          setState(() {
            _textContent = response.data;
            _isLoadingContent = false;
          });
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load inline file preview.';
          _isLoadingContent = false;
        });
      }
    }
  }

  Future<void> _openExternal() async {
    final targetUrl = widget.fileUrl ?? widget.filePath;
    if (targetUrl != null && targetUrl.isNotEmpty) {
      await AppUtils.launchAppUrl(targetUrl);
    } else {
      AppToast.showError('Preview', 'No valid file link or path available.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = widget.fileName.fileExtension.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.fileName,
              style: const TextStyle(color: Colors.white, fontSize: 15.0, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.fileName.fileTypeLabel,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.0),
            ),
          ],
        ),
        actions: [
          if (_textContent != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white),
              tooltip: 'Copy File Content',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _textContent!));
                AppToast.showSuccess('Copied', 'File text content copied to clipboard.');
              },
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
            tooltip: 'Open / Download',
            onPressed: _openExternal,
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(child: Center(child: _buildBody(ext))),
    );
  }

  Widget _buildBody(String ext) {
    // 1. Image Preview
    if (widget.fileName.isImageUrl) {
      final imageSource = widget.fileUrl ?? widget.filePath;
      if (imageSource == null || imageSource.isEmpty) {
        return Center(
          child: Text(context.tr('image_path_missing'), style: const TextStyle(color: Colors.white)),
        );
      }
      return InteractiveViewer(
        maxScale: 5.0,
        child: CachedImage(imageSource, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
      );
    }

    // 2. Text / CSV / SQL Content Preview
    if (_isTextBasedFile) {
      if (_isLoadingContent) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16.0),
            Text(context.tr('loading_preview').replaceAll('{ext}', ext), style: const TextStyle(color: Colors.white70)),
          ],
        );
      }

      if (_textContent != null && _textContent!.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.darkCanvas,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      ext,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.0),
                    ),
                  ),
                  Text(
                    '${_textContent!.length} characters',
                    style: const TextStyle(color: Colors.white54, fontSize: 12.0),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24.0),
              Expanded(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      _textContent!,
                      style: const TextStyle(
                        color: AppColors.darkCanvasLight,
                        fontFamily: 'monospace',
                        fontSize: 13.0,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // 3. Fallback Document Card View
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(
              widget.fileName.isCsvUrl
                  ? Icons.table_chart_rounded
                  : (widget.fileName.isSqlUrl
                        ? Icons.code_rounded
                        : (widget.fileName.isPdfUrl ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded)),
              size: 64.0,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24.0),
          Text(
            widget.fileName,
            style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.fileName.fileTypeLabel,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13.0),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12.0),
            Text(_errorMessage!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12.0)),
          ],
          const SizedBox(height: 32.0),
          AppButton.solid(
            text: context.tr('open_download_file').replaceAll('{ext}', ext),
            iconData: Icons.file_download_rounded,
            height: 48.0,
            borderRadius: 10.0,
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            onPressed: _openExternal,
          ),
        ],
      ),
    );
  }
}
