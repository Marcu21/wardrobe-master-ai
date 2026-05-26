import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:mobile_app/navigation/app_routes.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'home_view_model.dart';
import 'widgets/weather_card.dart';
import 'widgets/hero_section.dart';
import 'widgets/ai_stylist_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/user_avatar.dart';

const _kBlob1 = kGlowPrimary;
const _kBlob2 = kGlowPrimary2;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
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
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.calendar),
          ),
          IconButton(
            icon: const Icon(Icons.eco_outlined, color: Colors.black87),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.sustainability),
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const HomeUserAvatar(),
            onSelected: (value) async {
              if (value == 'logout') await AuthService().signOut();
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
                    weather: vm.weather,
                    isLoading: vm.isLoading,
                    error: vm.error,
                    onRetry: () => vm.fetchWeather(),
                  ),
                  const SizedBox(height: 16),
                  AiStylistCard(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.aiStylist),
                  ),
                  const SizedBox(height: 12),
                  QuickActionsColumn(
                    onDressingRoomTap: () =>
                        Navigator.pushNamed(context, AppRoutes.dressingRoom),
                    onShoppingTap: () =>
                        Navigator.pushNamed(context, AppRoutes.shopping),
                    onSmartPackingTap: () =>
                        Navigator.pushNamed(context, AppRoutes.trips),
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

