import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'package:mobile_app/screens/auth_wrapper.dart';
import 'package:mobile_app/screens/main_navigation.dart';
import 'package:mobile_app/screens/add_clothing/add_clothing_screen.dart';
import 'package:mobile_app/screens/clothing_detail/clothing_detail_screen.dart';
import 'package:mobile_app/screens/outfit_detail/outfit_detail_screen.dart';
import 'package:mobile_app/screens/virtual_dressing_room/virtual_dressing_room_screen.dart';
import 'package:mobile_app/screens/trip_view/trip_view_screen.dart';
import 'package:mobile_app/screens/packing_setup/packing_setup_screen.dart';
import 'package:mobile_app/screens/my_trips/my_trips_screen.dart';
import 'package:mobile_app/screens/calendar/calendar_screen.dart';
import 'package:mobile_app/screens/sustainability/sustainability_screen.dart';
import 'package:mobile_app/screens/ai_stylist/ai_stylist_chat_screen.dart';
import 'package:mobile_app/screens/shopping_assistant/shopping_assistant_screen.dart';
import 'package:mobile_app/screens/laundry/laundry_screen.dart';
import 'package:mobile_app/screens/match_result/match_result_screen.dart';
import 'package:mobile_app/screens/item_selection/item_selection_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.auth:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainNavigation());

      case AppRoutes.addClothing:
        final args = settings.arguments as AddClothingArgs?;
        return MaterialPageRoute(
          builder: (_) => AddClothingScreen(
            initialAnalysisResult: args?.initialAnalysisResult,
            initialImageFile: args?.initialImageFile,
          ),
        );

      case AppRoutes.clothingDetail:
        final args = settings.arguments as ClothingDetailArgs;
        return MaterialPageRoute(
          builder: (_) => ClothingDetailScreen(itemData: args.itemData),
        );

      case AppRoutes.outfitDetail:
        final args = settings.arguments as OutfitDetailArgs;
        return MaterialPageRoute(
          builder: (_) => OutfitDetailScreen(
            outfitData: args.outfitData,
            outfitId: args.outfitId,
          ),
        );

      case AppRoutes.dressingRoom:
        final args = settings.arguments as VirtualDressingRoomArgs?;
        return MaterialPageRoute(
          builder: (_) =>
              VirtualDressingRoomScreen(initialItemIds: args?.initialItemIds),
        );

      case AppRoutes.tripView:
        final args = settings.arguments as TripViewArgs;
        return MaterialPageRoute(
          builder: (_) => TripViewScreen(
            destination: args.destination,
            days: args.days,
            vibe: args.vibe,
            dateRange: args.dateRange,
            initialTripData: args.initialTripData,
            tripPlans: args.tripPlans,
            luggageSize: args.luggageSize,
            tripId: args.tripId,
          ),
        );

      case AppRoutes.tripSetup:
        return MaterialPageRoute(builder: (_) => const PackingSetupScreen());

      case AppRoutes.trips:
        return MaterialPageRoute(builder: (_) => const MyTripsScreen());

      case AppRoutes.calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());

      case AppRoutes.sustainability:
        return MaterialPageRoute(builder: (_) => const SustainabilityScreen());

      case AppRoutes.aiStylist:
        return MaterialPageRoute(builder: (_) => const AiStylistChatScreen());

      case AppRoutes.shopping:
        return MaterialPageRoute(
            builder: (_) => const ShoppingAssistantScreen());

      case AppRoutes.laundry:
        return MaterialPageRoute(builder: (_) => const LaundryScreen());

      case AppRoutes.matchResult:
        final args = settings.arguments as MatchResultArgs;
        return MaterialPageRoute(
          builder: (_) => MatchResultScreen(
            scannedItemData: args.scannedItemData,
            imageFile: args.imageFile,
          ),
        );

      case AppRoutes.itemSelection:
        final args = settings.arguments as ItemSelectionArgs;
        return MaterialPageRoute(
          builder: (_) =>
              ItemSelectionScreen(initialSelectedIds: args.initialSelectedIds),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
