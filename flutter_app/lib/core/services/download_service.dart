import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// use simple path concatenation to avoid adding an extra dependency
import 'package:path_provider/path_provider.dart';

class DownloadItem {
  final String id;
  final String url;
  final String filename;
  int progress; // 0-100
  String? savedPath;
  bool completed;

  DownloadItem({
    required this.id,
    required this.url,
    required this.filename,
    this.progress = 0,
    this.savedPath,
    this.completed = false,
  });
}

class DownloadService extends ChangeNotifier {
  final Dio _dio = Dio();
  final Map<String, DownloadItem> _downloads = {};

  List<DownloadItem> get downloads => _downloads.values.toList();

  DownloadItem? getById(String id) => _downloads[id];

  Future<DownloadItem> startDownload(String url, String filename) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = DownloadItem(id: id, url: url, filename: filename);
    _downloads[id] = item;
    notifyListeners();

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docsDir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final safeName = filename.replaceAll(RegExp(r"[^0-9A-Za-z. _-]"), '_');
      final savePath = '${downloadsDir.path}/$safeName';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          final prog = total > 0 ? ((received / total) * 100).round() : 0;
          item.progress = prog.clamp(0, 100);
          notifyListeners();
        },
        // Dio v5 expects a Duration for timeouts; use zero duration for no timeout
        options: Options(receiveTimeout: Duration.zero),
      );

      item.savedPath = savePath;
      item.completed = true;
      item.progress = 100;
      notifyListeners();
      return item;
    } catch (e) {
      // mark as failed (progress -1)
      item.progress = -1;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeDownload(String id) async {
    final item = _downloads[id];
    if (item != null) {
      if (item.savedPath != null) {
        try {
          final f = File(item.savedPath!);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }
      _downloads.remove(id);
      notifyListeners();
    }
  }
}
