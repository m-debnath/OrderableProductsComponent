public with sharing class OrderableProductsController {
  static Integer gLimit = 5;
  static Integer gOffset = 5;

  @AuraEnabled(cacheable=true)
  public static List<PricebookEntry> listEligibleProducts(
    ID sOrderId,
    Integer sOffset
  ) {
    // Validation for negative numbers
    if (sOffset < 0) {
      sOffset = gOffset;
    }
    try {
      // Paginate all the active Pricebook Entries for Current Order's Pricebook Id
      return [
        SELECT Id, Name, Product2Id, ProductCode, UnitPrice
        FROM PricebookEntry
        WHERE
          IsActive = TRUE
          AND Pricebook2Id IN (
            SELECT Pricebook2Id
            FROM Order
            WHERE Id = :sOrderId
          )
        ORDER BY Name ASC
        LIMIT :gLimit
        OFFSET :sOffset
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static Integer countEligibleProducts(ID sOrderId) {
    try {
      return [
        SELECT COUNT()
        FROM PricebookEntry
        WHERE
          IsActive = TRUE
          AND Pricebook2Id IN (
            SELECT Pricebook2Id
            FROM Order
            WHERE Id = :sOrderId
          )
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Order> getOrderStatus(ID sOrderId) {
    try {
      return [SELECT Id, Status FROM Order WHERE Id = :sOrderId];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
