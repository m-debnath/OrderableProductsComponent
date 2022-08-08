/**
 * Represents various methods related to order.
 * E.g. Order validation.
 * E.g. Order submission.
 */
public with sharing class OrderServices {
  /**
   * Validates an order before submission.
   * @param sOrderId Order Id
   */
  public String validateOrder(String sOrderId) {
    try {
      List<Order> orders = [
        SELECT Id, Account.AccountNumber, OrderNumber, Status, Type
        FROM Order
        WHERE Id = :sOrderId
      ];
      if (orders.size() != 1) {
        return 'Order not found.';
      } else {
        if (orders[0].Status != 'Draft') {
          return 'Order should be in "Draft" status.';
        }
        if (String.isBlank(orders[0].Account.AccountNumber)) {
          return 'Account Number should be present.';
        }
        if (String.isBlank(orders[0].Type)) {
          return 'Order Type should not be blank.';
        }
        List<Contract> contracts = [
          SELECT Id, Status
          FROM Contract
          WHERE Id IN (SELECT ContractId FROM Order WHERE Id = :sOrderId)
        ];
        if (contracts.size() != 1) {
          return 'Order should have an Activated Contract.';
        } else {
          if (contracts[0].Status != 'Activated') {
            return 'Order should have an Activated Contract.';
          }
        }
        List<OrderItem> orderItems = [
          SELECT Id, Product2.Name, Product2.ProductCode, UnitPrice, Quantity
          FROM OrderItem
          WHERE OrderId = :sOrderId
        ];
        if (orderItems.size() > 0) {
          return 'SUCCESS';
        } else {
          return 'Order does not have any products.';
        }
      }
    } catch (Exception e) {
      return e.getMessage();
    }
  }

  /**
   * Submits an order to external API.
   * @param sOrderId Order Id
   */
  public String submitOrder(String sOrderId) {
    JSONGenerator gen = JSON.createGenerator(true);
    String result;
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
      for (Order order : orders) {
        gen.writeStartObject();
        gen.writeStringField('accountNumber', order.Account.AccountNumber);
        gen.writeStringField('orderNumber', order.OrderNumber);
        gen.writeStringField('type', order.Type);
        gen.writeStringField('status', order.Status);
        gen.writeFieldName('orderProducts');
        gen.writeStartArray();
        for (OrderItem item : orderItems) {
          gen.writeStartObject();
          gen.writeStringField('name', item.Product2.Name);
          gen.writeStringField('code', item.Product2.ProductCode);
          gen.writeNumberField('unitPrice', item.UnitPrice);
          gen.writeNumberField('quantity', (Integer) item.Quantity);
          gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();
        String requestBody = gen.getAsString();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Request_Catcher_Creds/test/');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
          result = 'SUCCESS';
        } else {
          result = 'Order submit failed.';
        }
      }
      return result;
    } catch (Exception e) {
      return e.getMessage();
    }
  }
}
