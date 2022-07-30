public with sharing class OrderProductsController {
  @AuraEnabled(cacheable=true)
  public static List<OrderItem> listOrderProducts(ID sOrderId) {
    try {
      return [
        SELECT
          Id,
          Order.Status,
          Product2.Name,
          Quantity,
          TotalPrice,
          UnitPrice,
          PricebookEntryId
        FROM OrderItem
        WHERE OrderId = :sOrderId
        ORDER BY CreatedDate ASC NULLS FIRST
        LIMIT 50000
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static Decimal getOrderProductsTotalPrice(ID sOrderId) {
    Decimal total_price;
    try {
      List<AggregateResult> result = [
        SELECT SUM(TotalPrice)
        FROM OrderItem
        WHERE OrderId = :sOrderId
      ];
      total_price = (Decimal) result[0].get('expr0');
      return total_price;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static Decimal getOrderProductsTotalQuantity(ID sOrderId) {
    Decimal total_quantity;
    try {
      List<AggregateResult> result = [
        SELECT SUM(Quantity)
        FROM OrderItem
        WHERE OrderId = :sOrderId
      ];
      total_quantity = (Decimal) result[0].get('expr0');
      return total_quantity;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<Id> addProductToOrder(
    ID sOrderId,
    ID sProductId,
    ID sPricebookEntryId,
    Decimal nUnitPrice
  ) {
    Boolean bProductFound = false;
    List<Id> updatedIds = new List<Id>();
    updatedIds.add(sOrderId);
    try {
      List<OrderItem> existingProducts = [
        SELECT Id, Quantity
        FROM OrderItem
        WHERE OrderId = :sOrderId AND Product2id = :sProductId
      ];
      if (existingProducts.size() > 0) {
        for (OrderItem item : existingProducts) {
          item.Quantity = item.Quantity + 1;
          bProductFound = true;
        }
        update existingProducts;
      } else {
        OrderItem lineItem = new OrderItem();
        lineItem.OrderId = sOrderId;
        lineItem.Quantity = 1;
        lineItem.UnitPrice = nUnitPrice;
        lineItem.Product2id = sProductId;
        lineItem.PricebookEntryId = sPricebookEntryId;
        insert lineItem;
      }
      return updatedIds;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<Id> deleteProductFromOrder(ID sOrderId, ID sOrderItemId) {
    Boolean bToUpdate = false;
    List<Id> updatedIds = new List<Id>();
    updatedIds.add(sOrderId);
    try {
      List<OrderItem> existingProducts = [
        SELECT Id, Quantity
        FROM OrderItem
        WHERE Id = :sOrderItemId
      ];
      if (existingProducts.size() > 0) {
        for (OrderItem item : existingProducts) {
          if (item.Quantity > 1) {
            item.Quantity = item.Quantity - 1;
            bToUpdate = true;
          }
        }
        if (bToUpdate) {
          update existingProducts;
        } else {
          delete existingProducts;
        }
      }
      return updatedIds;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
