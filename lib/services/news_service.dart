
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/article.dart';

class NewsService {

  // Mengambil API key dari file .env
  String get apiKey {
    final key = dotenv.env['NEWS_API_KEY'] ?? '';

    if (key.isEmpty) {
      throw Exception(
        'NEWS_API_KEY belum diatur. Periksa file .env.',
      );
    }

    return key;
  }

  // Mengambil berita berdasarkan kategori
  Future<List<Article>> fetchTopHeadlines({
    String category = 'general',
  }) async {
    final uri = Uri.https(
      'newsapi.org',
      '/v2/top-headlines',
      {
        'country': 'us',
        'category': category,
        'pageSize': '20',
      },
    );

    return _getArticles(uri);
  }

  // Mencari berita melalui API
  Future<List<Article>> searchArticles({
    required String query,
  }) async {
    final uri = Uri.https(
      'newsapi.org',
      '/v2/everything',
      {
        'q': query,
        'pageSize': '20',
        'sortBy': 'publishedAt',
      },
    );

    return _getArticles(uri);
  }

  // Request API bersama
  Future<List<Article>> _getArticles(Uri uri) async {
    final response = await http.get(
      uri,
      headers: {
        'X-Api-Key': apiKey,
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body)
          as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Respons server tidak dapat dibaca. HTTP ${response.statusCode}',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ??
            'Gagal mengambil berita. HTTP ${response.statusCode}',
      );
    }

    if (data['status'] != 'ok') {
      throw Exception(
        data['message'] ??
            'Terjadi kesalahan pada API',
      );
    }

    final List<dynamic> articlesJson =
        data['articles'] ?? [];

    return articlesJson.map((json) {
      return Article.fromJson(
        json as Map<String, dynamic>,
      );
    }).toList();
  }
}
