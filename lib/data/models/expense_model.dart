class Expense {
  DateTime date;
  String description;
  double value;
  String category;
  String subcategory;
  String paymentAccount;

  Expense({
    required this.date,
    required this.description,
    required this.value,
    required this.category,
    required this.subcategory,
    required this.paymentAccount,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'description': description,
      'value': value,
      'category': category,
      'subcategory': subcategory,
      'paymentAccount': paymentAccount,
    };
  }
}
