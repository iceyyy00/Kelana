import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/place.dart';
import '../core/constants/app_colors.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final bool isSelected;
  final VoidCallback onToggleSelect;

  const PlaceCard({
    super.key,
    required this.place,
    required this.isSelected,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggleSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail with fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade200,
                  child: place.photoUrl.isNotEmpty
                      ? Image.network(
                          place.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.landscape,
                            color: Colors.grey,
                            size: 36,
                          ),
                        )
                      : const Icon(
                          Icons.place,
                          color: AppColors.primary,
                          size: 36,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Checkbox
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (_) => onToggleSelect(),
                        ),
                      ],
                    ),

                    // Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        place.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Rating and Price
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${place.rating} (${place.userRatingsTotal})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          place.estimatedPrice == 0
                              ? 'Gratis'
                              : currencyFormatter.format(place.estimatedPrice),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: place.estimatedPrice == 0
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    // Address snippet
                    Text(
                      place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
