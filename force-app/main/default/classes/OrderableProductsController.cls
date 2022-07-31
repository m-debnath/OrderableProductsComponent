public with sharing class OrderableProductsController {
  static Integer gLimit = 5;
  static Integer gOffset = 5;

  @AuraEnabled(cacheable=true)
  public static List<PricebookEntry> listEligibleProducts(
    ID sOrderId,
    Integer nOffset,
    Integer nLimit
  ) {
    // Validation for negative numbers
    if (nOffset < 0) {
      nOffset = gOffset;
    }
    if (nLimit < 0) {
      nLimit = gLimit;
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
        LIMIT :nLimit
        OFFSET :nOffset
      ];
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
