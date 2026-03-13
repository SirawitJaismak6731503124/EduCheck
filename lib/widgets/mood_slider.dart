import 'package:flutter/material.dart';

class MoodSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const MoodSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _emojis = ['😟', '😐', '🙂', '😊', '😄'];
  static const _labels = ['Struggling', 'Neutral', 'Okay', 'Good', 'Great!'];

  @override
  Widget build(BuildContext context) {
    final index = (value - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(_emojis[index], style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          Text(
            _labels[index],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF1A237E),
              thumbColor: const Color(0xFF1A237E),
              inactiveTrackColor: const Color(0xFFBBDEFB),
              overlayColor: const Color(0xFF1A237E).withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                5,
                (i) => Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i + 1 == value
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: i + 1 == value
                        ? const Color(0xFF1A237E)
                        : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
