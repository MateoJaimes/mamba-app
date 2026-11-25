import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/account_service.dart';
import '../../../../core/services/currency_service.dart';

class ProfilePreferencesPage extends StatefulWidget {
  const ProfilePreferencesPage({
    super.key,
    required this.profile,
    this.currency = false,
  });
  final Map<String, dynamic> profile;
  final bool currency;
  @override
  State<ProfilePreferencesPage> createState() => _ProfilePreferencesPageState();
}

class _ProfilePreferencesPageState extends State<ProfilePreferencesPage> {
  List<Map<String, dynamic>> _countries = [],
      _regions = [],
      _cities = [],
      _currencies = [];
  String? _country, _region, _city;
  late final _cityText = TextEditingController(
    text: '${widget.profile['city'] ?? ''}',
  );
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _country = widget.profile['country_code'];
    _region = widget.profile['region_code'];
    _city = widget.profile['city_code'];
    _load();
  }

  List<Map<String, dynamic>> _rows(dynamic rows) =>
      List<Map<String, dynamic>>.from(rows as List);
  Future<void> _load() async {
    try {
      if (widget.currency) {
        _currencies = _rows(
          await AccountService.client
              .from('currencies')
              .select()
              .order('sort_order'),
        );
      } else {
        _countries = _rows(
          await AccountService.client.from('countries').select().order('name'),
        );
        _regions = _rows(
          await AccountService.client
              .from('regions')
              .select()
              .eq('country_code', 'CO')
              .order('name'),
        );
        if (_region != null) await _loadCities(_region!);
      }
    } catch (e) {
      _error = AccountService.error(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCities(String code) async {
    final rows = await AccountService.client
        .from('cities')
        .select()
        .eq('region_code', code)
        .order('name');
    if (mounted && _region == code) setState(() => _cities = _rows(rows));
  }

  @override
  void dispose() {
    _cityText.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_country == null ||
        (_country == 'CO' && (_region == null || _city == null)) ||
        (_country != 'CO' && _cityText.text.trim().isEmpty)) {
      setState(() => _error = 'Selecciona tu país y completa tu ciudad.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AccountService.client
          .from('profiles')
          .update({
            'country_code': _country,
            'region_code': _country == 'CO' ? _region : null,
            'city_code': _country == 'CO' ? _city : null,
            'city': _cityText.text.trim(),
          })
          .eq('id', AccountService.userId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = AccountService.error(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _picker(
    String label,
    List<Map<String, dynamic>> rows,
    String? value,
    ValueChanged<String?> change,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label:$value:${rows.length}'),
    initialValue: rows.any((r) => r['code'] == value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: rows
        .map(
          (r) => DropdownMenuItem<String>(
            value: r['code'],
            child: Text('${r['name']}', overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: _saving ? null : change,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.currency ? 'Divisa' : 'País y ciudad')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.currency) ...[
                const Text(
                  'Elige cómo quieres ver los precios. Las conversiones son aproximadas; las solicitudes conservan su valor original en COP.',
                ),
                const SizedBox(height: 16),
                for (final c in _currencies)
                  ListTile(
                    title: Text('${c['code']} · ${c['name']}'),
                    trailing: CurrencyService.instance.code == c['code']
                        ? const Icon(Icons.check_circle)
                        : null,
                    enabled: !_saving,
                    onTap: () async {
                      setState(() {
                        _saving = true;
                        _error = null;
                      });
                      try {
                        await CurrencyService.instance.select('${c['code']}');
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => _error =
                                'No pudimos actualizar la divisa. Reintenta.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
                  ),
                Text(
                  'Tasa: ${CurrencyService.instance.updatedAt ?? 'COP, sin conversión'}${CurrencyService.instance.stale ? ' · Última tasa disponible' : ''}',
                ),
                TextButton(
                  onPressed: () =>
                      launchUrl(Uri.parse('https://www.exchangerate-api.com')),
                  child: const Text('Tasas de ExchangeRate-API'),
                ),
              ] else ...[
                _picker(
                  'País',
                  _countries,
                  _country,
                  (v) => setState(() {
                    _country = v;
                    _region = null;
                    _city = null;
                    _cities = [];
                  }),
                ),
                const SizedBox(height: 20),
                if (_country == 'CO') ...[
                  _picker('Departamento', _regions, _region, (v) async {
                    setState(() {
                      _region = v;
                      _city = null;
                      _cities = [];
                    });
                    if (v != null) {
                      try {
                        await _loadCities(v);
                      } catch (e) {
                        if (mounted) {
                          setState(() => _error = AccountService.error(e));
                        }
                      }
                    }
                  }),
                  const SizedBox(height: 20),
                  _picker(
                    'Ciudad o municipio',
                    _cities,
                    _city,
                    (v) => setState(() => _city = v),
                  ),
                ] else
                  TextField(
                    controller: _cityText,
                    decoration: const InputDecoration(labelText: 'Ciudad'),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Guardar ubicación'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Países: GeoNames · Municipios de Colombia: DANE / DIVIPOLA',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (_saving) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
            ],
          ),
  );
}
