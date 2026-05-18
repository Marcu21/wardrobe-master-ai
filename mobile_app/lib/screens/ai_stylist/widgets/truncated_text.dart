import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';

class TruncatedText extends StatefulWidget {
  final String text;
  const TruncatedText({super.key, required this.text});

  @override
  State<TruncatedText> createState() => _TruncatedTextState();
}

class _TruncatedTextState extends State<TruncatedText> {
  bool _expanded = false;
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            maxLines: _expanded ? null : _maxLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
