import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerWidget extends StatelessWidget {
  final String title;
  final String urlOrPath;
  final bool isOffline;

  const PdfViewerWidget({
    super.key,
    required this.title,
    required this.urlOrPath,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: isOffline
          ? SfPdfViewer.file(File(urlOrPath)) // Loads from Hive's local path
          : SfPdfViewer.network(urlOrPath),   // Streams from the web
    );
  }
}