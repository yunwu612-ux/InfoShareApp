import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article.dart';

class ArticleService {
  final _db = Supabase.instance.client;
  Future<List<Article>> fetchArticles({String query = '', String? categoryId, String? tag}) async {
    var request = _db.from('articles').select('*, categories(name)').eq('status', 'published');
    if (categoryId != null && categoryId.isNotEmpty) request = request.eq('category_id', categoryId);
    if (tag != null && tag.isNotEmpty) request = request.contains('tags', [tag]);
    if (query.trim().isNotEmpty) {
      final q = query.trim().replaceAll(',', ' ');
      request = request.or('title.ilike.%$q%,summary.ilike.%$q%,body.ilike.%$q%');
    }
    final rows = await request.order('updated_at', ascending: false);
    return rows.map((row) => Article.fromMap(row)).toList();
  }
  Future<List<Map<String, dynamic>>> fetchCategories() async =>
      await _db.from('categories').select('id,name,slug').order('name');
  Stream<List<Map<String, dynamic>>> watchArticleChanges() {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final channel = _db.channel('public-articles-live')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'articles',
        callback: (_) async {
          try { controller.add(await _db.from('articles').select('id,status,updated_at')); }
          catch (e) { controller.addError(e); }
        }).subscribe();
    controller.onCancel = () async { await _db.removeChannel(channel); };
    return controller.stream;
  }
}
