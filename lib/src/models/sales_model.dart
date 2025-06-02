// Model class for Sales Item
class SalesItem {
  int? expenseCategoryId;
  String? product = 'Product';
  String? unit = 'UNIT';
  String description = '';
  int quantity = 0;
  double price = 0.0;
  double total = 0.0;
  double discount = 0.0;
  double vatAmount = 0.0;
  double subtotal = 0.0;

  SalesItem({
    this.expenseCategoryId,
    this.product,
    this.unit,
    this.description = '',
    this.quantity = 0,
    this.price = 0.0,
    this.total = 0.0,
    this.discount = 0.0,
    this.vatAmount = 0.0,
    this.subtotal = 0.0,
  });
}
