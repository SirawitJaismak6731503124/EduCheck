import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/class_session.dart';
import '../providers/session_provider.dart';
import '../widgets/form_widgets.dart';
import '../widgets/mood_slider.dart';
import 'qr_scanner_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prevTopicCtrl = TextEditingController();
  final _expectedTopicCtrl = TextEditingController();

  int _mood = 3;
  Position? _position;
  String? _qrCode;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _prevTopicCtrl.dispose();
    _expectedTopicCtrl.dispose();
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
        _showSnack('Location permission permanently denied. Enable it in Settings.', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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

    final session = ClassSession(
      id: const Uuid().v4(),
      checkInTime: DateTime.now(),
      startLat: _position!.latitude,
      startLng: _position!.longitude,
      prevTopic: _prevTopicCtrl.text.trim(),
      expectedTopic: _expectedTopicCtrl.text.trim(),
      mood: _mood,
    );

    await context.read<SessionProvider>().checkIn(session);

    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gpsConfirmed = _position != null;
    final qrConfirmed = _qrCode != null;

    return ScreenScaffold(
      title: 'Check In',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
              _InfoChip(
                icon: Icons.qr_code,
                text: 'Code: $_qrCode',
              ),
            ],

            // ── Pre-Class Reflection ───────────────────────────────────────
            const SizedBox(height: 32),
            const SectionHeader(
              icon: Icons.menu_book_rounded,
              label: 'Pre-Class Reflection',
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _prevTopicCtrl,
              label: 'Previous Topic',
              hint: 'What was covered in the last class?',
              icon: Icons.history_edu_rounded,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _expectedTopicCtrl,
              label: 'Expected Topic',
              hint: 'What do you expect to learn today?',
              icon: Icons.lightbulb_outline_rounded,
            ),

            // ── Mood Check ─────────────────────────────────────────────────
            const SizedBox(height: 32),
            const SectionHeader(
              icon: Icons.mood_rounded,
              label: 'How Are You Feeling?',
            ),
            const SizedBox(height: 14),
            MoodSlider(
              value: _mood,
              onChanged: (v) => setState(() => _mood = v),
            ),

            // ── Submit ─────────────────────────────────────────────────────
            const SizedBox(height: 36),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
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
                        'Confirm Check-In',
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '$label is required' : null,
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
