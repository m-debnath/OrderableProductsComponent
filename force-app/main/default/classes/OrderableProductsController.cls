public with sharing class OrderableProductsController {
  static Integer gLimit = 5;
  static Integer gOffset = 5;

  @AuraEnabled(cacheable=true)
  public static Map<String, List<SObject>> listEligibleProducts(
    ID sOrderId,
    Integer sOffset
  ) {
    // Validation for negative numbers
    if (sOffset < 0) {
      sOffset = gOffset;
    }
    Map<String, List<SObject>> result = new Map<String, List<SObject>>();
    try {
      // Paginate all the active Pricebook Entries for Current Order's Pricebook Id
      List<PricebookEntry> pricebookEntries = [
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
      // To display actions based on order status on LWC.
      List<Order> orders = [SELECT Status FROM Order WHERE Id = :sOrderId];
      result.put('PricebookEntry', pricebookEntries);
      result.put('Order', orders);
      return result;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static Integer countEligibleProducts(ID sOrderId) {
    try {
      // Count all the active Pricebook Entries for Current Order's Pricebook Id
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
}
