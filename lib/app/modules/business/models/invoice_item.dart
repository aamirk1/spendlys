class InvoiceItem {
  String description;
  double quantity;
  double unitPrice;
  double get amount => quantity * unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
        "description": description,
        "quantity": quantity,
        "unit_price": unitPrice,
        "amount": amount,
      };
}
