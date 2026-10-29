import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/article.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('资料详情')),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 32), children: [
      if (article.categoryName != null) Align(alignment: Alignment.centerLeft, child: Chip(label: Text(article.categoryName!))),
      Text(article.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      if (article.summary.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(article.summary, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('更新于 ${article.updatedAt.toLocal()}')),
      if (article.tags.isNotEmpty) Wrap(spacing: 6, children: article.tags.map((t) => Chip(label: Text('#$t'))).toList()),
      if (article.imageUrls.isNotEmpty) ...[
        const SizedBox(height: 8),
        ...article.imageUrls.map((url) => Padding(padding: const EdgeInsets.only(bottom: 12), child: GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url)))) ,
          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: double.infinity, placeholder: (_,__) => Container(height: 180, color: Colors.black12))),
        )))
      ],
      const Divider(height: 28),
      SelectableText(article.body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7)),
    ]),
  );
}
