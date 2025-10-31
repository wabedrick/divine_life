import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class OnlineServicesScreen extends StatefulWidget {
  const OnlineServicesScreen({super.key});

  @override
  State<OnlineServicesScreen> createState() => _OnlineServicesScreenState();
}

class _OnlineServicesScreenState extends State<OnlineServicesScreen> {
  static final Logger _logger = Logger();

  final List<OnlineServiceItem> _services = [
    OnlineServiceItem(
      title: 'YouTube Page',
      description: 'Watch live and archived services on our YouTube channel.',
      icon: Icons.video_library,
      url: 'https://www.youtube.com/@divinelifeministries1807',
      color: Colors.red,
      isLive: true,
      schedule: 'Sundays & Archives',
    ),
    OnlineServiceItem(
      title: 'Zoom Sunday Service',
      description: 'Join our Sunday worship service via Zoom.',
      icon: Icons.videocam,
      url: 'https://us02web.zoom.us/j/81148387755?pwd=L0FhZm1XajVMb1NYc2FqbWZiQjZJZz09',
      color: Colors.blue,
      schedule: 'Sundays 10:00 AM',
    ),
    OnlineServiceItem(
      title: 'Zoom Morning Prayers',
      description: 'Join daily morning prayers via Zoom.',
      icon: Icons.wb_sunny,
      url: 'https://us02web.zoom.us/j/81148387755?pwd=L0FhZm1XajVMb1NYc2FqbWZiQjZJZz09',
      color: Colors.green,
      schedule: 'Daily 4:30 AM – 5:30 AM',
    ),
    OnlineServiceItem(
      title: 'Spirit FM 96.6 Radio Program',
      description: 'Tune in to our radio program on Spirit FM 96.6.',
      icon: Icons.radio,
      url: 'https://spiritfm.co.ug', // Optional: actual program link
      color: Colors.orange,
      schedule: 'Mon–Fri 7:00–7:30 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Online Services'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            actions: [
              if (authProvider.canManageOnlineServices)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showManageServicesDialog(),
                  tooltip: 'Manage Online Services',
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                // Refresh the page
              });
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connect Online',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join us from anywhere in the world. Experience worship, fellowship, and growth through our online services.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.0,
                          crossAxisSpacing: 16.0,
                          childAspectRatio: 0.85,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final service = _services[index];
                      return _buildServiceCard(service);
                    }, childCount: _services.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(OnlineServiceItem service) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _launchUrl(service.url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                service.color.withValues(alpha: 0.1),
                service.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: service.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(service.icon, size: 32, color: service.color),
                  ),
                  if (service.isLive)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  service.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  service.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  service.schedule,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: service.color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.launch,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open $url');
      }
    } catch (e) {
      _logger.e('Error launching URL $url: $e');
      _showErrorSnackBar('Error opening link: $e');
    }
  }

  void _showManageServicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manage Online Services'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(service.icon, color: service.color),
                    title: Text(service.title),
                    subtitle: Text(service.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editService(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteService(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: _addNewService,
              child: const Text('Add Service'),
            ),
          ],
        );
      },
    );
  }

  void _editService(int index) {
    final service = _services[index];
    _showServiceEditDialog(service, index);
  }

  void _addNewService() {
    _showServiceEditDialog(null, null);
  }

  void _showServiceEditDialog(OnlineServiceItem? service, int? index) {
    final titleController = TextEditingController(text: service?.title ?? '');
    final descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    final urlController = TextEditingController(text: service?.url ?? '');
    final scheduleController = TextEditingController(
      text: service?.schedule ?? '',
    );
    IconData selectedIcon = service?.icon ?? Icons.web;
    Color selectedColor = service?.color ?? Colors.blue;
    bool isLive = service?.isLive ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(service == null ? 'Add Service' : 'Edit Service'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: scheduleController,
                        decoration: const InputDecoration(
                          labelText: 'Schedule',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Icon: ${selectedIcon.codePoint}'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _showIconPicker(setDialogState, (icon) {
                                  selectedIcon = icon;
                                }),
                            child: const Text('Choose Icon'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              color: selectedColor,
                              child: const Center(
                                child: Text(
                                  'Color',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () =>
                                _showColorPicker(setDialogState, (color) {
                                  selectedColor = color;
                                }),
                            child: const Text('Choose Color'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Live Service'),
                        value: isLive,
                        onChanged: (value) {
                          setDialogState(() {
                            isLive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newService = OnlineServiceItem(
                      title: titleController.text,
                      description: descriptionController.text,
                      icon: selectedIcon,
                      url: urlController.text,
                      color: selectedColor,
                      isLive: isLive,
                      schedule: scheduleController.text,
                    );

                    setState(() {
                      if (index != null) {
                        _services[index] = newService;
                      } else {
                        _services.add(newService);
                      }
                    });

                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Close manage dialog too
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteService(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Service'),
          content: Text(
            'Are you sure you want to delete "${_services[index].title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _services.removeAt(index);
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close manage dialog too
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showIconPicker(
    StateSetter setDialogState,
    Function(IconData) onIconSelected,
  ) {
    final icons = [
      Icons.live_tv,
      Icons.video_library,
      Icons.favorite,
      Icons.menu_book,
      Icons.groups,
      Icons.podcasts,
      Icons.facebook,
      Icons.web,
      Icons.church,
      Icons.play_circle,
      Icons.music_note,
      Icons.event,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Icon'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onIconSelected(icons[index]);
                    setDialogState(() {});
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icons[index], size: 32),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showColorPicker(
    StateSetter setDialogState,
    Function(Color) onColorSelected,
  ) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Color'),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onColorSelected(colors[index]);
                    setDialogState(() {});
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors[index],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class OnlineServiceItem {
  final String title;
  final String description;
  final IconData icon;
  final String url;
  final Color color;
  final bool isLive;
  final String schedule;

  OnlineServiceItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.url,
    required this.color,
    this.isLive = false,
    required this.schedule,
  });
}
