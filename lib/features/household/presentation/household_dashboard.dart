import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/household/data/household_repository.dart';
import 'package:finanzapp_v2/features/household/domain/household.dart';
import 'package:finanzapp_v2/features/periods/data/period_repository.dart';
import 'package:finanzapp_v2/features/periods/data/periods_provider.dart';
import 'package:finanzapp_v2/features/periods/presentation/settlement_screen.dart';
import 'package:finanzapp_v2/features/transactions/data/household_transactions_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HouseholdDashboard extends ConsumerStatefulWidget {
  final Household household;
  const HouseholdDashboard({super.key, required this.household});

  @override
  ConsumerState<HouseholdDashboard> createState() => _HouseholdDashboardState();
}

class _HouseholdDashboardState extends ConsumerState<HouseholdDashboard> {
  void _showAddExpenseDialog() {
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedAccountId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Household Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final accountsAsync = ref.watch(accountsListProvider);
                    return accountsAsync.maybeWhen(
                      data: (accounts) {
                        if (accounts.isEmpty) {
                          return const Text("Create a personal account first");
                        }
                        selectedAccountId ??= accounts.first.id;
                        return DropdownButton<String>(
                          value: selectedAccountId,
                          items: accounts
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => selectedAccountId = v),
                        );
                      },
                      orElse: () => const CircularProgressIndicator(),
                    );
                  },
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                final category = categoryController.text;

                if (selectedAccountId != null &&
                    amount > 0 &&
                    category.isNotEmpty) {
                  await ref
                      .read(transactionRepositoryProvider)
                      .createTransaction(
                        accountId: selectedAccountId!,
                        amount: amount,
                        type: 'expense', // Household usually expenses
                        category: category,
                        description: descriptionController.text,
                        date: DateTime.now(),
                        context: 'household',
                        householdId: widget.household.id,
                      );
                  ref.invalidate(
                    householdTransactionsProvider(widget.household.id),
                  );
                  ref.invalidate(accountsListProvider);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCurrentPeriod() async {
    final now = DateTime.now();
    try {
      await ref
          .read(periodRepositoryProvider)
          .createPeriod(widget.household.id, now.year, now.month);
      ref.invalidate(periodsListProvider(widget.household.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<String?>(
          // Simple fetch to get current My User ID
          future: ref
              .read(dioProvider)
              .get('/users/me')
              .then((r) => r.data['id'] as String?),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const AlertDialog(
                content: Text("Failed to load user info"),
              );
            }

            final currentUserId = snapshot.data!;
            final isUserA = widget.household.userAId == currentUserId;

            return AlertDialog(
              title: const Text("Manage Members"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(widget.household.userAEmail), // User A
                    subtitle: const Text("Admin"),
                    trailing: isUserA ? const Chip(label: Text("You")) : null,
                  ),
                  if (widget.household.userBEmail != null)
                    ListTile(
                      title: Text(widget.household.userBEmail!),
                      subtitle: const Text("Member"),
                      trailing: IconButton(
                        icon: Icon(
                          isUserA
                              ? Icons.remove_circle
                              : (widget.household.userBId == currentUserId
                                    ? Icons.exit_to_app
                                    : Icons.info),
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          if (isUserA) {
                            // Remove Member Confirmation
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text("Remove Member?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text("Remove"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(householdRepositoryProvider)
                                  .removeMember(
                                    widget.household.id,
                                    widget.household.userBId!,
                                  );
                              if (context.mounted) Navigator.pop(context);
                            }
                          } else if (widget.household.userBId ==
                              currentUserId) {
                            // Leave Confirmation
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text("Leave Household?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text("Leave"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(householdRepositoryProvider)
                                  .removeMember(
                                    widget.household.id,
                                    currentUserId,
                                  );
                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        },
                      ),
                    )
                  else
                    ListTile(
                      tileColor: Colors.grey.shade100,
                      title: const Text("Invite Partner"),
                      subtitle: const Text("Currently empty slot"),
                      leading: const Icon(Icons.person_add),
                      onTap: () {
                        // Placeholder for future invite logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "To invite, use the dashboard helper or create new request.",
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(periodsListProvider(widget.household.id));
    final transactionsAsync = ref.watch(
      householdTransactionsProvider(widget.household.id),
    );

    return Column(
      children: [
        // Header / Period Info
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Hogar Activo",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.people),
                        tooltip: "Manage Members",
                        onPressed: _showMembersDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, size: 20),
                        tooltip: "Ver Historial",
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HouseholdHistoryScreen(
                              householdId: widget.household.id,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.household.id.substring(0, 8),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              periodsAsync.when(
                data: (periods) {
                  final now = DateTime.now();
                  final currentPeriod = periods
                      .where((p) => p.year == now.year && p.month == now.month)
                      .firstOrNull;

                  if (currentPeriod != null) {
                    final statusTranslated = currentPeriod.status == 'settled'
                        ? 'CERRADO'
                        : 'ABIERTO';
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettlementScreen(
                            householdId: widget.household.id,
                            period: currentPeriod,
                          ),
                        ),
                      ),
                      child: Chip(
                        label: Text(
                          "${currentPeriod.month}/${currentPeriod.year} - $statusTranslated",
                        ),
                        backgroundColor: currentPeriod.status == 'settled'
                            ? Colors.grey.shade300
                            : Colors.green.shade100,
                        avatar: const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    );
                  } else {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text("Iniciar Periodo"),
                      onPressed: _createCurrentPeriod,
                    );
                  }
                },
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                ),
                error: (e, s) => const Icon(Icons.error),
              ),
            ],
          ),
        ),

        const Divider(),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Gastos Compartidos Recientes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: transactionsAsync.when(
            data: (txs) => txs.isEmpty
                ? const Center(
                    child: Text("No hay gastos compartidos este mes."),
                  )
                : ListView.builder(
                    itemCount: txs.length,
                    itemBuilder: (context, index) {
                      final tx = txs[index];
                      // Format date in Spanish
                      final dateFormatted = DateFormat.yMMMd(
                        'es_ES',
                      ).format(tx.date);
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.home)),
                        title: Text(tx.category),
                        subtitle: Text("${tx.description}\n$dateFormatted"),
                        trailing: Text(
                          "\$${tx.amount.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text("Error: $e")),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton.extended(
            onPressed: _showAddExpenseDialog,
            label: const Text("Nuevo Gasto Compartido"),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
