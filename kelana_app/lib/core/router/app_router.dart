import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/chat/chat_parser_screen.dart';
import '../../features/places/recommendations_screen.dart';
import '../../features/itinerary/itinerary_detail_screen.dart';
import '../../features/saved/saved_itineraries_screen.dart';
import '../../features/profile/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatParserScreen(),
    ),
    GoRoute(
      path: '/recommendations',
      builder: (context, state) => const RecommendationsScreen(),
    ),
    GoRoute(
      path: '/itinerary',
      builder: (context, state) => const ItineraryDetailScreen(),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) => const SavedItinerariesScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
