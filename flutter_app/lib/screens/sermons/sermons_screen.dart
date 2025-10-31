import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import '../../core/models/sermon.dart';
import '../../core/models/social_media_post.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/sermon_service.dart';

class SermonsScreen extends StatefulWidget {
  const SermonsScreen({super.key});

  @override
  State<SermonsScreen> createState() => _SermonsScreenState();
}

class _SermonsScreenState extends State<SermonsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_SermonsTabState> _sermonsTabKey = GlobalKey();
  final GlobalKey<_SocialMediaTabState> _socialMediaTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sermons & Media'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.play_circle_outline),
                  text: 'YouTube Sermons',
                ),
                Tab(icon: Icon(Icons.share), text: 'Social Media'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              SermonsTab(key: _sermonsTabKey),
              SocialMediaTab(key: _socialMediaTabKey),
            ],
          ),
          floatingActionButton: authProvider.canManageSermons
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddContentDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Content'),
                )
              : null,
        );
      },
    );
  }

  void _showAddContentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddContentDialog(
        onContentAdded: () {
          // Refresh both tabs content
          _sermonsTabKey.currentState?._loadInitialData();
          _socialMediaTabKey.currentState?._loadInitialData();
        },
      ),
    );
  }
}

class SermonsTab extends StatefulWidget {
  const SermonsTab({super.key});

  @override
  State<SermonsTab> createState() => _SermonsTabState();
}

class _SermonsTabState extends State<SermonsTab> {
  static final Logger _logger = Logger();
  final TextEditingController _searchController = TextEditingController();
  List<Sermon> _sermons = [];
  List<Sermon> _featuredSermons = [];
  Map<String, String> _categories = {};
  bool _isLoading = true;
  bool _isSearching = false;
  String? _selectedCategory;
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _logger.d('🚀 SermonsScreen: Starting to load initial data...');
      setState(() => _isLoading = true);

      // Make API calls separately to handle different return types
      final sermonsDataFuture = SermonService.getSermons(page: 1, perPage: 10);
      final featuredSermonsFuture = SermonService.getFeaturedSermons(limit: 5);
      final categoriesFuture = SermonService.getSermonCategories();

      final sermonsData = await sermonsDataFuture;
      final featuredSermons = await featuredSermonsFuture;
      final categories = await categoriesFuture;

      _logger.d('✅ SermonsScreen: All API calls completed successfully');

