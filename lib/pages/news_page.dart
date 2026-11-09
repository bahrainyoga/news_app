
import 'package:flutter/material.dart';

import '../models/article.dart';
import '../services/news_service.dart';
import 'article_detail_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final NewsService _newsService = NewsService();

  late Future<List<Article>> _newsFuture;

  String _selectedCategory = 'general';

  // Menyimpan kata kunci pencarian API yang sedang aktif
  String? _activeSearchQuery;

  // Daftar kategori berita
  final List<Map<String, String>> _categories = [
    {'label': 'Umum', 'value': 'general'},
    {'label': 'Bisnis', 'value': 'business'},
    {'label': 'Hiburan', 'value': 'entertainment'},
    {'label': 'Kesehatan', 'value': 'health'},
    {'label': 'Sains', 'value': 'science'},
    {'label': 'Olahraga', 'value': 'sports'},
    {'label': 'Teknologi', 'value': 'technology'},
  ];

  // Controller pencarian API
  final TextEditingController _searchController =
      TextEditingController();

  // Controller filter lokal
  final TextEditingController _localFilterController =
      TextEditingController();

  String _localKeyword = '';

  @override
  void initState() {
    super.initState();

    // Memuat berita pertama kali
    _newsFuture = _newsService.fetchTopHeadlines();
  }

  // Memilih kategori berita
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;

      // Keluar dari mode pencarian API
      _activeSearchQuery = null;

      // Kosongkan kolom pencarian
      _searchController.clear();

      // Request berita berdasarkan kategori
      _newsFuture = _newsService.fetchTopHeadlines(
        category: category,
      );
    });
  }

  // Mencari berita melalui NewsAPI
  void _searchNews() {
    final query = _searchController.text.trim();

    // Jika kosong, kembali ke kategori aktif
    if (query.isEmpty) {
      _selectCategory(_selectedCategory);
      return;
    }

    setState(() {
      _activeSearchQuery = query;

      _newsFuture = _newsService.searchArticles(
        query: query,
      );
    });
  }

  // Mengulang request yang sedang aktif
  void _retryFetch() {
    setState(() {
      if (_activeSearchQuery != null) {
        // Jika sebelumnya mencari berita,
        // ulangi pencarian yang sama.
        _newsFuture = _newsService.searchArticles(
          query: _activeSearchQuery!,
        );
      } else {
        // Jika sebelumnya memilih kategori,
        // ulangi kategori tersebut.
        _newsFuture = _newsService.fetchTopHeadlines(
          category: _selectedCategory,
        );
      }
    });
  }

  // Filter lokal berdasarkan judul berita
  List<Article> filterByTitle(
    List<Article> articles,
    String keyword,
  ) {
    if (keyword.trim().isEmpty) {
      return articles;
    }

    return articles.where((article) {
      return article.title.toLowerCase().contains(
            keyword.trim().toLowerCase(),
          );
    }).toList();
  }

  // Membuka halaman detail berita
  void _openArticleDetail(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ArticleDetailPage(
            article: article,
          );
        },
      ),
    );
  }

  // Menghapus controller
  @override
  void dispose() {
    _searchController.dispose();
    _localFilterController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'News App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // =================================
          // SEARCH API
          // =================================

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchNews(),
              decoration: InputDecoration(
                hintText: 'Cari berita...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _searchNews,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // =================================
          // PILIHAN KATEGORI
          // =================================

          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              children: _categories.map((category) {
                final selected =
                    _selectedCategory == category['value'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category['label']!),
                    selected: selected,
                    onSelected: (_) {
                      _selectCategory(category['value']!);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // =================================
          // FILTER LOKAL
          // =================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: TextField(
              controller: _localFilterController,
              decoration: InputDecoration(
                labelText: 'Filter judul berita',
                hintText: 'Contoh: AI, technology, sports',
                prefixIcon: const Icon(Icons.filter_alt),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _localFilterController.clear();

                    setState(() {
                      _localKeyword = '';
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _localKeyword = value;
                });
              },
            ),
          ),

          // =================================
          // DAFTAR BERITA
          // =================================

          Expanded(
            child: FutureBuilder<List<Article>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                // KONDISI LOADING
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // KONDISI ERROR
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 48,
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Gagal mengambil berita',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: _retryFetch,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // DATA BERITA
                final List<Article> articles =
                    snapshot.data ?? [];

                // FILTER LOKAL
                final List<Article> filteredArticles =
                    filterByTitle(
                  articles,
                  _localKeyword,
                );

                // KONDISI DATA KOSONG
                if (filteredArticles.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada berita yang cocok.',
                    ),
                  );
                }

                // KONDISI BERHASIL
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = filteredArticles[index];

                    return InkWell(
                      onTap: () {
                        _openArticleDetail(article);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // GAMBAR BERITA
                            if (article.imageUrl.isNotEmpty)
                              Image.network(
                                article.imageUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // INFORMASI BERITA
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.sourceName,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    article.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    article.description.isEmpty
                                        ? 'Deskripsi tidak tersedia.'
                                        : article.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 8),

                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Baca selengkapnya',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.blue,
                                        size: 16,
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
