import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/weather_service.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';

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
                    foregroundColor: kPrimary,
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
