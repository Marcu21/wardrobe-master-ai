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
      appBar: AppBar(
        title: const Text(
          'Wardrobe Master',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Lookbook moved to main navigation
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Style Calendar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.eco_outlined),
            tooltip: 'Sustainability Tracker',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SustainabilityScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 48), // Opens downwards
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: _buildUserAvatar(),
            onSelected: (value) async {
              if (value == 'settings') {
                // TODO: Implement settings screen navigation
              } else if (value == 'logout') {
                await FirebaseService().signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.black87, size: 20),
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
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseService().currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String name = '';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    name = data['name'] ?? '';
                  }
                } else if (FirebaseService().currentUser?.displayName != null) {
                  name = FirebaseService().currentUser!.displayName!;
                }

                return Text(
                  name.isNotEmpty ? "Hello, $name!" : "Hello!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              "Let's see what we are wearing today.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
            const SizedBox(height: 24),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.black, Color(0xFF424242)], // Black to Dark Grey
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Ready to pick your outfit?",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Based on the weather and your style, I recommend a layered look today.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiStylistChatScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShoppingAssistantScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
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
        ),
      ),
    );
  }

  Widget _buildMyTripsCard() {
    final uid = FirebaseService().currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: uid != null
            ? FirebaseFirestore.instance
                  .collection('trips')
                  .where('user_id', isEqualTo: uid)
                  .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          final hasTrips = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyTripsScreen()),
                  );
                },
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        Icons.luggage,
                        size: 100,
                        color: Colors.blueAccent.withValues(alpha: 0.03),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
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
                                    color: Colors.blueAccent.shade700
                                        .withValues(alpha: 0.8),
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
                              color: Colors.blueAccent.withValues(alpha: 0.1),
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVirtualDressingRoomCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VirtualDressingRoomScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                        color: Colors.purple.shade700.withValues(alpha: 0.8),
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
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.checkroom,
                  color: Colors.purple,
                  size: 28,
                ),
              ),
            ],
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
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(24),
        ),
        height: 150,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 10),
              Text(
                "Checking weather...",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(24),
        ),
        height: 150,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 32, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                "Weather unavailable.",
                style: TextStyle(color: Colors.red[800], fontSize: 13),
              ),
              TextButton(onPressed: onRetry, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    if (weather == null) return const SizedBox.shrink();

    final gradient = _getGradient(weather!.condition, weather!.iconCode);
    final icon = _getIconForCondition(weather!.condition, weather!.iconCode);
    final now = DateTime.now();
    final dateString =
        "${_getWeekday(now.weekday)}, ${now.day} ${_getMonth(now.month)}";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ultra-Compact Single Row Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: City & Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather!.cityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18, // Reduced to 18
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateString,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13, // Reduced to 13
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Right: Temp & Icon (Tight Row)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${weather!.temperature}°",
                    style: const TextStyle(
                      fontSize: 38, // Reduced to 38
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 38, // Matches text size
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16), // Breathing room
          // 2. Hourly Forecast Glass Strip (Compact)
          Container(
            height: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.15,
              ), // Slightly more transparent
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: weather!.forecast.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final item = weather!.forecast[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.timeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      _getIconForCondition(item.condition, item.iconCode),
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${item.temperature}°",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
    bool isNight = iconCode.endsWith('n'); // verificam daca e noapte

    if (condition.contains('clear') || condition.contains('sun')) {
      if (isNight) {
        // cer senin de noapte (Albastru foarte inchis spre Negru)
        return const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      // cer senin de zi
      return const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFEB3B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (condition.contains('cloud')) {
      return const LinearGradient(
        colors: [Color(0xFF607D8B), Color(0xFF90A4AE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (condition.contains('snow')) {
      return const LinearGradient(
        colors: [Color(0xFF81D4FA), Color(0xFFE1F5FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // fallback
    return isNight
        ? const LinearGradient(
            colors: [Color(0xFF311B92), Color(0xFF512DA8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF5E35B1), Color(0xFF9575CD)],
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
