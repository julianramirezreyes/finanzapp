import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/household/data/household_repository.dart';
import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/loading_indicator.dart';

class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await ref.read(householdRepositoryProvider).requestHousehold(email);
      ref.invalidate(householdProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitación enviada'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _acceptInvite(String id) async {
    setState(() => isLoading = true);
    try {
      await ref.read(householdRepositoryProvider).acceptHousehold(id);
      ref.invalidate(householdProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(householdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión del Hogar')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: householdAsync.when(
          data: (household) {
            if (household == null) {
              return _buildNoHousehold(context, isDark);
            }

            if (household.status == 'active') {
              return HouseholdHistoryScreen(household: household);
            }

            return _buildPendingHousehold(context, household, isDark);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildNoHousehold(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.info,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Aún no tienes un hogar',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Invita a tu pareja o compañero para compartir gastos',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Correo de tu pareja',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _sendInvite,
                  child: isLoading
                      ? const LoadingIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text('Enviar Invitación'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingHousehold(
    BuildContext context,
    dynamic household,
    bool isDark,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              household.status == 'active' ? Icons.home : Icons.pending,
              size: 64,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Estado: ${household.status == 'pending' ? 'Pendiente' : household.status.toString().toUpperCase()}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ID: ${household.id.substring(0, 8)}...',
            style: TextStyle(color: AppColors.textMuted),
          ),
          if (household.status == 'pending') ...[
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Text(
                'Esperando confirmación.\nSi enviaste la invitación, espera a que la acepten.\nSi te invitaron a ti, pulsa aceptar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: isLoading ? null : () => _acceptInvite(household.id),
              child: isLoading
                  ? const LoadingIndicator(color: Colors.white)
                  : const Text('Aceptar Invitación'),
            ),
          ],
        ],
      ),
    );
  }
}
