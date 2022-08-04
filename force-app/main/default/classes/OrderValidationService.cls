public with sharing class OrderValidationService {
  String sOrderId;

  public OrderValidationService(String sOrderId) {
    this.sOrderId = sOrderId;
  }

  public String validateOrder() {
    try {
      List<Order> orders = [
        SELECT Id, Account.AccountNumber, OrderNumber, Status, Type
        FROM Order
        WHERE Id = :this.sOrderId
      ];
      List<OrderItem> orderItems = [
        SELECT Id, Product2.Name, Product2.ProductCode, UnitPrice, Quantity
        FROM OrderItem
        WHERE OrderId = :this.sOrderId
      ];
      if (orders.size() != 1) {
        return 'Order not found.';
      } else {
        if (orders[0].Status != 'Draft') {
          return 'Order should be in "Draft" status.';
        } else {
          if (orderItems.size() > 0) {
            return 'SUCCESS';
          } else {
            return 'Order does not have any products.';
          }
        }
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
