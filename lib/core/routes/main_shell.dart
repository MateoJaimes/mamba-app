import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../features/feed/presentation/feed_home_tab_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isCompact = false;

  static const _items = [
    (Icons.explore_outlined, Icons.explore_rounded, 'Explorar'),
    (Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    (Icons.search_rounded, Icons.search_rounded, 'Buscar'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Agenda'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  void _onDestinationSelected(int index) {
    if (_isCompact) setState(() => _isCompact = false);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    if (index == 1) {
      feedHomeTabRequest.value++;
    }
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical ||
        notification is! UserScrollNotification) {
      return false;
    }

    final shouldCompact = switch (notification.direction) {
      ScrollDirection.reverse => true,
      ScrollDirection.forward => false,
      ScrollDirection.idle => _isCompact,
    };
    if (shouldCompact != _isCompact) {
      setState(() => _isCompact = shouldCompact);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.navigationShell.currentIndex;
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.only(
            left: _isCompact ? 8 : 0,
            right: _isCompact ? 8 : 0,
            bottom: _isCompact ? 8 : 0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                height: _isCompact ? 52 : 68,
                decoration: BoxDecoration(
                  color: const Color(0xE6191F1C),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: const Color(0x38D7E5DC)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppColors.emeraldGlow,
                      blurRadius: 20,
                      spreadRadius: -14,
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final active = selected == index;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: active,
                        label: item.$3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () => _onDestinationSelected(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            margin: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: _isCompact ? 4 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0x2634D399)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                active ? item.$2 : item.$1,
                                size: _isCompact ? 20 : 23,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
