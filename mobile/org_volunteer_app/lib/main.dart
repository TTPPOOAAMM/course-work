import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

import 'bloc/event/event_bloc.dart';
import 'screens/create_event_screen.dart';
import 'bloc/my_events/my_events_bloc.dart';

import 'bloc/applications/applications_bloc.dart';
import 'screens/event_applications_screen.dart';
void main() {
  runApp(const VolunteerOrgApp());
}

class VolunteerOrgApp extends StatelessWidget {
  const VolunteerOrgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc()..add(AuthCheckStatus()),
      child: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/auth',
      refreshListenable: GoRouterRefreshStream(context.read<AuthBloc>().stream),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final isAuthLocation = state.matchedLocation == '/auth';

        if (authState is AuthInitial || authState is AuthLoading) {
          return null;
        }

        if (authState is Authenticated) {
          return isAuthLocation ? '/' : null;
        }

        if (authState is Unauthenticated || authState is AuthFailure) {
          return isAuthLocation ? null : '/auth';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider(
            create: (context) => MyEventsBloc(),
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/create-event',
          builder: (context, state) => BlocProvider(
            create: (context) => EventBloc(),
            child: const CreateEventScreen(),
          ),
        ),
        GoRoute(
          path: '/event-applications/:id',
          builder: (context, state) {
            final eventId = int.parse(state.pathParameters['id']!);
            return BlocProvider(
              create: (context) => ApplicationsBloc(),
              child: EventApplicationsScreen(eventId: eventId),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Организатор Мероприятий',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEB6864),
          primary: const Color(0xFFEB6864), 
          onPrimary: Colors.white, 
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}