enum SettlementDirection { settled, debtor, creditor, observer }

String contributionLabel(String label, double share, double totalAmount) {
  final percentage = totalAmount == 0 ? 0 : (share / totalAmount * 100).round();
  return '$label ($percentage%)';
}

SettlementDirection settlementDirection({
  required double balance,
  required String debtorId,
  required String creditorId,
  required String? currentUserId,
}) {
  if (balance <= 0) return SettlementDirection.settled;
  if (debtorId == currentUserId) return SettlementDirection.debtor;
  if (creditorId == currentUserId) return SettlementDirection.creditor;
  return SettlementDirection.observer;
}