      if (mounted) {
        _logger.d('📊 SermonsScreen: Processing response data...');
        _logger.d(
          '   - Sermons count: ${(sermonsData['sermons'] as List<Sermon>).length}',
        );
        _logger.d('   - Featured sermons count: ${featuredSermons.length}');
        _logger.d('   - Categories count: ${categories.length}');

        setState(() {
          _sermons = sermonsData['sermons'] as List<Sermon>;
          _featuredSermons = featuredSermons;
          _categories = categories;

          final pagination = sermonsData['pagination'] as Map<String, dynamic>;
          _hasMorePages = pagination['current_page'] < pagination['last_page'];
          _isLoading = false;
        });

        _logger.d('✅ SermonsScreen: State updated successfully');
        _logger.d('   - _sermons.length: ${_sermons.length}');
        _logger.d('   - _featuredSermons.length: ${_featuredSermons.length}');
      }
    } catch (e) {
      _logger.e('❌ SermonsScreen: Error loading initial data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load sermons: $e');
      }
    }
  }

  Future<void> _searchSermons() async {
    try {
      setState(() {
        _isSearching = true;
        _currentPage = 1;
      });

      final result = await SermonService.getSermons(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        page: 1,
        perPage: 20,
      );

      if (mounted) {
        setState(() {
          _sermons = result['sermons'] as List<Sermon>;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMorePages = pagination['current_page'] < pagination['last_page'];
          _currentPage = pagination['current_page'];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        _showErrorSnackBar('Search failed: $e');
      }
    }
  }

  Future<void> _loadMoreSermons() async {
    if (!_hasMorePages || _isSearching) return;

    try {
      final result = await SermonService.getSermons(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        page: _currentPage + 1,
        perPage: 20,
      );

      if (mounted) {
        setState(() {
          _sermons.addAll(result['sermons'] as List<Sermon>);
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMorePages = pagination['current_page'] < pagination['last_page'];
          _currentPage = pagination['current_page'];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load more sermons: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search sermons, speakers, topics...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _searchSermons();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onSubmitted: (value) => _searchSermons(),
              ),

              const SizedBox(height: 12),

              // Category Filter
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.entries.map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                        _searchSermons();
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchSermons,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Featured Sermons Section
                if (_featuredSermons.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Featured Sermons',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredSermons.length,
                      itemBuilder: (context, index) {
                        final sermon = _featuredSermons[index];
                        return Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildFeaturedSermonCard(sermon),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  Divider(),

                  const SizedBox(height: 16),
                ],

                // All Sermons Section
                Row(
                  children: [
                    const Icon(Icons.play_circle_outline),
                    const SizedBox(width: 8),
                    Text(
                      'All Sermons',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sermons List
                if (_sermons.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No sermons found matching your criteria.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...List.generate(_sermons.length, (index) {
                    final sermon = _sermons[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildSermonCard(sermon),
                    );
                  }),

                // Load More Button
                if (_hasMorePages)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _loadMoreSermons,
                        child: const Text('Load More'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSermonCard(Sermon sermon) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launchUrl(sermon.youtubeUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(sermon.youtubeThumbnail),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sermon.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (sermon.speaker != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By ${sermon.speaker}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    sermon.formattedDate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonCard(Sermon sermon) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launchUrl(sermon.youtubeUrl),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 120,
              height: 90,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(sermon.youtubeThumbnail),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sermon.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sermon.isFeatured)
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          sermon.speaker ?? 'Unknown Speaker',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sermon.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),

                        if (sermon.durationSeconds != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sermon.formattedDuration,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sermon.categoryDisplayName,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Spacer(),

                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${sermon.viewCount} views',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialMediaTab extends StatefulWidget {
  const SocialMediaTab({super.key});

  @override
  State<SocialMediaTab> createState() => _SocialMediaTabState();
}

class _SocialMediaTabState extends State<SocialMediaTab> {
  final TextEditingController _searchController = TextEditingController();
  List<SocialMediaPost> _posts = [];
  List<SocialMediaPost> _featuredPosts = [];
  Map<String, String> _platforms = {};
  bool _isLoading = true;
  bool _isSearching = false;
  String? _selectedPlatform;
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      // Make API calls separately to handle different return types
      final postsDataFuture = SermonService.getSocialMediaPosts(
        page: 1,
        perPage: 10,
      );
      final featuredPostsFuture = SermonService.getFeaturedSocialMediaPosts(
        limit: 5,
      );
      final platformsFuture = SermonService.getSocialMediaPlatforms();

      final postsData = await postsDataFuture;
      final featuredPosts = await featuredPostsFuture;
      final platforms = await platformsFuture;

      if (mounted) {
        setState(() {
          _posts = postsData['posts'] as List<SocialMediaPost>;
          _featuredPosts = featuredPosts;
          _platforms = platforms;

          final pagination = postsData['pagination'] as Map<String, dynamic>;
          _hasMorePages = pagination['current_page'] < pagination['last_page'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load social media posts: $e');
      }
    }
  }

  Future<void> _searchPosts() async {
    try {
      setState(() {
        _isSearching = true;
        _currentPage = 1;
      });

      final result = await SermonService.getSocialMediaPosts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        platform: _selectedPlatform,
        page: 1,
        perPage: 20,
      );

      if (mounted) {
        setState(() {
          _posts = result['posts'] as List<SocialMediaPost>;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMorePages = pagination['current_page'] < pagination['last_page'];
          _currentPage = pagination['current_page'];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        _showErrorSnackBar('Search failed: $e');
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMorePages || _isSearching) return;

    try {
      final result = await SermonService.getSocialMediaPosts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        platform: _selectedPlatform,
        page: _currentPage + 1,
        perPage: 20,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(result['posts'] as List<SocialMediaPost>);
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMorePages = pagination['current_page'] < pagination['last_page'];
          _currentPage = pagination['current_page'];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load more posts: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search posts, hashtags...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _searchPosts();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onSubmitted: (value) => _searchPosts(),
              ),

              const SizedBox(height: 12),

              // Platform Filter
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPlatform,
                      decoration: InputDecoration(
                        labelText: 'Platform',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Platforms'),
                        ),
                        ..._platforms.entries.map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPlatform = value);
                        _searchPosts();
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchPosts,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Featured Posts Section
                if (_featuredPosts.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Featured Posts',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredPosts.length,
                      itemBuilder: (context, index) {
                        final post = _featuredPosts[index];
                        return Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildFeaturedPostCard(post),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  Divider(),

                  const SizedBox(height: 16),
                ],

                // All Posts Section
                Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 8),
                    Text(
                      'All Posts',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Posts Grid
                if (_posts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No posts found matching your criteria.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_posts[index]);
                    },
                  ),

                // Load More Button
                if (_hasMorePages)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _loadMorePosts,
                        child: const Text('Load More'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPostCard(SocialMediaPost post) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launchUrl(post.postUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: post.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(post.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: post.thumbnailUrl == null ? Colors.grey[300] : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Platform badge
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getPlatformColor(post.platform),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                post.platformDisplayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),

                      // Play/view icon
                      const Center(
                        child: Icon(
                          Icons.open_in_new,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.favorite, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        post.formattedEngagement,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),

                      const Spacer(),

                      Text(
                        post.formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(SocialMediaPost post) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launchUrl(post.postUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: post.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(post.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: post.thumbnailUrl == null ? Colors.grey[300] : null,
                ),
                child: Stack(
                  children: [
                    // Platform badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getPlatformColor(post.platform),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          post.platformDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Featured star
                    if (post.isFeatured)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: Icon(Icons.star, color: Colors.amber, size: 20),
                      ),

                    // Play/view overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.open_in_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Icon(Icons.favorite, size: 12, color: Colors.red),
                        const SizedBox(width: 2),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Icon(Icons.share, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${post.shareCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      post.formattedDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    const platformColors = {
      'instagram': Color(0xFFE4405F),
      'facebook': Color(0xFF1877F2),
      'tiktok': Color(0xFF000000),
      'twitter': Color(0xFF1DA1F2),
      'youtube_shorts': Color(0xFFFF0000),
    };
    return platformColors[platform] ?? Colors.grey;
  }
}

class AddContentDialog extends StatefulWidget {
  final VoidCallback? onContentAdded;

  const AddContentDialog({super.key, this.onContentAdded});

  @override
  State<AddContentDialog> createState() => _AddContentDialogState();
}

class _AddContentDialogState extends State<AddContentDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Sermon fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _speakerController = TextEditingController();
  final _durationController = TextEditingController();
  String _selectedCategory = 'sunday_service';
  bool _isFeatured = false;

  // Social Media fields
  final _smTitleController = TextEditingController();
  final _smDescriptionController = TextEditingController();
  final _postUrlController = TextEditingController();
  final _hashtagsController = TextEditingController();
  String _selectedPlatform = 'youtube_shorts';
  String _mediaType = 'video';
  bool _smIsFeatured = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
    _speakerController.dispose();
    _durationController.dispose();
    _smTitleController.dispose();
    _smDescriptionController.dispose();
    _postUrlController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Content',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Sermon'),
                Tab(text: 'Social Media'),
              ],
            ),

            const SizedBox(height: 16),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildSermonForm(), _buildSocialMediaForm()],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Add Content'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Sermon Title *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _youtubeUrlController,
            decoration: const InputDecoration(
              labelText: 'YouTube URL *',
              hintText: 'https://www.youtube.com/watch?v=...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter YouTube URL';
              }
              if (!value.contains('youtube.com') &&
                  !value.contains('youtu.be')) {
                return 'Please enter a valid YouTube URL';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _speakerController,
            decoration: const InputDecoration(
              labelText: 'Speaker *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter speaker name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: '45',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'sunday_service',
                child: Text('Sunday Service'),
              ),
              DropdownMenuItem(
                value: 'bible_study',
                child: Text('Bible Study'),
              ),
              DropdownMenuItem(
                value: 'prayer_meeting',
                child: Text('Prayer Meeting'),
              ),
              DropdownMenuItem(
                value: 'youth_service',
                child: Text('Youth Service'),
              ),
              DropdownMenuItem(
                value: 'special_event',
                child: Text('Special Event'),
              ),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),

          const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Featured Sermon'),
            value: _isFeatured,
            onChanged: (value) => setState(() => _isFeatured = value ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextFormField(
            controller: _smTitleController,
            decoration: const InputDecoration(
              labelText: 'Post Title *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _smDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _postUrlController,
            decoration: const InputDecoration(
              labelText: 'Post URL *',
              hintText: 'https://www.instagram.com/p/...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter post URL';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _hashtagsController,
            decoration: const InputDecoration(
              labelText: 'Hashtags',
              hintText: '#church #faith #worship',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedPlatform,
            decoration: const InputDecoration(
              labelText: 'Platform',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
              DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
              DropdownMenuItem(
                value: 'youtube_shorts',
                child: Text('YouTube Shorts'),
              ),
              DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
              DropdownMenuItem(value: 'twitter', child: Text('Twitter')),
            ],
            onChanged: (value) => setState(() => _selectedPlatform = value!),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _mediaType,
            decoration: const InputDecoration(
              labelText: 'Media Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'video', child: Text('Video')),
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'carousel', child: Text('Carousel')),
              DropdownMenuItem(value: 'story', child: Text('Story')),
            ],
            onChanged: (value) => setState(() => _mediaType = value!),
          ),

          const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Featured Post'),
            value: _smIsFeatured,
            onChanged: (value) =>
                setState(() => _smIsFeatured = value ?? false),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_tabController.index == 0) {
        // Submit sermon
        final sermonData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'youtube_url': _youtubeUrlController.text,
          'speaker': _speakerController.text,
          'duration': int.tryParse(_durationController.text) ?? 0,
          'category': _selectedCategory,
          'is_featured': _isFeatured,
        };

        await SermonService.createSermon(sermonData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sermon added successfully!')),
          );
        }
      } else {
        // Submit social media post
        final postData = {
          'title': _smTitleController.text,
          'description': _smDescriptionController.text,
          'post_url': _postUrlController.text,
          'hashtags': _hashtagsController.text,
          'platform': _selectedPlatform,
          'media_type': _mediaType,
          'is_featured': _smIsFeatured,
        };

        await SermonService.createSocialMediaPost(postData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Social media post added successfully!'),
            ),
          );
        }
      }

      if (mounted) {
        widget.onContentAdded?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
