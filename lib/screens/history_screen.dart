import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/class_session.dart';
import '../providers/session_provider.dart';
import '../widgets/form_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Session History',
      body: Consumer<SessionProvider>(
        builder: (context, provider, _) {
          final sessions = provider.sessions;

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 72, color: Colors.black.withOpacity(0.18)),
                  const SizedBox(height: 16),
                  const Text(
                    'No sessions yet',
                    style: TextStyle(
                        color: Colors.black38,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check in to your first class to get started.',
                    style: TextStyle(color: Colors.black26, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _SessionCard(session: sessions[i]),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ClassSession session;
  const _SessionCard({required this.session});

  static const _emojis = ['😟', '😐', '🙂', '😊', '😄'];
  static final _dateFmt = DateFormat('MMM d, yyyy');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final emojiIdx = (session.mood - 1).clamp(0, 4);
    final dateStr = _dateFmt.format(session.checkInTime);
    final timeStr = _timeFmt.format(session.checkInTime);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: session.isActive
                ? const Color(0xFF1B5E20).withOpacity(0.12)
                : const Color(0xFF1A237E).withOpacity(0.08),
            child: Text(
              _emojis[emojiIdx],
              style: const TextStyle(fontSize: 22),
            ),
          ),
          title: Text(
            session.expectedTopic,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '$dateStr · $timeStr',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 4),
              if (session.isActive)
                _Badge(label: 'Active', color: const Color(0xFF1B5E20))
              else
                _Badge(
                  label: 'Completed',
                  color: const Color(0xFF1A237E),
                ),
            ],
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _DetailRow('Previous Topic', session.prevTopic),
            _DetailRow('Expected Topic', session.expectedTopic),
            _DetailRow(
              'Mood',
              '${_emojis[emojiIdx]}  ${session.mood}/5',
            ),
            _DetailRow(
              'Check-In Time',
              '${_dateFmt.format(session.checkInTime)} ${_timeFmt.format(session.checkInTime)}',
            ),
            _DetailRow(
              'Start Location',
              '${session.startLat.toStringAsFixed(5)}, ${session.startLng.toStringAsFixed(5)}',
            ),
            if (session.checkOutTime != null) ...[
              _DetailRow(
                'Check-Out Time',
                '${_dateFmt.format(session.checkOutTime!)} ${_timeFmt.format(session.checkOutTime!)}',
              ),
              _DetailRow(
                'Duration',
                _formatDuration(
                    session.checkOutTime!.difference(session.checkInTime)),
              ),
            ],
            if (session.endLat != null)
              _DetailRow(
                'End Location',
                '${session.endLat!.toStringAsFixed(5)}, ${session.endLng!.toStringAsFixed(5)}',
              ),
            if (session.learnedText != null)
              _DetailRow('What I Learned', session.learnedText!),
            if (session.feedback != null)
              _DetailRow('Instructor Feedback', session.feedback!),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h hr ${m} min';
    return '$m min';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
