import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/env.dart';
import '../../core/theme/app_colors.dart';

class PlanLocationField extends StatelessWidget {
  const PlanLocationField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.enabled,
  });
  final TextEditingController latitude, longitude;
  final bool enabled;
  Future<void> _pick(BuildContext context, FormFieldState<String> field) async {
    var point = LatLng(
      double.tryParse(latitude.text) ?? 6.2442,
      double.tryParse(longitude.text) ?? -75.5812,
    );
    final selected = await showDialog<LatLng>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: SizedBox(
            height: 500,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Toca el punto de encuentro',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 14,
                      minZoom: 2,
                      maxZoom: 18,
                      onTap: (_, position) =>
                          setDialogState(() => point = position),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppEnvironment.mapTileUrl,
                        userAgentPackageName: 'com.mamba.mamba_app',
                        maxNativeZoom: 16,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, point),
                        child: const Text('Usar este punto'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) {
      latitude.text = '${selected.latitude}';
      longitude.text = '${selected.longitude}';
      field.didChange(latitude.text);
    }
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
    initialValue: latitude.text,
    validator: (_) {
      final lat = double.tryParse(latitude.text),
          lon = double.tryParse(longitude.text);
      return lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180
          ? 'Elige el punto de encuentro en el mapa'
          : null;
    },
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: enabled ? () => _pick(context, field) : null,
          icon: Icon(
            latitude.text.isEmpty
                ? Icons.place_outlined
                : Icons.check_circle_outline,
          ),
          label: Text(
            latitude.text.isEmpty
                ? 'Elegir punto en el mapa'
                : 'Cambiar punto de encuentro',
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Marca dónde se encontrarán los participantes.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        if (field.hasError)
          Text(
            field.errorText!,
            style: const TextStyle(color: AppColors.error),
          ),
      ],
    ),
  );
}
