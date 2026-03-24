import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/good_habit/screens/add_good_habit_screen.dart';
import '../../features/bad_habit/screens/add_bad_habit_screen.dart';
import '../../features/bad_habit/screens/bad_habit_detail_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../shared/screens/main_shell.dart';
import '../../features/good_habit/screens/edit_good_habit_screen.dart';
import '../../shared/models/habit_model.dart';
import '../../features/bad_habit/screens/edit_bad_habit_screen.dart';
import '../../features/good_habit/screens/good_habit_detail_screen.dart';

// Route names
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const addGoodHabit = '/add-good-habit';
  static const addBadHabit = '/add-bad-habit';
  static const badHabitDetail = '/bad-habit/:id';
  static const stats = '/stats';
}

final appRouterProvider = Provider<GoRouter>((ref) {

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggedIn =
          Supabase.instance.client.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main shell dengan bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.stats,
            builder: (context, state) => const StatsScreen(),
          ),
        ],
      ),

      // Tambah habit
      GoRoute(
        path: AppRoutes.addGoodHabit,
        builder: (context, state) => const AddGoodHabitScreen(),
      ),
      GoRoute(
        path: AppRoutes.addBadHabit,
        builder: (context, state) => const AddBadHabitScreen(),
      ),

      // Detail bad habit
      GoRoute(
        path: AppRoutes.badHabitDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BadHabitDetailScreen(habitId: id);
        },
      ),
      //Detail good habit
      GoRoute(
        path: '/good-habit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GoodHabitDetailScreen(habitId: id);
        },
      ),
      //edit good habit
      GoRoute(
        path: '/edit-good-habit',
          builder: (context, state) {
          final habit = state.extra as HabitModel;
          return EditGoodHabitScreen(habit: habit);
        },    
      ),
      //edit bah habbit
      GoRoute(
      path: '/edit-bad-habit',
        builder: (context, state) {
        final habit = state.extra as HabitModel;
        return EditBadHabitScreen(habit: habit);
      },
    ),
    ],
  );
});
