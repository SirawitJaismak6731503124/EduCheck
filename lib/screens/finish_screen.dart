import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../widgets/form_widgets.dart';
import 'qr_scanner_screen.dart';

class FinishScreen extends StatefulWidget {
  const FinishScreen({super.key});

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _learnedCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  Position? _position;
  String? _qrCode;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _learnedCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────

  Future<void> _captureGPS() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack(
            'Location permission permanently denied. Enable it in Settings.',
            isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() => _position = pos);
    } catch (e) {
      _showSnack('Could not capture GPS: $e', isError: true);
    }
  }

  // ── QR ───────────────────────────────────────────────────────────────────

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );
    if (result != null && mounted) {
      setState(() => _qrCode = result);
      _showSnack('QR code captured successfully!');
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_position == null) {
      _showSnack('Please capture your GPS location first.', isError: true);
      return;
    }
    if (_qrCode == null) {
      _showSnack('Please scan the class QR code.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<SessionProvider>();
    final session = provider.activeSession!;

    final updated = session.copyWith(
      checkOutTime: DateTime.now(),
      endLat: _position!.latitude,
      endLng: _position!.longitude,
      learnedText: _learnedCtrl.text.trim(),
      feedback: _feedbackCtrl.text.trim(),
    );

    await provider.checkOut(updated);

    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>().activeSession;
    final gpsConfirmed = _position != null;
    final qrConfirmed = _qrCode != null;

    return ScreenScaffold(
      title: 'Finish Class',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Active Session Summary ─────────────────────────────────────
            if (session != null) _ActiveSessionCard(session: session),
            const SizedBox(height: 24),

            // ── Location & Verification ────────────────────────────────────
            const SectionHeader(
              icon: Icons.verified_outlined,
              label: 'Location & Verification',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ActionTile(
                    icon: gpsConfirmed
                        ? Icons.check_circle_rounded
                        : Icons.gps_fixed_rounded,
                    label: gpsConfirmed ? 'GPS Captured ✓' : 'Capture GPS',
                    color: gpsConfirmed
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF1A237E),
                    onTap: _captureGPS,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionTile(
                    icon: qrConfirmed
                        ? Icons.check_circle_rounded
                        : Icons.qr_code_scanner_rounded,
                    label: qrConfirmed ? 'QR Scanned ✓' : 'Scan QR Code',
                    color: qrConfirmed
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF1A237E),
                    onTap: _scanQR,
                  ),
                ),
              ],
            ),
            if (gpsConfirmed) ...[
              const SizedBox(height: 8),
              _InfoChip(
                icon: Icons.location_on,
                text:
                    'Lat: ${_position!.latitude.toStringAsFixed(5)}, Lng: ${_position!.longitude.toStringAsFixed(5)}',
              ),
            ],
            if (qrConfirmed) ...[
              const SizedBox(height: 4),
              _InfoChip(icon: Icons.qr_code, text: 'Code: $_qrCode'),
            ],

            // ── Post-Class Reflection ──────────────────────────────────────
            const SizedBox(height: 32),
            const SectionHeader(
              icon: Icons.edit_note_rounded,
              label: 'Post-Class Reflection',
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _learnedCtrl,
              label: 'What I Learned',
              hint: 'Summarise the key concepts from today\'s class...',
              icon: Icons.psychology_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _feedbackCtrl,
              label: 'Instructor Feedback',
              hint: 'How was the teaching today? Pace, clarity, examples...',
              icon: Icons.rate_review_rounded,
              maxLines: 3,
            ),

            // ── Submit ─────────────────────────────────────────────────────
            const SizedBox(height: 36),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Complete Session',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Icon(icon, color: const Color(0xFF1A237E)),
        ),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '$label is required' : null,
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ActiveSessionCard extends StatelessWidget {
  final dynamic session;
  const _ActiveSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final checkInTime = session.checkInTime as DateTime;
    final duration = DateTime.now().difference(checkInTime);
    final hrs = duration.inHours.toString().padLeft(2, '0');
    final mins = (duration.inMinutes % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined,
                color: Color(0xFF1A237E), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.expectedTopic as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Duration: $hrs h $mins min',
                  style:
                      const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black38),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
