import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import 'article_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}
class _LibraryScreenState extends State<LibraryScreen> {
  final service = ArticleService();
  final search = TextEditingController();
  List<Article> articles = [];
  List<Map<String,dynamic>> categories = [];
  String? categoryId;
  bool loading = true;
  String? error;
  StreamSubscription? live;
  @override
  void initState() {
    super.initState();
    load();
    live = service.watchArticleChanges().listen((_) => load(), onError: (_) {});
  }
  @override
  void dispose() { search.dispose(); live?.cancel(); super.dispose(); }
  Future<void> load() async {
    try {
      final results = await Future.wait([service.fetchArticles(query: search.text, categoryId: categoryId), service.fetchCategories()]);
      if (!mounted) return;
      setState(() { articles = results[0] as List<Article>; categories = results[1] as List<Map<String,dynamic>>; loading = false; error = null; });
    } catch (e) { if (mounted) setState(() { loading = false; error = '加载失败，请检查网络或云端配置。'; }); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('资料库', style: TextStyle(fontWeight: FontWeight.w700)), actions: [
      IconButton(tooltip: '刷新', onPressed: load, icon: const Icon(Icons.refresh))
    ]),
    body: RefreshIndicator(onRefresh: load, child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('探索与查阅', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(controller: search, onSubmitted: (_) => load(), textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: '搜索标题、内容或摘要', prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { search.clear(); load(); }),
            filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
        const SizedBox(height: 12),
        SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: [
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('全部'), selected: categoryId == null, onSelected: (_) { setState(() => categoryId = null); load(); })),
          ...categories.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c['name']), selected: categoryId == c['id'], onSelected: (_) { setState(() => categoryId = c['id']); load(); }))),
        ])),
        const SizedBox(height: 8),
        if (loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
        if (error != null) Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)),
        if (!loading && error == null && articles.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('暂无资料'))),
        ...articles.map((a) => Card(
          margin: const EdgeInsets.only(bottom: 12), clipBehavior: Clip.antiAlias,
          elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (a.imageUrls.isNotEmpty) CachedNetworkImage(imageUrl: a.imageUrls.first, height: 180, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_,__) => Container(height: 180, color: const Color(0xFFE8EDF3)),
                errorWidget: (_,__,___) => Container(height: 100, color: const Color(0xFFE8EDF3), child: const Icon(Icons.broken_image))),
              Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [if (a.categoryName != null) _pill(a.categoryName!), const Spacer(), Text(_date(a.updatedAt), style: Theme.of(context).textTheme.labelSmall)]),
                const SizedBox(height: 8), Text(a.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                if (a.summary.isNotEmpty) ...[const SizedBox(height: 6), Text(a.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54))],
                if (a.tags.isNotEmpty) ...[const SizedBox(height: 10), Wrap(spacing: 6, children: a.tags.take(5).map((t) => _pill('#$t')).toList())]
              ]))
            ])))),
      ],
    )),
  );
  Widget _pill(String s) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEAF0F7), borderRadius: BorderRadius.circular(20)), child: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF315C8A))));
  String _date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}';
}
