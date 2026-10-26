import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/place.dart';
import '../core/constants/app_colors.dart';

class ItineraryStopCard extends StatelessWidget {
  final Place place;
  final int index;
  final bool isFirst;
  final ValueChanged<bool?> onToggleVisited;
  final VoidCallback onRemove;

  const ItineraryStopCard({
    super.key,
    required this.place,
    required this.index,
    required this.isFirst,
    required this.onToggleVisited,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final estimatedRange = place.estimatedCostMin == place.estimatedCostMax
        ? currencyFormatter.format(place.estimatedCostMax)
        : '${currencyFormatter.format(place.estimatedCostMin)}–${currencyFormatter.format(place.estimatedCostMax)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Travel duration pill from previous stop
        if (!isFirst && place.estimatedTravelTimeFromPrevious > 0)
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  color: AppColors.htmlBorder,
                ),
                const SizedBox(width: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.htmlSurfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.htmlBorder, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_walk_rounded,
                          size: 14, color: AppColors.htmlPrimaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Estimasi ${place.estimatedTravelTimeFromPrevious} menit perjalanan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.htmlTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Main Stop Card
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          color: place.visited
              ? AppColors.htmlSurfaceContainer
              : AppColors.htmlSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: place.visited ? Colors.green.shade200 : AppColors.border,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Stop Number Circle
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: place.visited
                          ? AppColors.success
                          : AppColors.htmlPrimaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Name and category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: place.visited
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: place.visited
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            place.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Drag handle for reordering
                    const Icon(
                      Icons.drag_indicator_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Timing & Cost Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (place.suggestedArrivalTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.htmlSurfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.htmlBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule,
                                size: 13, color: AppColors.htmlSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Tiba: ${place.suggestedArrivalTime}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.htmlPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (place.suggestedDurationMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.htmlSurfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.htmlBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 13, color: AppColors.htmlTextSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${place.suggestedDurationMinutes} menit',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.htmlTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.htmlSurfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place.estimatedCostMax == 0
                            ? 'Gratis'
                            : 'Est. $estimatedRange',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.htmlPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),

                // AI Tip callout
                if (place.activityTip != null &&
                    place.activityTip!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.htmlSurfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: AppColors.htmlPrimaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place.activityTip!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.htmlTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 20),

                // Footer actions: Mark as visited & Remove
                Row(
                  children: [
                    InkWell(
                      onTap: () => onToggleVisited(!place.visited),
                      child: Row(
                        children: [
                          Checkbox(
                            value: place.visited,
                            activeColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: onToggleVisited,
                          ),
                          Text(
                            place.visited
                                ? 'Sudah Dikunjungi'
                                : 'Tandai Kunjungi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: place.visited
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.redAccent),
                      tooltip: 'Hapus dari itinerary',
                      onPressed: onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
