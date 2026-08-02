import 'package:finanzapp_v2/core/invalidation/data_invalidator.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'expense';
  double _amount = 0;
  String _description = '';
  DateTime _date = DateTime.now();
  String _context = 'personal';
  String? _accountId;
  String? _destinationAccountId;
  String? _pocketId;
  bool _excludeFromBalance = false;
  bool _paidWithCreditCard = false;
  bool _payingCreditCard = false; // Nueva opción: pagar deuda de TC
  String? _creditCardAccountId; // Selected credit card ID
  int _installments = 1;

  String? _selectionValue;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _type = t.type;
      _amount = t.amount;
      _description = t.description;
      _date = t.date;
      _context = t.context;
      _accountId = t.accountId;
      _destinationAccountId = t.destinationAccountId;
      _excludeFromBalance = t.excludeFromBalance;
      _paidWithCreditCard = t.paidWithCreditCard;
      _creditCardAccountId = t.vaultCardId;
      _installments = t.installments ?? 1;
      _payingCreditCard = _isCanonicalCardPayment(t);

      if (_payingCreditCard) {
        _selectionValue = 'static:GastoGeneral';
      } else if (t.budgetId != null) {
        _selectionValue = "budget:${t.budgetId}";
      } else {
        _selectionValue = "static:${t.category}";
      }
    }
  }

  bool _isCanonicalCardPayment(Transaction transaction) =>
      transaction.type == 'expense' &&
      transaction.category == 'Pago Tarjeta' &&
      !transaction.paidWithCreditCard &&
      transaction.vaultCardId != null;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final isEditing = widget.transactionToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Transacción' : 'Nueva Transacción'),
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: accountsAsync.when(
        data: (accounts) {
          final currency = NumberFormat.currency(
            symbol: '\$',
            decimalDigits: 0,
          );

          if (accounts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Por favor, crea una cuenta primero.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (_accountId == null && accounts.isNotEmpty) {
            _accountId = accounts.first.id;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxxl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTypeSelector(context),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildAmountField(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDescriptionField(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDateAndContextRow(isDark),
                  const SizedBox(height: AppSpacing.lg),
                  _buildCategorySelector(ref),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAccountSelector(accounts, currency),
                  if (_type == 'transfer') ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildDestinationAccountSelector(accounts, currency),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _buildExcludeFromBalanceSwitch(isDark),
                  if (_type == 'expense') ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildPayCreditCardDebtSwitch(isDark),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCreditCardSwitch(isDark),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildSubmitButton(isEditing, isDark),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'expense',
          label: const Text('Gasto'),
          icon: const Icon(Icons.arrow_downward, size: 18),
        ),
        ButtonSegment(
          value: 'income',
          label: const Text('Ingreso'),
          icon: const Icon(Icons.arrow_upward, size: 18),
        ),
        ButtonSegment(
          value: 'transfer',
          label: const Text('Transferencia'),
          icon: const Icon(Icons.swap_horiz, size: 18),
        ),
      ],
      selected: {_type},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _type = newSelection.first;
          if (_type == 'transfer') {
            _selectionValue = null;
          }
        });
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            if (_type == 'expense') {
              return context.stateFill(AppColors.expense);
            }
            if (_type == 'income') {
              return context.stateFill(AppColors.income);
            }
            return context.stateFill(AppColors.investment);
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            if (_type == 'expense') return AppColors.expense;
            if (_type == 'income') return AppColors.income;
            return AppColors.investment;
          }
          return AppColors.textSecondary;
        }),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monto',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: isEditingAmount() ? _amount.toString() : null,
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _type == 'expense'
                  ? AppColors.expense
                  : _type == 'income'
                  ? AppColors.income
                  : AppColors.investment,
            ),
            hintText: '0',
            filled: true,
            fillColor: context.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide(color: AppColors.expense),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa un monto';
            }
            final v = double.tryParse(value);
            if (v == null || v <= 0) return 'Monto inválido';
            return null;
          },
          onSaved: (value) => _amount = double.parse(value!),
        ),
      ],
    );
  }

  bool isEditingAmount() {
    return widget.transactionToEdit != null && _amount > 0;
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: _description,
          decoration: InputDecoration(
            hintText: _type == 'income'
                ? '¿De dónde viene el ingreso?'
                : _type == 'transfer'
                ? 'Concepto de la transferencia'
                : '¿Qué gastaste?',
            filled: true,
            fillColor: context.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
          onSaved: (value) => _description = value ?? '',
        ),
      ],
    );
  }

  Widget _buildDateAndContextRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMd('es_CO').format(_date),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contexto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: ValueKey(_context),
                    value: _context,
                    isExpanded: true,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'personal',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Personal'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'household',
                        child: Row(
                          children: [
                            Icon(Icons.home_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Hogar'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: _paidWithCreditCard
                        ? null
                        : (v) {
                            setState(() {
                              _context = v!;
                              _selectionValue = null;
                            });
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(WidgetRef ref) {
    if (_payingCreditCard) {
      return _buildCanonicalPaymentCategory();
    }
    final householdAsync = ref.watch(householdProvider);
    final String? currentHouseholdId = householdAsync.valueOrNull?.id;
    final String? targetHouseholdId = _context == 'household'
        ? currentHouseholdId
        : null;
    final budgetsAsync = ref.watch(budgetsListProvider(targetHouseholdId));

    return budgetsAsync.when(
      data: (budgets) {
        final List<DropdownMenuItem<String>> items = [];

        if (_type == 'income') {
          items.addAll([
            const DropdownMenuItem(
              value: "static:Salario",
              child: Text("Salario"),
            ),
            const DropdownMenuItem(
              value: "static:Honorarios",
              child: Text("Honorarios"),
            ),
            const DropdownMenuItem(
              value: "static:Regalo",
              child: Text("Regalo"),
            ),
            const DropdownMenuItem(
              value: "static:Inversión",
              child: Text("Rendimiento Inversión"),
            ),
            const DropdownMenuItem(
              value: "static:Otros",
              child: Text("Otros Ingresos"),
            ),
          ]);
        } else {
          // Gasto General - not linked to any budget
          items.add(
            const DropdownMenuItem(
              value: "static:GastoGeneral",
              child: Text("Gasto General"),
            ),
          );

          if (budgets.isNotEmpty) {
            final currency = NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 0,
            );

            for (var b in budgets) {
              // Mostrar progreso si hay monthlyQuota configurado (para personal y hogar)
              String subtitle = '';
              if (b.monthlyQuota > 0) {
                final double spent = b.currentAmount;
                final double limit = b.monthlyQuota;
                final double available = limit - spent;
                final int percentage = limit > 0
                    ? ((spent / limit) * 100).round()
                    : 0;
                subtitle =
                    '$percentage% - ${currency.format(available)} libres';
              } else {
                subtitle = b.isRecurrent ? 'Fijo' : 'Meta';
              }

              items.add(
                DropdownMenuItem(
                  value: "budget:${b.id}",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(b.category, style: const TextStyle(fontSize: 14)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          if (_type == 'transfer') {
            items.insert(
              0,
              const DropdownMenuItem(
                value: "static:Transferencia",
                child: Text("Transferencia General"),
              ),
            );
          }

          if (items.isEmpty) {
            items.addAll([
              const DropdownMenuItem(
                value: "static:General",
                child: Text("General"),
              ),
              const DropdownMenuItem(
                value: "static:Otros",
                child: Text("Otros Gastos"),
              ),
            ]);
          }
        }

        if (_selectionValue == null ||
            !items.any((i) => i.value == _selectionValue)) {
          if (items.isNotEmpty) _selectionValue = items.first.value;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categoría',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: ValueKey("cat_$_context$_type"),
                  value: _selectionValue,
                  isExpanded: true,
                  isDense: true,
                  items: items,
                  onChanged: (v) => setState(() => _selectionValue = v),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (e, s) => Text("Error cargando categorías: $e"),
    );
  }

  Widget _buildCanonicalPaymentCategory() {
    return Semantics(
      container: true,
      label: 'Pago de tarjeta: las compras ya consumen sus metas',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.stateFill(AppColors.warning),
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(color: AppColors.warning),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gasto General',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Esta selección no consume una meta.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Las compras con tarjeta ya consumen sus metas; asignar este pago duplicaría el gasto.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector(List<dynamic> accounts, NumberFormat currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuenta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Cuenta origen',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey(_accountId),
              value: _accountId,
              isExpanded: true,
              items: accounts
                  .map(
                    (a) => DropdownMenuItem<String>(
                      value: a.id as String,
                      child: Text('${a.name} (${currency.format(a.balance)})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _accountId = v;
                // Limpiar selección de TC si no pertenece a la nueva cuenta
                if (_creditCardAccountId != null && v != null) {
                  final creditCardsAsync = ref.read(
                    creditCardsWithDebtProvider,
                  );
                  final allCreditCards = creditCardsAsync.maybeWhen(
                    data: (cards) => cards,
                    orElse: () => <dynamic>[],
                  );
                  final cardBelongsToNewAccount = allCreditCards.any(
                    (card) =>
                        card['id'] == _creditCardAccountId &&
                        card['account_id'] == v,
                  );
                  if (!cardBelongsToNewAccount) {
                    _creditCardAccountId = null;
                  }
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationAccountSelector(
    List<dynamic> accounts,
    NumberFormat currency,
  ) {
    final pocketsAsync = _accountId != null
        ? ref.watch(pocketsProvider(_accountId!))
        : const AsyncValue<List<dynamic>>.data([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuenta Destino',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A donde envías el dinero',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey(_destinationAccountId),
              value: _destinationAccountId,
              isExpanded: true,
              items: accounts
                  .where((a) => a.id != _accountId)
                  .map(
                    (a) => DropdownMenuItem<String>(
                      value: a.id as String,
                      child: Text('${a.name} (${currency.format(a.balance)})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _destinationAccountId = v;
                _pocketId = null;
              }),
            ),
          ),
        ),
        if (_destinationAccountId != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bolsillo (opcional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Transferir a un bolsillo específico',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _pocketId,
                isExpanded: true,
                hint: const Text('Sin bolsillo'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin bolsillo'),
                  ),
                  ...pocketsAsync.when(
                    data: (pockets) => pockets.map(
                      (p) => DropdownMenuItem<String?>(
                        value: p.id as String,
                        child: Text(
                          '${p.name} (${currency.format(p.balance)})',
                        ),
                      ),
                    ),
                    loading: () => [],
                    error: (e, s) => [],
                  ),
                ],
                onChanged: (v) => setState(() => _pocketId = v),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExcludeFromBalanceSwitch(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.warning.withValues(alpha: 0.18)
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.money_off, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No afectar saldo',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Regístralo en el historial pero no descuentes dinero',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: _excludeFromBalance,
            onChanged: _paidWithCreditCard
                ? null
                : (bool value) {
                    setState(() => _excludeFromBalance = value);
                  },
            activeTrackColor: AppColors.primary,
            thumbColor: WidgetStateProperty.all(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPayCreditCardDebtSwitch(bool isDark) {
    final creditCardsAsync = ref.watch(creditCardsWithDebtProvider);
    // Read the data if present; loading/error are surfaced by the status footer
    // below instead of being silently coerced to an empty list.
    final filteredCreditCards =
        creditCardsAsync.valueOrNull ?? <Map<String, dynamic>>[];
    final dropdownValue =
        filteredCreditCards.any((c) => c['id'] == _creditCardAccountId)
        ? _creditCardAccountId
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.warning.withValues(alpha: 0.18)
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagar Tarjeta de Crédito',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Descarta saldo, registra como pago de deuda',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _payingCreditCard,
                onChanged: (bool value) {
                  setState(() {
                    _payingCreditCard = value;
                    if (_payingCreditCard) {
                      _paidWithCreditCard = false;
                      _excludeFromBalance = false;
                      _selectionValue = 'static:GastoGeneral';
                      if (filteredCreditCards.isNotEmpty) {
                        _creditCardAccountId =
                            filteredCreditCards.first['id'] as String?;
                      }
                    } else {
                      _creditCardAccountId = null;
                    }
                  });
                },
                activeTrackColor: AppColors.warning,
                thumbColor: WidgetStateProperty.all(Colors.white),
              ),
            ],
          ),
          if (_payingCreditCard && filteredCreditCards.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: ValueKey('pay_tc_select_$dropdownValue'),
                  value: dropdownValue,
                  isExpanded: true,
                  hint: const Text('Seleccionar tarjeta'),
                  items: filteredCreditCards.map<DropdownMenuItem<String>>((
                    card,
                  ) {
                    final debt =
                        (card['total_debt'] as num?)?.toDouble() ?? 0.0;
                    final debtStr = NumberFormat.currency(
                      symbol: '\$',
                      decimalDigits: 0,
                    ).format(debt);
                    return DropdownMenuItem<String>(
                      value: card['id'] as String,
                      child: Text('${card['title']} ($debtStr)'),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _creditCardAccountId = value;
                    });
                  },
                ),
              ),
            ),
          ],
          _creditCardStatusFooter(creditCardsAsync, _payingCreditCard),
        ],
      ),
    );
  }

  Widget _buildCreditCardSwitch(bool isDark) {
    final filteredCreditCardsAsync = ref.watch(creditCardsWithDebtProvider);
    final filteredCreditCards =
        filteredCreditCardsAsync.valueOrNull ?? <Map<String, dynamic>>[];
    final dropdownValue =
        filteredCreditCards.any((c) => c['id'] == _creditCardAccountId)
        ? _creditCardAccountId
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.info.withValues(alpha: 0.18)
                      : AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.credit_card, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagado con Tarjeta de Crédito',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'No descuenta saldo, cuenta para DIAN',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _paidWithCreditCard,
                onChanged: (bool value) {
                  setState(() {
                    _paidWithCreditCard = value;
                    if (_paidWithCreditCard) {
                      _payingCreditCard = false;
                      _excludeFromBalance = true;
                      if (filteredCreditCards.isNotEmpty) {
                        _creditCardAccountId =
                            filteredCreditCards.first['id'] as String?;
                      }
                    } else {
                      _creditCardAccountId = null;
                      _selectionValue = null;
                    }
                  });
                },
                activeTrackColor: AppColors.primary,
                thumbColor: WidgetStateProperty.all(Colors.white),
              ),
            ],
          ),
          if (_paidWithCreditCard && filteredCreditCards.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: ValueKey('tc_select_$dropdownValue'),
                  value: dropdownValue,
                  isExpanded: true,
                  hint: const Text('Seleccionar tarjeta'),
                  items: filteredCreditCards.map<DropdownMenuItem<String>>((
                    card,
                  ) {
                    final debt =
                        (card['total_debt'] as num?)?.toDouble() ?? 0.0;
                    final debtStr = NumberFormat.currency(
                      symbol: '\$',
                      decimalDigits: 0,
                    ).format(debt);
                    return DropdownMenuItem<String>(
                      value: card['id'] as String,
                      child: Text('${card['title']} ($debtStr)'),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _creditCardAccountId = value;
                      // Auto-seleccionar la cuenta de la tarjeta
                      if (value != null) {
                        final selectedCard = filteredCreditCards.firstWhere(
                          (c) => c['id'] == value,
                          orElse: () => filteredCreditCards.first,
                        );
                        _accountId = selectedCard['account_id'] as String?;
                      }
                    });
                  },
                ),
              ),
            ),
          ],
          if (_paidWithCreditCard && _creditCardAccountId != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Text('Cuotas: '),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<int>(
                  value: _installments,
                  items: List.generate(24, (i) => i + 1)
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (v) => setState(() => _installments = v ?? 1),
                ),
              ],
            ),
          ],
          _creditCardStatusFooter(
            filteredCreditCardsAsync,
            _paidWithCreditCard,
          ),
        ],
      ),
    );
  }

  // Footer that distinguishes "no cards" from "still loading" / "failed to load",
  // so a transient failure no longer masquerades as "no hay tarjetas".
  Widget _creditCardStatusFooter(
    AsyncValue<List<Map<String, dynamic>>> cardsAsync,
    bool toggleOn,
  ) {
    if (!toggleOn) return const SizedBox.shrink();
    return cardsAsync.when(
      data: (cards) {
        if (cards.isNotEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            'No hay tarjetas de crédito registradas en la bóveda',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.warning,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Cargando tarjetas...',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'No se pudieron cargar las tarjetas',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.expense,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(accountsListProvider);
                ref.invalidate(creditCardsWithDebtProvider);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing, bool isDark) {
    Color buttonColor;
    if (_type == 'expense') {
      buttonColor = AppColors.expense;
    } else if (_type == 'income') {
      buttonColor = AppColors.income;
    } else {
      buttonColor = AppColors.investment;
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        gradient: LinearGradient(
          colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        child: Text(
          isEditing ? 'Actualizar Transacción' : 'Guardar Transacción',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String finalCategory = 'General';
      String? finalBudgetId;

      if (_selectionValue != null) {
        if (_selectionValue!.startsWith("budget:")) {
          finalBudgetId = _selectionValue!.split(":")[1];
          final householdAsync = ref.read(householdProvider);
          final String? targetAuthId = _context == 'household'
              ? householdAsync.valueOrNull?.id
              : null;
          final budgets = await ref.read(
            budgetsListProvider(targetAuthId).future,
          );
          final budget = budgets.firstWhere(
            (b) => b.id == finalBudgetId,
            orElse: () => Budget(
              id: '',
              userId: '',
              category: 'General',
              limitAmount: 0,
              period: '',
            ),
          );
          finalCategory = budget.category;
        } else {
          finalCategory = _selectionValue!.split(":")[1];
        }
      } else {
        finalCategory = _type == 'transfer' ? 'Transferencia' : 'General';
      }

      String? finalHouseholdId;
      if (_context == 'household') {
        final householdAsync = ref.read(householdProvider);
        if (householdAsync.value != null) {
          finalHouseholdId = householdAsync.value!.id;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No tienes un hogar configurado.')),
            );
          }
          return;
        }
      }

      try {
        if (widget.transactionToEdit != null) {
          final t = widget.transactionToEdit!;

          final isCanonicalPayment = _isCanonicalCardPayment(t);
          final toUpdate = Transaction(
            id: t.id,
            accountId: _accountId!,
            amount: _amount,
            type: _type,
            category: isCanonicalPayment ? t.category : finalCategory,
            description: _description,
            date: _date,
            context: isCanonicalPayment ? t.context : _context,
            householdId: isCanonicalPayment ? t.householdId : finalHouseholdId,
            budgetId: isCanonicalPayment ? null : finalBudgetId,
            destinationAccountId: _destinationAccountId,
            pocketId: _pocketId,
            userId: t.userId,
            excludeFromBalance: _excludeFromBalance,
            paidWithCreditCard: isCanonicalPayment
                ? false
                : _type == 'expense'
                ? _paidWithCreditCard
                : false,
            creditCardAccountId: null,
            vaultCardId: isCanonicalPayment
                ? t.vaultCardId
                : _type == 'expense' && _paidWithCreditCard
                ? _creditCardAccountId
                : null,
            installments: isCanonicalPayment
                ? 1
                : _paidWithCreditCard
                ? _installments
                : 1,
          );

          await ref
              .read(transactionRepositoryProvider)
              .updateTransaction(toUpdate);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transacción actualizada')),
            );
          }
        } else if (_payingCreditCard &&
            _creditCardAccountId != null &&
            _accountId != null &&
            _amount > 0) {
          // Paying down a card: record ONLY the payment. The backend keys the
          // effect to the card and subtracts the cash itself. Creating a twin
          // generic transaction here would re-add the debt (double-write).
          await ref
              .read(transactionRepositoryProvider)
              .payCreditCard(
                vaultCardId: _creditCardAccountId!,
                amount: _amount,
                accountId: _accountId!,
                date: _date,
                description: _description.isNotEmpty
                    ? _description
                    : 'Pago de deuda tarjeta',
              );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Pago registrado')));
          }
        } else {
          await ref
              .read(transactionRepositoryProvider)
              .createTransaction(
                accountId: _accountId!,
                amount: _amount,
                type: _type,
                category: finalCategory,
                description: _description,
                date: _date,
                context: _context,
                householdId: finalHouseholdId,
                budgetId: finalBudgetId,
                destinationAccountId: _destinationAccountId,
                pocketId: _pocketId,
                excludeFromBalance: _excludeFromBalance,
                paidWithCreditCard: _type == 'expense'
                    ? _paidWithCreditCard
                    : false,
                creditCardAccountId: null,
                vaultCardId: _type == 'expense' && _paidWithCreditCard
                    ? _creditCardAccountId
                    : null,
                installments: _paidWithCreditCard ? _installments : 1,
              );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Transacción creada')));
          }
        }

        // Every create/update/pay path moves money: refresh the tx effect set.
        // The card's debt is keyed by its OWNER account, not the paying account,
        // so ALSO refresh the debt rollups whenever credit-card debt changed —
        // that is BOTH paying down a card (_payingCreditCard) AND charging an
        // expense to a card (_paidWithCreditCard). The previous code only fired
        // debtEffects on the pay-down path, so a card expense left the debt
        // summary stale (new-b7-2). One call with the union scope avoids the
        // double-invalidation the old branch risked (R4).
        final paidDebtChanged =
            (_payingCreditCard && _creditCardAccountId != null) ||
            (_type == 'expense' && _paidWithCreditCard);
        invalidateAfterMutation(
          ref,
          scope: {
            DataMutation.txEffects,
            if (paidDebtChanged) DataMutation.debtEffects,
          },
        );

        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
