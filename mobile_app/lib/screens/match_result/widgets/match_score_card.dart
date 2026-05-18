import 'package:flutter/material.dart';

Color _getScoreColor(int score) {
  if (score < 50) return const Color(0xFFE53935);
  if (score < 75) return const Color(0xFFE65100);
  return const Color(0xFF00695C);
}

class MatchScoreCard extends StatelessWidget {
  final int matchScore;

  const MatchScoreCard({super.key, required this.matchScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _getScoreColor(matchScore).withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(matchScore).withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: matchScore / 100,
                  strokeWidth: 7,
                  backgroundColor:
                      _getScoreColor(matchScore).withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getScoreColor(matchScore),
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                "$matchScore%",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _getScoreColor(matchScore),
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchScore >= 75
                      ? "Great match"
                      : matchScore >= 50
                      ? "Good match"
                      : "Low match",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _getScoreColor(matchScore),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Wardrobe compatibility score",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
