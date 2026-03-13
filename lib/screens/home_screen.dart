import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import 'checkin_screen.dart';
import 'finish_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('EduCheck'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Session History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: provider.loadData,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _StatusBanner(provider: provider),
                const SizedBox(height: 28),
                _PrimaryActionButton(provider: provider),
                const SizedBox(height: 28),
                _StatsRow(provider: provider),
                const SizedBox(height: 28),
                _RecentSessions(provider: provider),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Status Banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final SessionProvider provider;
  const _StatusBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final session = provider.activeSession;

    if (session == null) {
      return _GradientCard(
        colors: const [Color(0xFF1A237E), Color(0xFF3949AB)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ready for Class?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap Check In to start tracking your learning session.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      );
    }

    return _GradientCard(
      colors: const [Color(0xFF1B5E20), Color(0xFF43A047)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF69F0AE),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SESSION ACTIVE',
                style: TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.expectedTopic,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Checked in at ${_fmtTime(session.checkInTime)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(_moodEmoji(session.mood),
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                _moodLabel(session.mood),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _moodEmoji(int m) =>
      const ['😟', '😐', '🙂', '😊', '😄'][(m - 1).clamp(0, 4)];

  static String _moodLabel(int m) =>
      const ['Struggling', 'Neutral', 'Okay', 'Good', 'Great!'][(m - 1).clamp(0, 4)];
}

class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  const _GradientCard({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Primary Action Button ────────────────────────────────────────────────────

class _PrimaryActionButton extends StatelessWidget {
  final SessionProvider provider;
  const _PrimaryActionButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    final hasActive = provider.hasActiveSession;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              hasActive ? const Color(0xFFC62828) : const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        icon: Icon(
          hasActive ? Icons.stop_circle_outlined : Icons.login_rounded,
          size: 24,
        ),
        label: Text(
          hasActive ? 'Finish Class' : 'Check In',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                hasActive ? const FinishScreen() : const CheckInScreen(),
          ),
        ),
      ),
    );
  }
}

// ── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SessionProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.sessions.length;
    final completed = provider.sessions.where((s) => !s.isActive).length;
    final avgMood = total == 0
        ? 0.0
        : provider.sessions.map((s) => s.mood).reduce((a, b) => a + b) /
            total;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total\nSessions',
            value: '$total',
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF1A237E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: '$completed',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Avg\nMood',
            value: total == 0 ? '—' : avgMood.toStringAsFixed(1),
            icon: Icons.sentiment_satisfied_rounded,
            color: const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Recent Sessions Preview ──────────────────────────────────────────────────

class _RecentSessions extends StatelessWidget {
  final SessionProvider provider;
  const _RecentSessions({required this.provider});

  static const _emojis = ['😟', '😐', '🙂', '😊', '😄'];

  @override
  Widget build(BuildContext context) {
    final sessions = provider.sessions.take(3).toList();
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...sessions.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Text(
                  _emojis[(s.mood - 1).clamp(0, 4)],
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.expectedTopic,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${s.checkInTime.day}/${s.checkInTime.month}/${s.checkInTime.year}',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (s.isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const Icon(Icons.check_circle,
                      color: Color(0xFF1B5E20), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
