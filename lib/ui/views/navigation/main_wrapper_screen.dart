import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/alert_model.dart';
import '../../view_models/app_state_view_model.dart';

class MainWrapperScreen extends StatelessWidget {
  final Widget child;

  const MainWrapperScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/app/monitoring')) return 1;
    if (location.startsWith('/app/ai-risk')) return 2;
    if (location.startsWith('/app/alerts')) return 3;
    if (location.startsWith('/app/heatmap')) return 4;
    if (location.startsWith('/app/reports')) return 5;
    return 0; // default /app/home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/app/home');
        break;
      case 1:
        context.go('/app/monitoring');
        break;
      case 2:
        context.go('/app/ai-risk');
        break;
      case 3:
        context.go('/app/alerts');
        break;
      case 4:
        context.go('/app/heatmap');
        break;
      case 5:
        context.go('/app/reports');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateViewModel>();
    final selectedIndex = _calculateSelectedIndex(context);
    final isArabic = state.locale.languageCode == 'ar';
    final activeAlerts = state.alerts.where((a) => a.status == AlertStatus.active).length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/images/sari_logo.png',
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isPowerCut
                    ? AppColors.dangerRed.withOpacity(0.2)
                    : AppColors.safeGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.isPowerCut ? AppColors.dangerRed : AppColors.safeGreen,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isPowerCut ? AppColors.dangerRed : AppColors.safeGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.isPowerCut ? state.tr('powerOff') : state.tr('live'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: state.isPowerCut ? AppColors.dangerRed : AppColors.safeGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Button (AR / EN)
          InkWell(
            onTap: () => state.toggleLanguage(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    isArabic ? 'EN' : 'عربي',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Emergency Cutoff button
          IconButton(
            tooltip: state.tr('emergencyControl'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.power_settings_new_rounded,
                  color: state.isPowerCut ? AppColors.dangerRed : AppColors.warningOrange,
                ),
                if (state.isPowerCut)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.dangerRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push('/emergency'),
          ),

          // Device Management button
          IconButton(
            tooltip: state.tr('navDevices'),
            icon: const Icon(Icons.sensors, color: AppColors.textSecondary),
            onPressed: () => context.push('/devices'),
          ),

          // User Profile avatar button
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 6.0),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.3),
                child: Text(
                  state.currentUser.name.isNotEmpty ? state.currentUser.name[0] : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isPowerCut)
            Container(
              color: AppColors.dangerRed,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.tr('circuitsDeenergized'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard_rounded),
            label: state.tr('navHome'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart_rounded),
            activeIcon: const Icon(Icons.analytics_rounded),
            label: state.tr('navMonitoring'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.psychology_outlined),
            activeIcon: const Icon(Icons.psychology_rounded),
            label: state.tr('navAiRisk'),
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: activeAlerts > 0,
              label: Text('$activeAlerts'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            activeIcon: Badge(
              isLabelVisible: activeAlerts > 0,
              label: Text('$activeAlerts'),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: state.tr('navAlerts'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            activeIcon: const Icon(Icons.map_rounded),
            label: state.tr('navHeatmap'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insert_drive_file_outlined),
            activeIcon: const Icon(Icons.insert_drive_file_rounded),
            label: state.tr('navReports'),
          ),
        ],
      ),
    );
  }
}
