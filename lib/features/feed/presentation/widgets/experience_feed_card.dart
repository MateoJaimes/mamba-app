import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/mamba_data_service.dart';
import '../../../reviews/domain/colombian_rating.dart';
import 'experience_image_carousel.dart';

class ExperienceFeedCard extends StatefulWidget {
  const ExperienceFeedCard({super.key, required this.experience});

  final Map<String, dynamic> experience;

  @override
  State<ExperienceFeedCard> createState() => _ExperienceFeedCardState();
}

class _ExperienceFeedCardState extends State<ExperienceFeedCard> {
  late bool _isLiked;
  late bool _isSaved;
  final List<Map<String, dynamic>> _comments = [];
  bool _commentsLoading = false;
  bool _commentSubmitting = false;
  int _commentsRequestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.experience['is_liked_by_me'] == true;
    _isSaved = widget.experience['is_saved_by_me'] == true;
  }

  @override
  void didUpdateWidget(covariant ExperienceFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.experience['id'] != widget.experience['id']) {
      _isLiked = widget.experience['is_liked_by_me'] == true;
      _isSaved = widget.experience['is_saved_by_me'] == true;
      _comments.clear();
      _commentsLoading = false;
      _commentsRequestGeneration++;
    }
  }

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
                    onPressed: _toggleLike,
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
                    onPressed: _toggleSaved,
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

  Future<void> _toggleLike() async {
    final previous = _isLiked;
    final next = !previous;
    setState(() => _isLiked = next);
    if (MambaDataService.hasSignedInUser) {
      try {
        await MambaDataService.toggleExperienceLike('${widget.experience['id']}', previous);
      } catch (_) {
        if (mounted) setState(() => _isLiked = previous);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos actualizar el me gusta.')));
      }
    }
  }

  Future<void> _toggleSaved() async {
    final previous = _isSaved;
    final next = !previous;
    setState(() => _isSaved = next);
    if (MambaDataService.hasSignedInUser) {
      try {
        await MambaDataService.toggleFavorite('${widget.experience['id']}', previous);
      } catch (_) {
        if (mounted) setState(() => _isSaved = previous);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos guardar la publicación.')));
      }
    }
  }

  Future<void> _shareExperience() async {
    final title = widget.experience['title'] as String;
    final location = widget.experience['location'] as String;
    await SharePlus.instance.share(
      ShareParams(text: '$title en $location. Descúbrelo en MAMBA.'),
    );
  }

  Future<void> _showComments() async {
    final controller = TextEditingController();
    var loadingStarted = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          void safeSetSheetState(VoidCallback callback) {
            if (sheetContext.mounted) setSheetState(callback);
          }

          if (!loadingStarted) {
            loadingStarted = true;
            if (_comments.isEmpty) {
              _commentsLoading = true;
              final generation = ++_commentsRequestGeneration;
              MambaDataService.fetchComments('${widget.experience['id']}').then((comments) {
                if (generation != _commentsRequestGeneration) return;
                _comments
                  ..clear()
                  ..addAll(comments);
                _commentsLoading = false;
                safeSetSheetState(() {});
              });
            }
          }

          return AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: SafeArea(
              top: true,
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height -
                    MediaQuery.viewInsetsOf(sheetContext).bottom,
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildPublicationPreview(sheetContext),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Comentarios',
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                Text(
                                  '${_comments.length}',
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _commentsLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _comments.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Sé la primera persona en comentar',
                                        style: Theme.of(sheetContext)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _comments.length,
                                      separatorBuilder: (_, _) => Divider(
                                        color: AppColors.border.withValues(
                                          alpha: .65,
                                        ),
                                        height: 16,
                                      ),
                                      itemBuilder: (context, index) =>
                                          _buildCommentRow(
                                        context: sheetContext,
                                        comment: _comments[index],
                                        setSheetState: safeSetSheetState,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    minLines: 1,
                                    maxLines: 3,
                                    maxLength: 1000,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _submitComment(
                                      controller,
                                      safeSetSheetState,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Escribe un comentario',
                                      counterText: '',
                                      filled: true,
                                      fillColor: AppColors.surfaceRaised,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  tooltip: 'Publicar comentario',
                                  onPressed: _commentSubmitting
                                      ? null
                                      : () => _submitComment(
                                          controller,
                                          safeSetSheetState,
                                        ),
                                  icon: _commentSubmitting
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded),
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
            ),
          );
        },
      ),
    );
    controller.dispose();
  }

  Widget _buildPublicationPreview(BuildContext sheetContext) {
    final images = List<String>.from(widget.experience['images'] ?? const []);
    final image = images.isEmpty ? '' : images.first;
    final title = '${widget.experience['title'] ?? 'Publicación'}';
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isNotEmpty)
            CachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const ColoredBox(
                color: AppColors.surfaceRaised,
                child: Icon(Icons.landscape_outlined, size: 42),
              ),
            )
          else
            const ColoredBox(
              color: AppColors.surfaceRaised,
              child: Icon(Icons.landscape_outlined, size: 42),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x88000000), Colors.transparent, Color(0xD9000000)],
                stops: [0, .4, 1],
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 12,
            right: 8,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _providerName.trim().isEmpty
                        ? '?'
                        : _providerName.trim().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF06251A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${widget.experience['location'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar comentarios',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.experience['description'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentRow({
    required BuildContext context,
    required Map<String, dynamic> comment,
    required StateSetter setSheetState,
  }) {
    final author = '${comment['author_name'] ?? 'Viajero MAMBA'}';
    final avatarUrl = comment['author_avatar_url'] as String?;
    final createdAt = DateTime.tryParse('${comment['created_at'] ?? ''}')?.toLocal();
    final date = createdAt == null ? '' : DateFormat('dd-MM-yy').format(createdAt);
    final isOwner = MambaDataService.hasSignedInUser
        ? comment['user_id'] == MambaDataService.currentUserId
        : comment['user_id'] == 'preview';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.primary.withValues(alpha: .18),
          foregroundImage: avatarUrl == null || avatarUrl.isEmpty
              ? null
              : CachedNetworkImageProvider(avatarUrl),
          child: Text(
            author.trim().isEmpty ? '?' : author.trim()[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      tooltip: 'Opciones del comentario',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44),
                      iconSize: 19,
                      onSelected: (action) {
                        if (action == 'edit') {
                          _editComment(comment, setSheetState);
                        } else {
                          _deleteComment(comment, setSheetState);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded),
                              SizedBox(width: 10),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Text(
                '${comment['body'] ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editComment(
    Map<String, dynamic> comment,
    StateSetter setSheetState,
  ) async {
    final controller = TextEditingController(text: '${comment['body'] ?? ''}');
    final updatedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar comentario'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: 'Escribe tu comentario'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updatedText == null || updatedText.isEmpty) return;

    try {
      final String commentId = '${comment['id']}';
      final Map<String, dynamic> updated;
      if (comment['user_id'] == 'preview') {
        updated = {...comment, 'body': updatedText};
      } else {
        updated = await MambaDataService.updateComment(commentId, updatedText);
      }
      final index = _comments.indexWhere((item) => item['id'] == comment['id']);
      if (index >= 0 && mounted) {
        setState(() => _comments[index] = updated);
        setSheetState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos editar el comentario.')),
        );
      }
    }
  }

  Future<void> _deleteComment(
    Map<String, dynamic> comment,
    StateSetter setSheetState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Quieres eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      if (comment['user_id'] != 'preview') {
        await MambaDataService.deleteComment('${comment['id']}');
      }
      if (!mounted) return;
      setState(() => _comments.removeWhere((item) => item['id'] == comment['id']));
      setSheetState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos eliminar el comentario.')),
        );
      }
    }
  }

  Future<void> _submitComment(
    TextEditingController controller,
    StateSetter setSheetState,
  ) async {
    final comment = controller.text.trim();
    if (comment.isEmpty || _commentSubmitting) return;
    if (comment.length > 1000) return;
    controller.clear();

    if (MambaDataService.hasSignedInUser) {
      setSheetState(() => _commentSubmitting = true);
      try {
        final created = await MambaDataService.addComment(
          '${widget.experience['id']}',
          comment,
        );
        if (!mounted) return;
        setState(() => _comments.insert(0, created));
        setSheetState(() => _commentSubmitting = false);
      } catch (_) {
        setSheetState(() => _commentSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pudimos publicar el comentario.')),
          );
        }
      }
      return;
    }

    final now = DateTime.now().toIso8601String();
    setState(() => _comments.insert(0, {
      'id': 'preview-${DateTime.now().microsecondsSinceEpoch}',
      'user_id': 'preview',
      'body': comment,
      'author_name': 'Tú',
      'created_at': now,
    }));
    setSheetState(() {});
  }
}
