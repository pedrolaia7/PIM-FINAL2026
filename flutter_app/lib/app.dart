import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/network/session_events.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/repositories.dart';
import 'domain/usecases/auth/auth_usecases.dart';
import 'presentation/auth/bloc/auth_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _auth = AuthBloc(
    login: sl<LoginUseCase>(),
    register: sl<RegisterUseCase>(),
    enrollFace: sl<EnrollFaceUseCase>(),
    biometricLogin: sl<BiometricLoginUseCase>(),
    restoreSession: sl<RestoreSessionUseCase>(),
    logout: sl<LogoutUseCase>(),
    repository: sl<AuthRepository>(),
    sessionEvents: sl<SessionEvents>(),
  )..add(const AuthStarted());

  late final GoRouter _router = buildRouter(_auth);

  @override
  void dispose() {
    _auth.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _auth,
      // O tema muda com o time do usuário (cores do clube), como no app web
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (p, c) => p.user?.team != c.user?.team,
        builder: (context, state) => MaterialApp.router(
          title: 'TicketFut',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.forTeam(state.user?.team),
          routerConfig: _router,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
