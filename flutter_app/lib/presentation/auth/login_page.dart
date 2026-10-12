import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../domain/repositories/repositories.dart';
import '../common/widgets.dart';
import 'bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _enableBiometric = false;
  bool _deviceHasBiometric = false;
  bool _autoPrompted = false;

  @override
  void initState() {
    super.initState();
    sl<BiometricAuthenticator>().isAvailable.then((v) {
      if (mounted) setState(() => _deviceHasBiometric = v);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<AuthBloc>();
      final s = bloc.state;
      if (s.failure != null) showAppSnack(context, s.failure!.message, error: true);
      // Acesso rápido ativado: já abre o prompt de biometria ao entrar no app
      if (s.promptBiometric && !_autoPrompted) {
        _autoPrompted = true;
        bloc.add(const BiometricLoginRequested());
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(LoginSubmitted(_email.text, _password.text, enableBiometric: _enableBiometric));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (p, c) => p.errorSeq != c.errorSeq && c.failure != null,
          listener: (context, s) => showAppSnack(context, s.failure!.message, error: true),
          builder: (context, state) {
            final primary = Theme.of(context).colorScheme.primary;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Image.asset('assets/images/champions_card.png', height: 120),
                      const SizedBox(height: 12),
                      const Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'TICKET'),
                          TextSpan(text: 'FUT', style: TextStyle(color: AppColors.neonCyan)),
                        ]),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'E-MAIL'),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'SENHA',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => Validators.required(v, 'Informe a senha'),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_deviceHasBiometric)
                        CheckboxListTile(
                          value: _enableBiometric,
                          onChanged: (v) => setState(() => _enableBiometric = v ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Ativar acesso rápido com biometria / Face ID', style: TextStyle(fontSize: 13)),
                        ),
                      const SizedBox(height: 12),
                      BusyButton(label: 'ENTRAR', busy: state.busy, onPressed: _submit),
                      if (state.biometricReady && _deviceHasBiometric) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: state.busy ? null : () => context.read<AuthBloc>().add(const BiometricLoginRequested()),
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('ENTRAR COM BIOMETRIA'),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: state.busy ? null : () => context.push('/register'),
                        child: Text('CRIAR CONTA', style: TextStyle(color: primary, letterSpacing: 2, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
