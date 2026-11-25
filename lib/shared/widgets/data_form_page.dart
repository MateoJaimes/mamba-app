import 'package:flutter/material.dart';
import 'mapo_network_image.dart';
import '../../core/theme/app_colors.dart';
import 'plan_location_field.dart';
import '../../core/services/account_service.dart';
import '../../core/services/media_service.dart';

class DataField {
  const DataField(
    this.keyName,
    this.label, {
    this.lines = 1,
    this.required = true,
    this.number = false,
    this.https = false,
    this.choices,
    this.multiple = false,
    this.maxSelections = 6,
    this.section,
  });
  final String keyName;
  final String? section;
  final String label;
  final int lines;
  final bool required;
  final bool number;
  final bool https;
  final Map<String, String>? choices;
  final bool multiple;
  final int maxSelections;
}

class DataFormPage extends StatefulWidget {
  const DataFormPage({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    this.initial = const {},
    this.description,
    this.saveLabel = 'Guardar cambios',
  });
  final String title;
  final String? description;
  final String saveLabel;
  final List<DataField> fields;
  final Map<String, dynamic> initial;
  final Future<void> Function(Map<String, dynamic>) onSave;
  @override
  State<DataFormPage> createState() => _DataFormPageState();
}

class _DataFormPageState extends State<DataFormPage> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields)
      f.keyName: TextEditingController(
        text: '${widget.initial[f.keyName] ?? ''}',
      ),
  };
  bool _saving = false;
  late final Map<String, Set<String>> _selections = {
    for (final f in widget.fields.where((f) => f.multiple))
      f.keyName: Set<String>.from(widget.initial[f.keyName] as List? ?? []),
  };
  String? _error;
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      setState(() => _error = 'Revisa los campos marcados antes de guardar.');
      return;
    }
    for (final f in widget.fields.where((f) => f.multiple)) {
      if ((f.required && _selections[f.keyName]!.isEmpty) ||
          _selections[f.keyName]!.length > f.maxSelections) {
        setState(
          () => _error =
              'Elige entre ${f.required ? 1 : 0} y ${f.maxSelections} opciones en ${f.label}.',
        );
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave({
        for (final e in _controllers.entries) e.key: e.value.text.trim(),
        for (final e in _selections.entries) e.key: e.value.toList(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = AccountService.error(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _upload(DataField field) async {
    setState(() => _saving = true);
    try {
      final url = await MediaService.pickAndUpload();
      if (url != null) {
        final c = _controllers[field.keyName]!;
        c.text = field.keyName == 'images' && c.text.trim().isNotEmpty
            ? '${c.text.trim()}\n$url'
            : url;
      }
    } catch (e) {
      if (mounted) setState(() => _error = AccountService.error(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _choose(DataField field) async {
    final chosen = Set<String>.from(_selections[field.keyName]!);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Elige hasta ${field.maxSelections} opciones'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in field.choices!.entries)
                      FilterChip(
                        label: Text(e.value),
                        selected: chosen.contains(e.key),
                        onSelected:
                            !chosen.contains(e.key) &&
                                chosen.length >= field.maxSelections
                            ? null
                            : (selected) => setSheetState(() {
                                if (selected) {
                                  chosen.add(e.key);
                                } else {
                                  chosen.remove(e.key);
                                }
                              }),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context, chosen),
                  child: const Text('Listo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selections[field.keyName] = result);
    }
  }

  Widget _multiple(DataField field) => FormField<List<String>>(
    validator: (_) => field.required && _selections[field.keyName]!.isEmpty
        ? 'Selecciona al menos una opción'
        : null,
    builder: (state) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final value in _selections[field.keyName]!)
              Chip(label: Text(field.choices![value] ?? value)),
            ActionChip(
              avatar: const Icon(Icons.add, size: 17),
              label: Text(
                field.keyName == 'categories'
                    ? 'Elegir categorías'
                    : 'Elegir intereses',
              ),
              onPressed: _saving
                  ? null
                  : () async {
                      await _choose(field);
                      state.didChange(_selections[field.keyName]!.toList());
                    },
            ),
          ],
        ),
        if (state.hasError)
          Text(
            state.errorText!,
            style: const TextStyle(color: AppColors.error),
          ),
      ],
    ),
  );
  Widget _field(DataField f) {
    if (f.keyName == 'longitude' && _controllers.containsKey('latitude')) {
      return const SizedBox.shrink();
    }
    if (f.keyName == 'latitude' && _controllers.containsKey('longitude')) {
      return PlanLocationField(
        latitude: _controllers['latitude']!,
        longitude: _controllers['longitude']!,
        enabled: !_saving,
      );
    }
    if (f.https || f.keyName == 'images') return _photos(f);
    if (f.multiple) return _multiple(f);
    if (f.choices != null) {
      return DropdownButtonFormField<String>(
        initialValue: f.choices!.containsKey(_controllers[f.keyName]!.text)
            ? _controllers[f.keyName]!.text
            : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: f.label),
        items: [
          for (final e in f.choices!.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: _saving
            ? null
            : (v) => _controllers[f.keyName]!.text = v ?? '',
        validator: (v) =>
            f.required && v == null ? 'Selecciona una opción' : null,
      );
    }
    return TextFormField(
      controller: _controllers[f.keyName],
      maxLines: f.lines,
      enabled: !_saving,
      keyboardType: f.number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: f.label, alignLabelWithHint: true),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return f.required ? 'Completa este campo' : null;
        if (f.number && num.tryParse(value) == null) {
          return 'Escribe un número válido';
        }
        return null;
      },
    );
  }

  List<String> _urls(DataField f) => _controllers[f.keyName]!.text
      .split('\n')
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList();
  Widget _photos(DataField f) => FormField<String>(
    validator: (_) {
      final urls = _urls(f);
      if (f.required && urls.isEmpty) return 'Añade al menos una foto';
      if (urls.length > 8) return 'Elige hasta 8 fotos';
      if (urls.any((s) {
        final u = Uri.tryParse(s);
        return u?.scheme != 'https' || u!.host.isEmpty;
      })) {
        return 'Reemplaza la foto que no se pudo cargar';
      }
      return null;
    },
    builder: (state) {
      final urls = _urls(f), limit = f.keyName == 'images' ? 8 : 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (f.section == null)
            Text(
              f.keyName == 'images' ? 'Fotos del plan' : f.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 8),
          if (f.keyName == 'images')
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'La primera foto será la portada.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < urls.length; i++)
                SizedBox(
                  width: 116,
                  height: 116,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: MapoNetworkImage(
                            imageUrl: urls[i],
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                            errorWidget: (_, _, _) => const ColoredBox(
                              color: AppColors.surfaceRaised,
                              child: Icon(Icons.image_outlined),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton.filledTonal(
                          tooltip: 'Quitar foto ${i + 1}',
                          onPressed: _saving
                              ? null
                              : () {
                                  setState(() {
                                    final updated = _urls(f)..removeAt(i);
                                    _controllers[f.keyName]!.text = updated
                                        .join('\n');
                                  });
                                  state.didChange(
                                    _controllers[f.keyName]!.text,
                                  );
                                },
                          icon: const Icon(Icons.close, size: 17),
                        ),
                      ),
                    ],
                  ),
                ),
              if (urls.length < limit)
                SizedBox(
                  width: 116,
                  height: 116,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _saving
                        ? null
                        : () async {
                            await _upload(f);
                            state.didChange(_controllers[f.keyName]!.text);
                          },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined),
                        SizedBox(height: 8),
                        Text('Añadir foto', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (state.hasError)
            Text(
              state.errorText!,
              style: const TextStyle(color: AppColors.error),
            ),
        ],
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<DataField>>{};
    String current = '';
    for (final f in widget.fields) {
      if (f.section != null) current = f.section!;
      (groups[current] ??= []).add(f);
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : widget.saveLabel),
        ),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    widget.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              for (final group in groups.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (group.key.isNotEmpty) ...[
                            Text(
                              group.key,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          for (final f in group.value)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _field(f),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ),
    );
  }
}
