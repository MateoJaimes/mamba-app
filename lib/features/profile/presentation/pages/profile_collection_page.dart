import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/account_service.dart';

class ProfileCollectionPage extends StatefulWidget {
  const ProfileCollectionPage({super.key, this.reviews = false});
  final bool reviews;
  @override
  State<ProfileCollectionPage> createState() => _ProfileCollectionPageState();
}

class _ProfileCollectionPageState extends State<ProfileCollectionPage> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.reviews) {
      return AccountService.client
          .from('reviews')
          .select()
          .eq('reviewer_id', AccountService.userId)
          .order('created_at', ascending: false);
    }
    final saved = await AccountService.client
        .from('favorites')
        .select('experience_id')
        .eq('user_id', AccountService.userId);
    if (saved.isEmpty) return [];
    return AccountService.client
        .from('experience_feed')
        .select()
        .inFilter('id', saved.map((r) => r['experience_id']).toList());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.reviews ? 'Mis reseñas' : 'Mis guardados'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() => _future = _load()),
              child: const Text('No pudimos cargar. Reintentar'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.reviews
                    ? 'Tus reseñas aparecerán aquí después de completar y calificar una experiencia.'
                    : 'Guarda planes desde el feed para encontrarlos aquí.',
              ),
            ),
          );
        }
        return ListView(
          children: snapshot.data!
              .map(
                (r) => ListTile(
                  title: Text('${widget.reviews ? r['comment'] : r['title']}'),
                  subtitle: Text(
                    widget.reviews
                        ? 'Reseña de tu experiencia'
                        : '${r['location']}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '/experience/${widget.reviews ? r['experience_id'] : r['id']}',
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}
