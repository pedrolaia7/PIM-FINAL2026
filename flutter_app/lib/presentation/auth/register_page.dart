import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_args.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/team.dart';
import '../common/widgets.dart';
import 'bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cpf = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _team;
  int _plan = 0;
  bool _consent = false;

  static const _plans = <int, String>{
    0: 'SEM PLANO (SÓ INGRESSO)',
    5: 'SÓCIO BRONZE - 5% DESC.',
    10: 'SÓCIO PRATA - 10% DESC.',
    20: 'SÓCIO OURO - 20% DESC.',
  };

  @override
  void dispose() {
    for (final c in [_name, _cpf, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (!_consent) {
      showAppSnack(context, 'Autorize o uso da biometria facial para continuar.', error: true);
      return;
    }
    context.read<AuthBloc>().add(RegisterSubmitted(RegisterData(
          name: _name.text.trim(),
          cpf: Validators.digits(_cpf.text),
          email: _email.text.trim(),
          password: _password.text,
          team: _team!,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRIAR CONTA')),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (p, c) => p.errorSeq != c.errorSeq || (!p.justRegistered && c.justRegistered),
          listener: (context, s) {
            if (s.justRegistered) {
              // Próximo passo obrigatório do cadastro: selfie para o reconhecimento facial
              context.go('/face-enroll', extra: FaceEnrollArgs(planPercent: _plan, fromRegistration: true));
            } else if (s.failure != null) {
              showAppSnack(context, s.failure!.message, error: true);
            }
          },
          builder: (context, state) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _form,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'NOME COMPLETO'),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cpf,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, Masks.cpf()],
                      decoration: const InputDecoration(labelText: 'CPF'),
                      validator: Validators.cpf,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-MAIL'),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'SENHA', helperText: 'Mínimo de 8 caracteres, com letras e números'),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _team,
                      decoration: const InputDecoration(labelText: 'FILIAÇÃO (TIME)'),
                      items: [
                        for (final t in TeamInfo.all)
                          DropdownMenuItem(value: t.slug, child: Row(children: [TeamLogo(t.slug, size: 22), const SizedBox(width: 10), Text(t.name)])),
                      ],
                      onChanged: (v) => setState(() => _team = v),
                      validator: (v) => v == null ? 'Escolha seu time' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      value: _plan,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'PLANO DE SÓCIO'),
                      items: [for (final e in _plans.entries) DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))],
                      onChanged: (v) => setState(() => _plan = v ?? 0),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Autorizo o uso da minha biometria facial para confirmar compras. '
                        'Guardamos apenas uma representação matemática do rosto (não a foto) e você pode excluí-la quando quiser.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BusyButton(label: 'CONTINUAR', busy: state.busy, onPressed: _submit),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
