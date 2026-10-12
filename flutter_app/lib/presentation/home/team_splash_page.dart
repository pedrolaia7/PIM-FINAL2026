import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/team_theme.dart';
import '../auth/bloc/auth_bloc.dart';
import '../common/widgets.dart';

/// Tela de boas-vindas com a identidade do time (porta do splash.js do app web).
class TeamSplashPage extends StatefulWidget {
  const TeamSplashPage({super.key});

  @override
  State<TeamSplashPage> createState() => _TeamSplashPageState();
}

class _TeamSplashPageState extends State<TeamSplashPage> {
  int _idx = 0;
  Timer? _phraseTimer;
  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();
    final team = TeamTheme.of(context.read<AuthBloc>().state.user?.team);
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => _idx = (_idx + 1) % team.phrases.length);
    });
    _doneTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) context.go('/matches');
    });
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slug = context.read<AuthBloc>().state.user?.team ?? TeamTheme.defaultSlug;
    final team = TeamTheme.of(slug);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [team.splashBg.first, team.splashBg.last, team.splashBg.first],
          ),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (slug != TeamTheme.defaultSlug) TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.08),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: TeamLogo(slug, size: 96),
            ),
            const SizedBox(height: 24),
            Text(team.welcome, style: TextStyle(fontSize: 12, letterSpacing: 4, color: team.accent2.withAlpha(180))),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Padding(
                key: ValueKey(_idx),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  team.phrases[_idx],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3, color: team.primary),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
