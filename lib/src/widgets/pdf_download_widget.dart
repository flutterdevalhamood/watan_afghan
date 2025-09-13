// // Create a new file: lib/src/widgets/pdf_download_helper.dart
//
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class PdfDownloadHelper {
//   static Future<String?> downloadAndOpenPdf({
//     required String url,
//     required String reportType, // 'sales' or 'purchase'
//     required BuildContext context,
//   }) async {
//     try {
//       // Request storage permission
//       final status = await Permission.storage.request();
//       if (!status.isGranted) {
//         throw Exception('Storage permission denied');
//       }
//
//       // Get app directory for saving PDF
//       final dir = await getApplicationDocumentsDirectory();
//       final filePath =
//           '${dir.path}/${reportType}_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
//
//       // Download the PDF using Dio
//       final dio = Dio();
//       await dio.download(url, filePath);
//
//       return filePath;
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error downloading PDF: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       return null;
//     }
//   }
// }

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfDownloadHelper {
  static Future<String?> downloadAndOpenPdf({
    required String url,
    required String reportType,
    required context,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // ✅ Save inside app documents directory
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$reportType-report.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath; // return path for PDFView
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
