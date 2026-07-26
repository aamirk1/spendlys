import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool isScanCompleted = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF5F33E1);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Scan Barcode / QR",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          // Flashlight Toggle Button
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                color: Colors.white,
                icon: Icon(
                  isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: isTorchOn ? Colors.amber : Colors.white,
                ),
                iconSize: 24,
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
          // Camera Facing Toggle Button
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              return IconButton(
                color: Colors.white,
                icon: const Icon(Icons.cameraswitch_rounded),
                iconSize: 24,
                onPressed: () => cameraController.switchCamera(),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Mobile Scanner Camera Preview
          MobileScanner(
            controller: cameraController,
            onDetect: (BarcodeCapture capture) {
              if (isScanCompleted) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  setState(() {
                    isScanCompleted = true;
                  });
                  // Return scanned value
                  Get.back(result: rawValue);
                }
              }
            },
          ),

          // 2. Custom Scan Overlay (Visual Target Frame)
          _buildScanOverlay(context, primaryColor),

          // 3. Bottom Guide Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Align barcode or QR code inside the frame",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Scanning starts automatically",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Manual action button
                  OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.keyboard_outlined, color: Colors.white, size: 18),
                    label: const Text("Enter Code Manually", style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context, Color primaryColor) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scanFrameSize = screenWidth * 0.70;

    return Stack(
      children: [
        // Semi-transparent background mask around the scanning frame
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: scanFrameSize,
                  height: scanFrameSize,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        // The outline frame on top of the mask
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(scanFrameSize, scanFrameSize),
            painter: ScannerFramePainter(color: primaryColor, strokeWidth: 4),
          ),
        ),
        // Animated scanning line inside the frame
        _ScanLineAnimation(frameSize: scanFrameSize),
      ],
    );
  }
}

class _ScanLineAnimation extends StatefulWidget {
  final double frameSize;
  const _ScanLineAnimation({required this.frameSize});

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (MediaQuery.of(context).size.height - widget.frameSize) / 2 +
          widget.frameSize * _animation.value,
      left: (MediaQuery.of(context).size.width - widget.frameSize) / 2 + 20,
      right: (MediaQuery.of(context).size.width - widget.frameSize) / 2 + 20,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F33E1).withOpacity(0.8),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
          gradient: const LinearGradient(
            colors: [Colors.transparent, Color(0xFF5F33E1), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}

class ScannerFramePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  ScannerFramePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    final double cornerSize = width * 0.15;
    final double r = 24.0; // border radius of the frame

    // Top-Left Corner
    Path topLeft = Path()
      ..moveTo(0, cornerSize)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(cornerSize, 0);

    // Top-Right Corner
    Path topRight = Path()
      ..moveTo(width - cornerSize, 0)
      ..lineTo(width - r, 0)
      ..arcToPoint(Offset(width, r), radius: Radius.circular(r))
      ..lineTo(width, cornerSize);

    // Bottom-Right Corner
    Path bottomRight = Path()
      ..moveTo(width, height - cornerSize)
      ..lineTo(width, height - r)
      ..arcToPoint(Offset(width - r, height), radius: Radius.circular(r))
      ..lineTo(width - cornerSize, height);

    // Bottom-Left Corner
    Path bottomLeft = Path()
      ..moveTo(cornerSize, height)
      ..lineTo(r, height)
      ..arcToPoint(Offset(0, height - r), radius: Radius.circular(r))
      ..lineTo(0, height - cornerSize);

    canvas.drawPath(topLeft, paint);
    canvas.drawPath(topRight, paint);
    canvas.drawPath(bottomRight, paint);
    canvas.drawPath(bottomLeft, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
