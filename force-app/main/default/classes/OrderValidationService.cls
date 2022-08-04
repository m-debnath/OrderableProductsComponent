public with sharing class OrderValidationService {
  public static String validateOrder(String sOrderId) {
    try {
      List<Order> orders = [
        SELECT Id, Account.AccountNumber, OrderNumber, Status, Type
        FROM Order
        WHERE Id = :sOrderId
      ];
      List<OrderItem> orderItems = [
        SELECT Id, Product2.Name, Product2.ProductCode, UnitPrice, Quantity
        FROM OrderItem
        WHERE OrderId = :sOrderId
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
