import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../view_models/app_state_view_model.dart';

class EmergencyControlScreen extends StatelessWidget {
  const EmergencyControlScreen({super.key});

  void _confirmCutPower(BuildContext context, AppStateViewModel state) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 28),
              const SizedBox(width: 10),
              Text(state.tr('confirmCutoff'), style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            state.tr('cutoffWarning'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(state.tr('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                state.cutPower();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
                foregroundColor: Colors.white,
              ),
              child: Text(state.tr('yesCutPower'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(state.tr('emergencyControl')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: state.isPowerCut
                    ? AppColors.dangerRed.withOpacity(0.15)
                    : AppColors.darkSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: state.isPowerCut ? AppColors.dangerRed : AppColors.cardBorder,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    size: 80,
                    color: state.isPowerCut ? AppColors.dangerRed : AppColors.warningOrange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.isPowerCut ? state.tr('circuitsDeenergized') : state.tr('relaysEnergized'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: state.isPowerCut ? AppColors.dangerRed : AppColors.safeGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.isPowerCut
                        ? 'Emergency remote shutdown is active. All power outputs disengaged.'
                        : 'Remote emergency relay trip ready. Tap below to trigger immediate disengagement.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  if (!state.canCutPower)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        state.tr('cutoffNotAuthorized'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppColors.warningOrange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (!state.isPowerCut)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.canCutPower ? () => _confirmCutPower(context, state) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dangerRed,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppColors.dangerRed.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_off_rounded, size: 24),
                            const SizedBox(width: 10),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  state.tr('cutPowerNow'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.canCutPower ? () => state.restorePower() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safeGreen,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.power_rounded, size: 24),
                            const SizedBox(width: 10),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  state.tr('restorePower'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Emergency Protocol Checklist
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Protocol Guidelines:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text('1. In case of electrical fire or burning odor, disengage power immediately.'),
                  SizedBox(height: 6),
                  Text('2. Keep emergency contacts notified before manually re-closing breakers.'),
                  SizedBox(height: 6),
                  Text('3. Verify ground isolation using SARI diagnostic heatmap before resetting.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
