import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_stylist_chat_screen.dart';
import 'calendar_screen.dart';
import 'sustainability_screen.dart';
import 'shopping_assistant_screen.dart';
import 'my_trips_screen.dart';
import 'virtual_dressing_room_screen.dart';
import 'package:mobile_app/theme/app_colors.dart';
import '../widgets/glassmorphism_card.dart';

// Per-screen blob colours
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
            icon: _buildUserAvatar(),
            onSelected: (value) async {
              if (value == 'logout') await FirebaseService().signOut();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: Colors.black87,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
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
          // Background
          Positioned.fill(child: ColoredBox(color: kBgColor)),

          // Blobs
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

          // Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                    height:
                        MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        10,
                  ),
                  _buildHeroSection(),
                  const SizedBox(height: 24),
                  _buildWeatherCard(),
                  const SizedBox(height: 16),
                  _buildAIStylistCard(),
                  const SizedBox(height: 12),
                  _buildDressingRoomCard(),
                  const SizedBox(height: 12),
                  _buildShoppingCard(),
                  const SizedBox(height: 12),
                  _buildSmartPackingCard(),
                  const SizedBox(height: kBottomNavigationBarHeight + 66),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final now = DateTime.now();
            const months = [
              'JANUARY',
              'FEBRUARY',
              'MARCH',
              'APRIL',
              'MAY',
              'JUNE',
              'JULY',
              'AUGUST',
              'SEPTEMBER',
              'OCTOBER',
              'NOVEMBER',
              'DECEMBER',
            ];
            const weekdays = [
              'MONDAY',
              'TUESDAY',
              'WEDNESDAY',
              'THURSDAY',
              'FRIDAY',
              'SATURDAY',
              'SUNDAY',
            ];
            final dateStr =
                '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
            return Text(
              dateStr,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3.0,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.35),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseService().currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String name = '';
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) name = data['name'] ?? '';
            } else if (FirebaseService().currentUser?.displayName != null) {
              name = FirebaseService().currentUser!.displayName!;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hello,",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.black54,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  name.isNotEmpty ? name : "There",
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.05,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        const Text(
          "Discover today's aesthetic.",
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black45,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAIStylistCard() {
    return _HomeCard(
      shadowColor: const Color(0xFF4F46E5),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiStylistChatScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Stylist",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      "Your personal fashion advisor",
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Tell me where you're going and I'll build a perfect outfit from your wardrobe.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.52),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiStylistChatScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Generate Outfit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDressingRoomCard() {
    return _HomeCard(
      shadowColor: const Color(0xFF673AB7),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VirtualDressingRoomScreen()),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF673AB7).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.checkroom,
              color: Color(0xFF673AB7),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dressing Room",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Mix & match pieces from your wardrobe",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: Colors.black.withOpacity(0.25),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingCard() {
    return _HomeCard(
      shadowColor: const Color(0xFF009688),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingAssistantScreen()),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.doc_text_search,
              color: Color(0xFF009688),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Should I Buy This?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Scan any item to see if it fits your style",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: Colors.black.withOpacity(0.25),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartPackingCard() {
    final uid = FirebaseService().currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: uid != null
          ? FirebaseFirestore.instance
                .collection('trips')
                .where('user_id', isEqualTo: uid)
                .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        return _HomeCard(
          shadowColor: const Color(0xFF1565C0),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyTripsScreen()),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.luggage_rounded,
                  color: Color(0xFF1565C0),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Smart Packing",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "Build the perfect wardrobe for any trip",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherCard() {
    return DynamicWeatherCard(
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
    );
  }

  Widget _buildUserAvatar() {
    final user = FirebaseService().currentUser;
    if (user == null) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: kPrimary,
        child: Icon(Icons.person, color: Colors.white, size: 20),
      );
    }

    final photoUrl = user.photoURL;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(radius: 16, backgroundImage: NetworkImage(photoUrl));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String fallbackLetter = 'U';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null &&
              data['name'] != null &&
              data['name'].toString().trim().isNotEmpty) {
            fallbackLetter = data['name']
                .toString()
                .trim()
                .substring(0, 1)
                .toUpperCase();
          } else if (user.displayName != null &&
              user.displayName!.trim().isNotEmpty) {
            fallbackLetter = user.displayName!
                .trim()
                .substring(0, 1)
                .toUpperCase();
          } else if (user.email != null && user.email!.trim().isNotEmpty) {
            fallbackLetter = user.email!.trim().substring(0, 1).toUpperCase();
          }
        } else if (user.displayName != null &&
            user.displayName!.trim().isNotEmpty) {
          fallbackLetter = user.displayName!
              .trim()
              .substring(0, 1)
              .toUpperCase();
        } else if (user.email != null && user.email!.trim().isNotEmpty) {
          fallbackLetter = user.email!.trim().substring(0, 1).toUpperCase();
        }

        return CircleAvatar(
          radius: 16,
          backgroundColor: kPrimary,
          child: Text(
            fallbackLetter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}

// Reusable glass card

class _HomeCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color shadowColor;

  const _HomeCard({
    required this.onTap,
    required this.child,
    this.shadowColor = kPrimary,
  });

  @override
  State<_HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<_HomeCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: widget.shadowColor.withOpacity(0.14),
                blurRadius: 16,
                spreadRadius: 0,
                offset: Offset.zero,
              ),
              BoxShadow(
                color: widget.shadowColor.withOpacity(0.07),
                blurRadius: 32,
                spreadRadius: 3,
                offset: Offset.zero,
              ),
            ],
          ),
          child: GlassmorphismCard(
            sigma: 12,
            colorOpacity: 0.92,
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(18),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// Weather skeleton

class _WeatherSkeleton extends StatefulWidget {
  const _WeatherSkeleton();

  @override
  State<_WeatherSkeleton> createState() => _WeatherSkeletonState();
}

class _WeatherSkeletonState extends State<_WeatherSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _block(double w, double h, double opacity, {double radius = 6}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(opacity),
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut).value;
        final hi = 0.08 + t * 0.06;
        final lo = hi * 0.6;
        final vlo = hi * 0.4;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: kPrimary.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2,
                offset: Offset.zero,
              ),
              BoxShadow(
                color: kPrimary.withOpacity(0.04),
                blurRadius: 40,
                spreadRadius: 4,
                offset: Offset.zero,
              ),
            ],
          ),
          child: GlassmorphismCard(
            sigma: 12,
            colorOpacity: 0.80,
            borderRadius: BorderRadius.circular(24),
            borderColor: Colors.white.withOpacity(0.90),
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _block(110, 18, hi),
                                  const SizedBox(height: 7),
                                  _block(75, 11, lo),
                                  const SizedBox(height: 5),
                                  _block(58, 10, vlo),
                                ],
                              ),
                            ),
                          ),
                          _block(72, 50, hi, radius: 10),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            5,
                            (_) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _block(28, 9, lo, radius: 3),
                                const SizedBox(height: 7),
                                _block(14, 14, hi, radius: 7),
                                const SizedBox(height: 7),
                                _block(22, 11, lo, radius: 3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Weather card

class DynamicWeatherCard extends StatelessWidget {
  final WeatherModel? weather;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const DynamicWeatherCard({
    super.key,
    required this.weather,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _WeatherSkeleton();

    if (error != null) {
      return GlassmorphismCard(
        sigma: 12,
        colorOpacity: 0.75,
        borderRadius: BorderRadius.circular(28),
        borderColor: Colors.white.withOpacity(0.9),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 16, 14, 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 22,
                  color: Colors.black.withOpacity(0.28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Weather unavailable",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.42),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
        );
    }

    if (weather == null) return const SizedBox.shrink();

    final gradient = _getGradient(weather!.condition, weather!.iconCode);
    final bgIcon = _getIconForCondition(weather!.condition, weather!.iconCode);
    final description = _capitalize(weather!.description);

    int? minTemp;
    int? maxTemp;
    if (weather!.forecast.isNotEmpty) {
      final temps = weather!.forecast.map((f) => f.temperature).toList();
      minTemp = temps.reduce((a, b) => a < b ? a : b);
      maxTemp = temps.reduce((a, b) => a > b ? a : b);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative ghost icon
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                bgIcon,
                size: 110,
                color: Colors.white.withOpacity(0.08),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: city+description left, temperature right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.location_fill,
                                    size: 10,
                                    color: Colors.white.withOpacity(0.70),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    weather!.cityName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (minTemp != null && maxTemp != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "H:$maxTemp°  L:$minTemp°",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Text(
                        "${weather!.temperature}°",
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Forecast strip
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                        width: 1,
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      scrollDirection: Axis.horizontal,
                      itemCount: weather!.forecast.length,
                      separatorBuilder: (_, __) => Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 14),
                        color: Colors.white.withOpacity(0.12),
                      ),
                      itemBuilder: (context, index) {
                        final item = weather!.forecast[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.timeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.55),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Icon(
                                _getIconForCondition(
                                  item.condition,
                                  item.iconCode,
                                ),
                                size: 15,
                                color: Colors.white.withOpacity(0.88),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${item.temperature}°",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  LinearGradient _getGradient(String condition, String iconCode) {
    condition = condition.toLowerCase();
    final isNight = iconCode.endsWith('n');

    if (condition.contains('clear') || condition.contains('sun')) {
      if (isNight) {
        return const LinearGradient(
          colors: [Color(0xFF0F1B4D), Color(0xFF1A2B6D), Color(0xFF243B8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      return const LinearGradient(
        colors: [Color(0xFFD95F02), Color(0xFFF07C00), Color(0xFFFFAA00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (condition.contains('cloud')) {
      return const LinearGradient(
        colors: [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF6B8794)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return const LinearGradient(
        colors: [Color(0xFF0A2E5C), Color(0xFF0D47A1), Color(0xFF1565C0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (condition.contains('snow')) {
      return const LinearGradient(
        colors: [Color(0xFF1A3A5C), Color(0xFF1E4D8C), Color(0xFF1A6B8A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return const LinearGradient(
        colors: [Color(0xFF1A0533), Color(0xFF2D1B69), Color(0xFF1A237E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (condition.contains('mist') ||
        condition.contains('fog') ||
        condition.contains('haze')) {
      return const LinearGradient(
        colors: [Color(0xFF5D6D7E), Color(0xFF7F8C8D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return isNight
        ? const LinearGradient(
            colors: [Color(0xFF0F1B4D), Color(0xFF1A2B6D), Color(0xFF243B8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF4527A0), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  IconData _getIconForCondition(String condition, String iconCode) {
    condition = condition.toLowerCase();
    final isNight = iconCode.endsWith('n');

    if (condition.contains('thunder') || condition.contains('storm')) {
      return CupertinoIcons.bolt_fill;
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return CupertinoIcons.drop_fill;
    } else if (condition.contains('snow')) {
      return CupertinoIcons.snow;
    } else if (condition.contains('mist') ||
        condition.contains('fog') ||
        condition.contains('haze')) {
      return CupertinoIcons.cloud_fog_fill;
    } else if (condition.contains('cloud')) {
      return CupertinoIcons.cloud_fill;
    } else if (condition.contains('clear') || condition.contains('sun')) {
      return isNight
          ? CupertinoIcons.moon_stars_fill
          : CupertinoIcons.sun_max_fill;
    }

    return isNight
        ? CupertinoIcons.moon_stars_fill
        : CupertinoIcons.sun_max_fill;
  }
}
