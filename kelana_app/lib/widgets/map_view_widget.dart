import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/itinerary.dart';
import '../core/constants/app_colors.dart';

class MapViewWidget extends StatefulWidget {
  final List<Place> places;
  final List<LatLngPoint> polylinePoints;
  final Function(Place)? onMarkerTapped;

  const MapViewWidget({
    super.key,
    required this.places,
    this.polylinePoints = const [],
    this.onMarkerTapped,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  int? _selectedPlaceIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.places.isEmpty) {
      return Container(
        height: 240,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'Peta rute perjalanan akan muncul di sini',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Custom Painter Canvas Map representing the geographic route layout
            Positioned.fill(
              child: CustomPaint(
                painter: RouteCanvasPainter(
                  places: widget.places,
                  selectedIndex: _selectedPlaceIndex,
                ),
              ),
            ),

            // Tap detector overlay for markers
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: widget.places.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final place = entry.value;
                      final pos = _getNormalizedPosition(idx, widget.places.length, constraints.maxWidth, constraints.maxHeight);

                      return Positioned(
                        left: pos.dx - 18,
                        top: pos.dy - 36,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPlaceIndex = idx;
                            });
                            widget.onMarkerTapped?.call(place);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _selectedPlaceIndex == idx
                                      ? AppColors.secondary
                                      : (place.visited ? AppColors.success : AppColors.primary),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // Top Status Overlay
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined, color: Colors.tealAccent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.places.length} Titik Kunjungan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Selected Place Card Overlay
            if (_selectedPlaceIndex != null && _selectedPlaceIndex! < widget.places.length)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '${_selectedPlaceIndex! + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.places[_selectedPlaceIndex!].name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.places[_selectedPlaceIndex!].category,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => setState(() => _selectedPlaceIndex = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Offset _getNormalizedPosition(int index, int total, double width, double height) {
    if (total == 1) return Offset(width / 2, height / 2);
    // Smooth S-curve layout across canvas
    final t = index / (total - 1);
    final x = 40 + t * (width - 80);
    final y = height / 2 + (index % 2 == 0 ? -35 : 35);
    return Offset(x, y);
  }
}

class RouteCanvasPainter extends CustomPainter {
  final List<Place> places;
  final int? selectedIndex;

  RouteCanvasPainter({required this.places, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle grid background
    final gridPaint = Paint()
      ..color = const Color(0xFF334155).withOpacity(0.3)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (places.length < 2) return;

    // 2. Draw connected dashed route polyline
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < places.length; i++) {
      final t = i / (places.length - 1);
      final x = 40 + t * (size.width - 80);
      final y = size.height / 2 + (i % 2 == 0 ? -35 : 35);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Outer glow for route
    final glowPaint = Paint()
      ..color = const Color(0xFF14B8A6).withOpacity(0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    // Primary route line
    final linePaint = Paint()
      ..color = const Color(0xFF14B8A6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant RouteCanvasPainter oldDelegate) => true;
}
