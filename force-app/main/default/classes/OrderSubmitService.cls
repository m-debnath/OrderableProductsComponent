public with sharing class OrderSubmitService {
  public static String submitOrder(String sOrderId) {
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
        request.setEndpoint('callout:Request_Catcher_Creds/test/'); // Make sure to add password in Named Credentials
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
          // Activate the order on successful api response
          order.Status = 'Activated';
          update order;
          result = 'SUCCESS';
        } else {
          result = 'Order submit failed.';
        }
      }
      return result;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
