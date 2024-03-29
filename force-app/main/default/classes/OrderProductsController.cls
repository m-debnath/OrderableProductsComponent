public with sharing class OrderProductsController {
  /**
   * Queries and returns Order Products for given Order.
   */
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

  /**
   * Queries and returns Order Status for given Order.
   */
  @AuraEnabled(cacheable=true)
  public static String getOrderStatus(ID sOrderId) {
    String order_status;
    try {
      List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :sOrderId];
      return (String) orders[0].get('Status');
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Queries and returns Total Price for all
   * Order Products for given Order.
   */
  @AuraEnabled(cacheable=true)
  public static Decimal getOrderProductsTotalPrice(ID sOrderId) {
    Decimal total_price;
    try {
      List<AggregateResult> result = [
        SELECT SUM(TotalPrice)
        FROM OrderItem
        WHERE OrderId = :sOrderId
      ];
      total_price = String.isBlank(String.valueOf(result[0].get('expr0')))
        ? 0
        : (Decimal) result[0].get('expr0');
      return total_price;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Queries and returns Total Quantity of
   * Order Products for given Order.
   */
  @AuraEnabled(cacheable=true)
  public static Decimal getOrderProductsTotalQuantity(ID sOrderId) {
    Decimal total_quantity;
    try {
      List<AggregateResult> result = [
        SELECT SUM(Quantity)
        FROM OrderItem
        WHERE OrderId = :sOrderId
      ];
      total_quantity = String.isBlank(String.valueOf(result[0].get('expr0')))
        ? 0
        : (Decimal) result[0].get('expr0');
      return total_quantity;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Adds a new Product to given Order.
   */
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

  /**
   * Removes a Product to given Order.
   */
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

  /**
   * Assigns Standard Pricebook to Order.
   */
  @AuraEnabled
  public static List<Id> assignPricebook2Id(ID sOrderId) {
    List<Id> updatedIds = new List<Id>();
    updatedIds.add(sOrderId);
    Id standardPricebook2Id;
    List<Pricebook2> pricebooks = [
      SELECT Id
      FROM PriceBook2
      WHERE IsStandard = TRUE
    ];
    try {
      if (pricebooks.size() > 0) {
        standardPricebook2Id = pricebooks[0].Id;
        List<Order> orders = [
          SELECT Id, Pricebook2Id
          FROM Order
          WHERE Id = :sOrderId
        ];
        if (orders.size() > 0) {
          for (Order order : orders) {
            order.Pricebook2Id = standardPricebook2Id;
          }
          update orders;
        }
      }
      return updatedIds;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Submits the given order to external API.
   */
  @AuraEnabled
  public static Map<String, String> submitOrderRequest(ID sOrderId) {
    JSONGenerator gen = JSON.createGenerator(true);
    Map<String, String> result = new Map<String, String>();
    try {
      OrderServices orderServices = new OrderServices();
      String validationResult = orderServices.validateOrder(sOrderId);
      if (validationResult != 'SUCCESS') {
        result.put('code', '400');
        result.put('message', validationResult);
      } else {
        String submitResult = orderServices.submitOrder(sOrderId);
        if (submitResult != 'SUCCESS') {
          result.put('code', '400');
          result.put('message', submitResult);
        } else {
          result.put('code', '200');
          result.put('message', 'SUCCESS');
          List<Order> orders = [
            SELECT Id, Account.AccountNumber, OrderNumber, Status, Type
            FROM Order
            WHERE Id = :sOrderId
          ];
          for (Order order : orders) {
            // Activate the order on successful api response
            order.Status = 'Activated';
            update order;
          }
        }
      }
      return result;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
