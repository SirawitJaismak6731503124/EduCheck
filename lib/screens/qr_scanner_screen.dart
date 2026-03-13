import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen QR / barcode scanner. Returns the raw string value to the
/// caller via [Navigator.pop] on the first successful scan.
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      _scanned = true;
      Navigator.pop(context, rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Class QR Code'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (_, state, __) => Icon(
                state == TorchState.on ? Icons.flash_on : Icons.flash_off,
              ),
            ),
            onPressed: _controller.toggleTorch,
            tooltip: 'Toggle torch',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dimmed overlay with transparent cutout
          _ScanOverlay(),

          // Instruction text
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Point the camera at the class QR code',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Semi-transparent overlay that draws a clear square scanning frame.
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const frameSize = 240.0;
    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(frameSize: frameSize),
      child: Center(
        child: SizedBox(
          width: frameSize,
          height: frameSize,
          child: Stack(
            children: [
              // Corner decorations
              _Corner(topLeft: true),
              _Corner(topLeft: false, flip: Axis.horizontal),
              _Corner(topLeft: false, flip: Axis.vertical),
              _Corner(topLeft: false, flip: null, bottom: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double frameSize;
  _OverlayPainter({required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = frameSize / 2;

    // Draw four semi-transparent rectangles around the frame
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, cy - half), paint);
    canvas.drawRect(Rect.fromLTRB(0, cy + half, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTRB(0, cy - half, cx - half, cy + half), paint);
    canvas.drawRect(Rect.fromLTRB(cx + half, cy - half, size.width, cy + half), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Corner extends StatelessWidget {
  final bool topLeft;
  final Axis? flip;
  final bool bottom;

  const _Corner({
    required this.topLeft,
    this.flip,
    this.bottom = false,
  });

  @override
  Widget build(BuildContext context) {
    const color = Colors.white;
    const thickness = 3.0;
    const length = 24.0;

    Widget corner = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: length, height: thickness, color: color),
        Container(width: thickness, height: length, color: color),
      ],
    );

    if (flip == Axis.horizontal) {
      corner = Transform.scale(scaleX: -1, child: corner);
    } else if (flip == Axis.vertical) {
      corner = Transform.scale(scaleY: -1, child: corner);
    } else if (bottom) {
      corner = Transform.scale(scaleX: -1, scaleY: -1, child: corner);
    }

    AlignmentGeometry alignment;
    if (topLeft) {
      alignment = Alignment.topLeft;
    } else if (flip == Axis.horizontal) {
      alignment = Alignment.topRight;
    } else if (flip == Axis.vertical) {
      alignment = Alignment.bottomLeft;
    } else {
      alignment = Alignment.bottomRight;
    }

    return Positioned.fill(child: Align(alignment: alignment, child: corner));
  }
}
