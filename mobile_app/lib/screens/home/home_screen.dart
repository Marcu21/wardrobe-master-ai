import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/weather_service.dart';
import '../../services/firebase_service.dart';
import '../ai_stylist_chat_screen.dart';
import '../calendar_screen.dart';
import '../sustainability_screen.dart';
import '../shopping_assistant_screen.dart';
import '../my_trips_screen.dart';
import '../virtual_dressing_room_screen.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/weather_card.dart';
import 'widgets/hero_section.dart';
import 'widgets/ai_stylist_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/user_avatar.dart';

const _kBlob1 = Color(0x384F46E5);
const _kBlob2 = Color(0x206352D2);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final position = await _weatherService.determinePosition();
      final weather = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Wardrobe Master',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.eco_outlined, color: Colors.black87),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SustainabilityScreen()),
            ),
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const HomeUserAvatar(),
            onSelected: (value) async {
              if (value == 'logout') await FirebaseService().signOut();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.black87, size: 20),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: kBgColor)),
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - v)),
                child: Opacity(opacity: v, child: child),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
                  ),
                  const HeroSection(),
                  const SizedBox(height: 24),
                  DynamicWeatherCard(
                    weather: _weather,
                    isLoading: _isLoading,
                    error: _error,
                    onRetry: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _fetchWeather();
                    },
                  ),
                  const SizedBox(height: 16),
                  AiStylistCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiStylistChatScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  QuickActionsColumn(
                    onDressingRoomTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VirtualDressingRoomScreen()),
                    ),
                    onShoppingTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShoppingAssistantScreen()),
                    ),
                    onSmartPackingTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyTripsScreen()),
                    ),
                  ),
                  const SizedBox(height: kBottomNavigationBarHeight + 66),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
