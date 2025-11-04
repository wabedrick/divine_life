import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/services/download_service.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: Consumer<DownloadService>(
        builder: (context, ds, child) {
          final items = ds.downloads;
          if (items.isEmpty) {
            return const Center(child: Text('No downloads yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final it = items[index];
              return ListTile(
                leading: Icon(
                  it.completed ? Icons.check_circle : Icons.downloading,
                  color: it.completed ? Colors.green : Colors.orange,
                ),
                title: Text(it.filename),
                subtitle: it.progress >= 0
                    ? Text(
                        it.completed
                            ? 'Saved: ${it.savedPath}'
                            : 'Downloading: ${it.progress}%',
                      )
                    : const Text('Failed'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (it.savedPath != null)
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () async {
                          await OpenFile.open(it.savedPath!);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ds.removeDownload(it.id);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Download removed')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
