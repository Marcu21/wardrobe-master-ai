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
      backgroundColor: Colors.grey[50],
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
        backgroundColor: Colors.grey[50]!.withOpacity(0.9),
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 10,
                  right: -10,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEADDFF).withOpacity(0.4),
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFCCBC).withOpacity(0.3),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: const SizedBox(),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 4.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseService().currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String name = '';
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            if (data != null) {
                              name = data['name'] ?? '';
                            }
                          } else if (FirebaseService()
                                  .currentUser
                                  ?.displayName !=
                              null) {
                            name = FirebaseService().currentUser!.displayName!;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Hello,",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w200,
                                  color: Colors.black87,
                                ),
                              ),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Colors.black,
                                        Color(0xFF424242),
                                        Colors.black87,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                child: Text(
                                  name.isNotEmpty ? name : "There",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Discover today's aesthetic.",
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildWeatherCard(),
            const SizedBox(height: 24),
            _buildAIStylistCard(),
            const SizedBox(height: 16),
            _buildShoppingAssistantCard(),
            const SizedBox(height: 16),
            _buildVirtualDressingRoomCard(),
            _buildMyTripsCard(),
            const SizedBox(height: kBottomNavigationBarHeight + 60),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final user = FirebaseService().currentUser;
    if (user == null) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blueAccent,
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
          backgroundColor: Colors.blueAccent,
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

  Widget _buildAIStylistCard() {
    return _GlassNavCard(
      accentColor: Colors.black87,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiStylistChatScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Stylist",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Ready to pick your outfit?",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Based on the weather and your style, I recommend a layered look today.",
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiStylistChatScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Generate Outfit",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingAssistantCard() {
    return _GlassNavCard(
      accentColor: Colors.teal,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingAssistantScreen()),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Should I Buy This?",
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Scan an item in-store to see its Wardrobe Match Score.",
                  style: TextStyle(color: Colors.teal.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: Colors.teal,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTripsCard() {
    final uid = FirebaseService().currentUser?.uid;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: uid != null
            ? FirebaseFirestore.instance
                  .collection('trips')
                  .where('user_id', isEqualTo: uid)
                  .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          return _GlassNavCard(
            accentColor: Colors.blueAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyTripsScreen()),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Smart Packing",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Plan your travel outfits with AI-powered capsule wardrobes.",
                        style: TextStyle(
                          color: Colors.blueAccent.shade700.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.luggage_rounded,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVirtualDressingRoomCard() {
    return _GlassNavCard(
      accentColor: Colors.purple,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VirtualDressingRoomScreen()),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Virtual Dressing Room",
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Mix, match, and visualize your outfits on a digital canvas.",
                  style: TextStyle(
                    color: Colors.purple.shade700.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.checkroom, color: Colors.purple, size: 28),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Glass Navigation Card ───────────────────────────────────────────
class _GlassNavCard extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  const _GlassNavCard({
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_GlassNavCard> createState() => _GlassNavCardState();
}

class _GlassNavCardState extends State<_GlassNavCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: GestureDetector(
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.accentColor.withOpacity(0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.14),
                  blurRadius: 22,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

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
    if (isLoading) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mimic city name skeleton
            Container(
              width: 120,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            // Mimic condition skeleton
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            // Mimic hourly strip skeleton
            Container(
              height: 76,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black.withOpacity(0.25),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Checking weather...",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.35),
                        fontWeight: FontWeight.w400,
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

    if (error != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 28,
              color: Colors.black.withOpacity(0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Weather unavailable",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.45),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (weather == null) return const SizedBox.shrink();

    final gradient = _getGradient(weather!.condition, weather!.iconCode);
    final icon = _getIconForCondition(weather!.condition, weather!.iconCode);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: city + condition
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather!.cityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather!.condition,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                // Right: big temperature + icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${weather!.temperature}\u00b0",
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(icon, size: 32, color: Colors.white70),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Hourly forecast strip ──────────────────────────────
            Container(
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: weather!.forecast.length,
                separatorBuilder: (_, __) => Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.white.withOpacity(0.15),
                ),
                itemBuilder: (context, index) {
                  final item = weather!.forecast[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Icon(
                          _getIconForCondition(item.condition, item.iconCode),
                          size: 18,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${item.temperature}\u00b0",
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
    );
  }

  String _getWeekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  LinearGradient _getGradient(String condition, String iconCode) {
    condition = condition.toLowerCase();
    bool isNight = iconCode.endsWith('n');

    if (condition.contains('clear') || condition.contains('sun')) {
      if (isNight) {
        return const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      return const LinearGradient(
        colors: [Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFFB300)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (condition.contains('cloud')) {
      return const LinearGradient(
        colors: [Color(0xFF455A64), Color(0xFF607D8B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return const LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (condition.contains('snow')) {
      return const LinearGradient(
        colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF00838F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return isNight
        ? const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  IconData _getIconForCondition(String condition, String iconCode) {
    condition = condition.toLowerCase();
    bool isNight = iconCode.endsWith('n'); // verificam daca e noapte

    if (condition.contains('rain') || condition.contains('drizzle')) {
      return CupertinoIcons.drop_fill;
    } else if (condition.contains('cloud')) {
      return CupertinoIcons.cloud_fill;
    } else if (condition.contains('snow')) {
      return CupertinoIcons.snow;
    } else if (condition.contains('clear') || condition.contains('sun')) {
      return isNight
          ? CupertinoIcons.moon_stars_fill
          : CupertinoIcons.sun_max_fill;
    }

    // default
    return isNight
        ? CupertinoIcons.moon_stars_fill
        : CupertinoIcons.sun_max_fill;
  }
}
