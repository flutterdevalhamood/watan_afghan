// Updated Model class for Sales Item
class SalesItem {
  int? productId;
  int? unitId;
  String? fromInvId; // Add this property
  String? product = 'Product';
  String? unit = 'UNIT';
  String? fromInv = 'From Inventory'; // Add this property
  String description = '';
  int quantity = 0;
  double price = 0.0;
  double total = 0.0;
  double taxRate = 0.0; // Tax percentage (0.0 or 0.5)
  double taxAmount = 0.0; // Calculated tax amount
  double totalWithTax = 0.0; // Total including tax
  double discount = 0.0;
  double vatAmount = 0.0;
  double subtotal = 0.0;

  SalesItem({
    this.productId,
    this.unitId,
    this.fromInvId, // Add this parameter
    this.product,
    this.unit,
    this.fromInv, // Add this parameter
    this.description = '',
    this.quantity = 0,
    this.price = 0.0,
    this.total = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.totalWithTax = 0.0,
    this.discount = 0.0,
    this.vatAmount = 0.0,
    this.subtotal = 0.0,
  });
}
