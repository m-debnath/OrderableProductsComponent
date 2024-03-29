public with sharing class OrderableProductsController {
  static Integer gLimit = 5;
  static Integer gOffset = 5;

  /**
   * Lists all the Products present in active
   * Price Book Entry for the given Order.
   */
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

  /**
   * Counts all the Products present in active
   * Price Book Entry for the given Order.
   */
  @AuraEnabled(cacheable=true)
  public static Integer countEligibleProducts(ID sOrderId) {
    try {
      // Check if Price Book is associated with Order.
      List<order> orders = [
        SELECT Id, Pricebook2Id
        FROM Order
        WHERE Id = :sOrderId
      ];
      if (String.isBlank(orders[0].Pricebook2Id)) {
        return -1;
      }
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
