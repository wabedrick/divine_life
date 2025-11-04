import 'package:logger/logger.dart';
import '../models/sermon.dart';
import '../models/social_media_post.dart';
import 'api_service.dart';

class SermonService {
  static final Logger _logger = Logger();
  // Sermons API methods
  static Future<Map<String, dynamic>> getSermons({
    String? search,
    String? category,
    String? speaker,
    String? fromDate,
    String? toDate,
    bool? featured,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (speaker != null && speaker.isNotEmpty) {
        queryParams['speaker'] = speaker;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['to_date'] = toDate;
      }
      if (featured != null && featured) {
        queryParams['featured'] = '1';
      }

      String endpoint = '/sermons';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      _logger.d('SermonService: Fetching sermons from endpoint: $endpoint');
      final data = await ApiService.get(endpoint);
      _logger.d(
        'SermonService: Found ${(data['data'] as List).length} sermons in response',
      );

      return {
        'sermons': (data['data'] as List)
            .map((json) => Sermon.fromJson(json))
            .toList(),
        'pagination': {
          'current_page': data['current_page'],
          'last_page': data['last_page'],
          'total': data['total'],
          'per_page': data['per_page'],
          'from': data['from'],
          'to': data['to'],
        },
      };
    } catch (e) {
      throw Exception('Error fetching sermons: $e');
    }
  }

  static Future<List<Sermon>> getFeaturedSermons({int limit = 5}) async {
    try {
      // Use ApiService's new getList method for endpoints that return arrays
      final List<dynamic> sermons = await ApiService.getList(
        '/sermons/featured?limit=$limit',
      );
      return sermons.map((json) => Sermon.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching featured sermons: $e');
    }
  }

  static Future<Sermon> getSermon(int id) async {
    try {
      final data = await ApiService.get('/sermons/$id');
      return Sermon.fromJson(data);
    } catch (e) {
      throw Exception('Error fetching sermon: $e');
    }
  }

  static Future<Map<String, String>> getSermonCategories() async {
    try {
      final data = await ApiService.get('/sermons/categories');
      return Map<String, String>.from(data);
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  static Future<Sermon> createSermon(Map<String, dynamic> sermonData) async {
    try {
      final data = await ApiService.post('/sermons', data: sermonData);
      return Sermon.fromJson(data);
    } catch (e) {
      throw Exception('Error creating sermon: $e');
    }
  }

  // Social Media Posts API methods
  static Future<Map<String, dynamic>> getSocialMediaPosts({
    String? search,
    String? platform,
    String? category,
    String? mediaType,
    String? fromDate,
    String? toDate,
    bool? featured,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (platform != null && platform.isNotEmpty) {
        queryParams['platform'] = platform;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (mediaType != null && mediaType.isNotEmpty) {
        queryParams['media_type'] = mediaType;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['to_date'] = toDate;
      }
      if (featured != null && featured) {
        queryParams['featured'] = '1';
      }

      String endpoint = '/social-media';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final data = await ApiService.get(endpoint);

      return {
        'posts': (data['data'] as List)
            .map((json) => SocialMediaPost.fromJson(json))
            .toList(),
        'pagination': {
          'current_page': data['current_page'],
          'last_page': data['last_page'],
          'total': data['total'],
          'per_page': data['per_page'],
          'from': data['from'],
          'to': data['to'],
        },
      };
    } catch (e) {
      throw Exception('Error fetching social media posts: $e');
    }
  }

  static Future<List<SocialMediaPost>> getFeaturedSocialMediaPosts({
    int limit = 10,
  }) async {
    try {
      // Use ApiService's getList method for endpoints that return arrays
      final List<dynamic> posts = await ApiService.getList(
        '/social-media/featured?limit=$limit',
      );
      return posts.map((json) => SocialMediaPost.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching featured posts: $e');
    }
  }

  static Future<Map<String, String>> getSocialMediaPlatforms() async {
    try {
      final data = await ApiService.get('/social-media/platforms');
      return Map<String, String>.from(data);
    } catch (e) {
      throw Exception('Error fetching platforms: $e');
    }
  }

  static Future<Map<String, dynamic>> getPostsByPlatform(
    String platform, {
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      String endpoint = '/social-media/platform/$platform';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final data = await ApiService.get(endpoint);

      return {
        'posts': (data['data'] as List)
            .map((json) => SocialMediaPost.fromJson(json))
            .toList(),
        'pagination': {
          'current_page': data['current_page'],
          'last_page': data['last_page'],
          'total': data['total'],
          'per_page': data['per_page'],
          'from': data['from'],
          'to': data['to'],
        },
      };
    } catch (e) {
      throw Exception('Error fetching posts by platform: $e');
    }
  }

  static Future<SocialMediaPost> createSocialMediaPost(
    Map<String, dynamic> postData,
  ) async {
    try {
      final data = await ApiService.post('/social-media', data: postData);
      return SocialMediaPost.fromJson(data);
    } catch (e) {
      throw Exception('Error creating social media post: $e');
    }
  }

  // Sermon CRUD operations
  static Future<Sermon> updateSermon(
    int id,
    Map<String, dynamic> sermonData,
  ) async {
    try {
      final data = await ApiService.put('/sermons/$id', data: sermonData);
      return Sermon.fromJson(data);
    } catch (e) {
      throw Exception('Error updating sermon: $e');
    }
  }

  static Future<void> deleteSermon(int id) async {
    try {
      await ApiService.delete('/sermons/$id');
    } catch (e) {
      throw Exception('Error deleting sermon: $e');
    }
  }

  // Social Media CRUD operations
  static Future<SocialMediaPost> updateSocialMediaPost(
    int id,
    Map<String, dynamic> postData,
  ) async {
    try {
      final data = await ApiService.put('/social-media/$id', data: postData);
      return SocialMediaPost.fromJson(data);
    } catch (e) {
      throw Exception('Error updating social media post: $e');
    }
  }

  static Future<void> deleteSocialMediaPost(int id) async {
    try {
      await ApiService.delete('/social-media/$id');
    } catch (e) {
      throw Exception('Error deleting social media post: $e');
    }
  }
}
