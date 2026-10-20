import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class KelanaHeader extends StatelessWidget {
  final String title;

  const KelanaHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.htmlSurface,
        border: Border(
            bottom: BorderSide(
                color: AppColors.htmlBorder.withValues(alpha: 0.55))),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.htmlPrimaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/icons/logoonly2.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('K',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Kelana',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.htmlPrimaryContainer),
          ),
          const SizedBox(width: 7),
          Text('/',
              style: TextStyle(
                  color: AppColors.htmlBorder.withValues(alpha: 0.9))),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.htmlTextSecondary),
            ),
          ),
          IconButton(
            tooltip: 'Profil',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline_rounded, size: 21),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.htmlPrimary,
              foregroundColor: Colors.white,
              fixedSize: const Size(34, 34),
            ),
          ),
        ],
      ),
    );
  }
}

class KelanaBottomNavigation extends StatelessWidget {
  final String currentPath;

  const KelanaBottomNavigation({super.key, required this.currentPath});

  static const _items = [
    ('/home', 'Home', Icons.explore_outlined),
    ('/chat', 'Plan', Icons.calendar_month_outlined),
    ('/trips', 'Trips', Icons.luggage_outlined),
    ('/saved', 'Saved', Icons.bookmark_border_rounded),
    ('/profile', 'Profile', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.htmlSurface.withValues(alpha: 0.98),
        border: Border(
            top: BorderSide(
                color: AppColors.htmlBorder.withValues(alpha: 0.55))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.map((item) {
              final active = item.$1 == currentPath;
              final color = active
                  ? AppColors.htmlPrimaryContainer
                  : AppColors.htmlTextTertiary;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.$1),
                  child: SizedBox(
                    height: 58,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.$3, size: 21, color: color),
                            const SizedBox(height: 2),
                            Text(
                              item.$2,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
