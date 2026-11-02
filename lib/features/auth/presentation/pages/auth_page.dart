import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/auth/account_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.authConfigured});

  final bool authConfigured;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNamesController = TextEditingController();
  final _lastNamesController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _isRegistering = false;
  AccountIntent _accountIntent = AccountIntent.tourist;
  String _documentType = 'cc';
  DateTime? _birthDate;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  String? _notice;
  String? _error;

  @override
  void dispose() {
    _firstNamesController.dispose();
    _lastNamesController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _notice = null;
      _error = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!widget.authConfigured) {
      setState(() => _error = 'Falta configurar la conexión de autenticación.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _notice = null;
      _error = null;
    });

    try {
      final auth = AuthService(Supabase.instance.client);
      if (_isRegistering) {
        final response = await auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          firstNames: _firstNamesController.text,
          lastNames: _lastNamesController.text,
          documentType: _documentType,
          documentNumber: _documentNumberController.text,
          birthDate: _birthDate!,
          phoneNumber: _phoneController.text,
          intent: _accountIntent,
        );

        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            _isRegistering = false;
            _notice =
                'Revisa tu correo para confirmar la cuenta y luego inicia sesión.';
          });
        } else {
          context.go('/feed');
        }
      } else {
        await auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) context.go('/feed');
      }
    } on AuthException catch (exception) {
      if (mounted) setState(() => _error = _friendlyAuthError(exception));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No fue posible conectar. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _requestPasswordRecovery() async {
    final validationError = _validateEmail(_emailController.text);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _notice = null;
      _error = null;
    });

    try {
      await AuthService(
        Supabase.instance.client,
      ).sendPasswordRecovery(_emailController.text);
      if (mounted) {
        setState(() {
          _notice =
              'Si hay una cuenta con ese correo, recibirás un enlace para cambiar la contraseña.';
        });
      }
    } on AuthException catch (exception) {
      if (mounted) setState(() => _error = _friendlyAuthError(exception));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No fue posible conectar. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyAuthError(AuthException exception) {
    return switch (exception.code) {
      'invalid_credentials' => 'Correo o contraseña incorrectos.',
      'email_not_confirmed' => 'Confirma tu correo antes de iniciar sesión.',
      'user_already_exists' => 'Ya existe una cuenta con ese correo.',
      'weak_password' => 'La contraseña no cumple los requisitos de seguridad.',
      'over_email_send_rate_limit' =>
        'Se enviaron varios correos recientemente. Espera un momento y vuelve a intentar.',
      _ =>
        'No pudimos completar la solicitud. Revisa los datos e inténtalo de nuevo.',
    };
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Escribe tu correo.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Escribe un correo válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Escribe tu contraseña.';
    if (_isRegistering && value.length < 8) {
      return 'Usa al menos 8 caracteres.';
    }
    return null;
  }

  String? _validateDocumentNumber(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (normalized.length < 4 || normalized.length > 24) {
      return 'Escribe un número de documento válido.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Escribe un número de teléfono válido.';
    }
    return null;
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(today.year - 120),
      lastDate: today,
      helpText: 'Selecciona tu fecha de nacimiento',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthDate = selected;
      _birthDateController.text =
          '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: -130,
            right: -100,
            child: _GlowOrb(size: 310, opacity: .13),
          ),
          const Positioned(
            bottom: -170,
            left: -130,
            child: _GlowOrb(size: 360, opacity: .09),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 30),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandMark(),
                      const SizedBox(height: 32),
                      Text(
                        widget.authConfigured
                            ? (_isRegistering
                                  ? 'Únete a MAMBA'
                                  : 'Qué bueno verte')
                            : 'Estamos preparando MAMBA',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        widget.authConfigured
                            ? (_isRegistering
                                  ? 'Crea tu cuenta y empieza a descubrir.'
                                  : 'Inicia sesión para continuar tu próxima aventura.')
                            : 'La conexión segura se activa al configurar el proyecto.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 36,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: widget.authConfigured
                            ? _buildAuthForm(theme)
                            : _buildSetupState(theme),
                      ),
                      if (kDebugMode && !widget.authConfigured) ...[
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/feed'),
                          icon: const Icon(Icons.preview_outlined),
                          label: const Text('Continuar en vista previa'),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'EXPERIENCIAS QUE TE CONECTAN',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: .8),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isRegistering) ...[
            _AuthTextField(
              controller: _firstNamesController,
              label: 'Nombres',
              hint: 'Como aparecen en tu documento',
              icon: Icons.person_outline_rounded,
              validator: (value) => (value?.trim().isNotEmpty ?? false)
                  ? null
                  : 'Escribe tus nombres.',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _AuthTextField(
              controller: _lastNamesController,
              label: 'Apellidos',
              hint: 'Como aparecen en tu documento',
              icon: Icons.person_outline_rounded,
              validator: (value) => (value?.trim().isNotEmpty ?? false)
                  ? null
                  : 'Escribe tus apellidos.',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              decoration: const InputDecoration(
                labelText: 'Tipo de documento',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'cc', child: Text('Cédula de ciudadanía')),
                DropdownMenuItem(value: 'ce', child: Text('Cédula de extranjería')),
                DropdownMenuItem(value: 'ti', child: Text('Tarjeta de identidad')),
                DropdownMenuItem(value: 'ppt', child: Text('Permiso por Protección Temporal')),
                DropdownMenuItem(value: 'passport', child: Text('Pasaporte')),
              ],
              onChanged: (value) => setState(() => _documentType = value ?? 'cc'),
            ),
            const SizedBox(height: 16),
            _AuthTextField(
              controller: _documentNumberController,
              label: 'Número de documento',
              hint: 'Sin puntos ni espacios',
              icon: Icons.numbers_rounded,
              validator: _validateDocumentNumber,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _AuthTextField(
              controller: _birthDateController,
              label: 'Fecha de nacimiento',
              hint: 'Día / Mes / Año',
              icon: Icons.calendar_month_outlined,
              readOnly: true,
              onTap: _pickBirthDate,
              validator: (_) => _birthDate == null ? 'Selecciona tu fecha de nacimiento.' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _AuthTextField(
              controller: _phoneController,
              label: 'Teléfono de contacto',
              hint: '+57 300 000 0000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            Text(
              'Tus datos personales se guardan de forma privada y no aparecen en tu perfil público.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text('¿Cómo quieres empezar?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<AccountIntent>(
              segments: const [
                ButtonSegment(
                  value: AccountIntent.tourist,
                  icon: Icon(Icons.explore_outlined),
                  label: Text('Explorar'),
                ),
                ButtonSegment(
                  value: AccountIntent.experienceHost,
                  icon: Icon(Icons.storefront_outlined),
                  label: Text('Ofrecer planes'),
                ),
              ],
              selected: {_accountIntent},
              onSelectionChanged: (selection) =>
                  setState(() => _accountIntent = selection.first),
            ),
            if (_accountIntent == AccountIntent.experienceHost) ...[
              const SizedBox(height: 8),
              Text(
                'Tu cuenta seguirá siendo de turista. Esto solo indica tu interés; '
                'no habilita publicaciones ni sustituye la verificación de anfitrión.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
          ],
          _AuthTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
            icon: Icons.alternate_email_rounded,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            controller: _passwordController,
            label: 'Contraseña',
            hint: 'Mínimo 8 caracteres',
            icon: Icons.lock_outline_rounded,
            validator: _validatePassword,
            obscureText: !_isPasswordVisible,
            textInputAction: _isRegistering
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: _isRegistering ? null : (_) => _submit(),
            suffix: IconButton(
              tooltip: _isPasswordVisible
                  ? 'Ocultar contraseña'
                  : 'Mostrar contraseña',
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          if (!_isRegistering)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSubmitting ? null : _requestPasswordRecovery,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
          if (_isRegistering) ...[
            const SizedBox(height: 16),
            _AuthTextField(
              controller: _confirmationController,
              label: 'Confirma tu contraseña',
              hint: 'Escríbela de nuevo',
              icon: Icons.verified_user_outlined,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) => value == _passwordController.text
                  ? null
                  : 'Las contraseñas no coinciden.',
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _InlineMessage(message: _error!, isError: true),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 16),
            _InlineMessage(message: _notice!, isError: false),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 21,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    )
                  : Text(_isRegistering ? 'Crear cuenta' : 'Iniciar sesión'),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRegistering
                    ? '¿Ya tienes cuenta?'
                    : '¿Primera vez en MAMBA?',
                style: theme.textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: _isSubmitting ? null : _toggleMode,
                child: Text(_isRegistering ? 'Inicia sesión' : 'Regístrate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupState(ThemeData theme) {
    return Column(
      children: [
        const Icon(
          Icons.lock_clock_outlined,
          size: 38,
          color: AppColors.primary,
        ),
        const SizedBox(height: 14),
        Text(
          'Autenticación pendiente de configuración',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Define SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY al ejecutar la app. '
          'La llave secreta del servidor nunca debe incluirse en Flutter.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      onFieldSubmitted: onSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      autocorrect: false,
      enableSuggestions: !obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            color: const Color(0x2234D399),
            border: Border.all(color: const Color(0x5534D399)),
          ),
          child: const Icon(
            Icons.explore_rounded,
            color: AppColors.primary,
            size: 31,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'MAMBA',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Text(message, style: TextStyle(color: color, height: 1.35)),
    );
  }
}
