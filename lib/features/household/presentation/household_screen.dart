import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/household/data/household_repository.dart';
import 'package:finanzapp_v2/features/household/presentation/household_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;

  Future<void> _sendInvite() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await ref.read(householdRepositoryProvider).requestHousehold(email);
      ref.invalidate(householdProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión del Hogar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: householdAsync.when(
          data: (household) {
            if (household == null) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Aún no tienes un hogar.",
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Invita a tu pareja o compañero mediante su correo electrónico para compartir gastos.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo de tu pareja',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _sendInvite,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Enviar Invitación"),
                    ),
                  ),
                ],
              );
            }

            if (household.status == 'active') {
              return HouseholdDashboard(household: household);
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    household.status == 'active' ? Icons.home : Icons.pending,
                    size: 80,
                    color: household.status == 'active'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Estado: ${household.status == 'pending' ? 'Pendiente' : household.status.toUpperCase()}",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text("ID: ${household.id.substring(0, 8)}..."), // Shorten ID
                  if (household.status == 'pending') ...[
                    const SizedBox(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "Esperando confirmación. Si enviaste la invitación, espera a que la acepten. Si te invitaron a ti, pulsa aceptar.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _acceptInvite(household.id),
                      child: const Text(
                        "Aceptar Invitación (Si recibiste una)",
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
