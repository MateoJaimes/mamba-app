import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reviews/domain/colombian_rating.dart';
import 'experience_image_carousel.dart';

class ExperienceFeedCard extends StatefulWidget {
  const ExperienceFeedCard({super.key, required this.experience});

  final Map<String, dynamic> experience;

  @override
  State<ExperienceFeedCard> createState() => _ExperienceFeedCardState();
}

class _ExperienceFeedCardState extends State<ExperienceFeedCard> {
  bool _isLiked = false;
  bool _isSaved = false;
  final List<String> _comments = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final images = List<String>.from(widget.experience['images']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                final hostId = widget.experience['provider_id'] as String?;
                if (hostId != null) context.push('/host/$hostId');
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .22),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _providerName.trim().isEmpty
                            ? '?'
                            : _providerName
                                  .trim()
                                  .substring(0, 1)
                                  .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF06251A),
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _providerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.experience['location'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Más opciones',
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ],
                ),
              ),
            ),
            ExperienceImageCarousel(
              images: images,
              onTap: () {
                final experienceId = widget.experience['id'] as String?;
                if (experienceId != null) {
                  context.push('/experience/$experienceId');
                }
              },
              ratingLabel:
                  widget.experience['experience_rating'] as String? ??
                  ColombianRating.unaChimba.label,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Me gusta',
                    onPressed: () => setState(() => _isLiked = !_isLiked),
                    icon: Icon(
                      _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isLiked
                          ? const Color(0xFFFF657A)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Comentarios',
                    onPressed: _showComments,
                    icon: const Icon(Icons.mode_comment_outlined),
                  ),
                  IconButton(
                    tooltip: 'Compartir',
                    onPressed: _shareExperience,
                    icon: const Icon(Icons.send_rounded),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: _isSaved
                        ? 'Quitar de guardados'
                        : 'Guardar publicación',
                    onPressed: () => setState(() => _isSaved = !_isSaved),
                    icon: Icon(
                      _isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: _isSaved
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.experience['title'],
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.experience['description'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 19,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '${widget.experience['reviews']} reseñas del plan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const Spacer(),
                      Text('Desde ', style: theme.textTheme.bodyMedium),
                      Text(
                        widget.experience['price'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final experienceId = widget.experience['id'] as String?;
                        if (experienceId != null) {
                          context.push('/experience/$experienceId');
                        }
                      },
                      icon: const Icon(Icons.confirmation_number_outlined),
                      label: const Text('Me apunto'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _providerName =>
      widget.experience['provider'] as String? ?? 'Anfitrión local';

  Future<void> _shareExperience() async {
    final title = widget.experience['title'] as String;
    final location = widget.experience['location'] as String;
    await SharePlus.instance.share(
      ShareParams(text: '$title en $location. Descúbrelo en MAMBA.'),
    );
  }

  Future<void> _showComments() async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Comentarios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              if (_comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Sé la primera persona en comentar',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ..._comments.map(
                  (comment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(comment),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) =>
                          _addComment(controller, setSheetState),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _addComment(controller, setSheetState),
                    icon: Icon(
                      Icons.send_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }

  void _addComment(
    TextEditingController controller,
    StateSetter setSheetState,
  ) {
    final comment = controller.text.trim();
    if (comment.isEmpty) return;
    setState(() => _comments.add(comment));
    controller.clear();
    setSheetState(() {});
  }
}
