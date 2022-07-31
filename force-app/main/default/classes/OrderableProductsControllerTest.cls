@IsTest
public class OrderableProductsControllerTest {
  @testSetup
  static void setup() {
    Integer numProducts = 17;
    TestDataFactory.createProductsAndPrices(numProducts);
    TestDataFactory.createOrder();
  }

  @isTest
  static void TestTestDataFactory() {
    Integer numProducts = 17;
    Integer numOrders = 1;

    // Verify Products
    List<Product2> products = [SELECT Id FROM Product2 LIMIT 100];
    System.assertEquals(numProducts, products.size());

    // Verify Pricebook Entries
    PricebookEntry[] pricebookentries = [
      SELECT Id
      FROM PricebookEntry
      WHERE Pricebook2Id = :Test.getStandardPricebookId() AND IsActive = TRUE
      LIMIT 100
    ];
    System.assertEquals(numProducts, pricebookentries.size());

    // Verify Order
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(numOrders, orders.size());
  }
}

/*
          Name = 'GenWatt Diesel ' + i + '01kW',
          ProductCode = 'GC' + i + '01',
*/

