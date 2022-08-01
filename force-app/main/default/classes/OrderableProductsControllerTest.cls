@IsTest
public class OrderableProductsControllerTest {
  static Integer gNumProducts = 17;
  static Integer gNumOrders = 1;
  static Integer gOffset = 0;
  static Integer gLimit = 5;

  @testSetup
  static void setup() {
    Integer numProducts = 17;
    TestDataFactory.createProductsAndPrices(numProducts);
    TestDataFactory.createOrder();
  }

  @isTest
  static void TestTestDataFactory() {
    // Verify Products
    List<Product2> products = [SELECT Id FROM Product2 LIMIT 100];
    System.assertEquals(
      gNumProducts,
      products.size(),
      'Product creation failed.'
    );

    // Verify Pricebook Entries
    PricebookEntry[] pricebookentries = [
      SELECT Id
      FROM PricebookEntry
      WHERE Pricebook2Id = :Test.getStandardPricebookId() AND IsActive = TRUE
      LIMIT 100
    ];
    System.assertEquals(
      gNumProducts,
      pricebookentries.size(),
      'Price Book Entry creation failed.'
    );

    // Verify Order
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size());
  }

  @isTest
  static void TestCountEligibleProducts() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    // Verify Eligible Products Count
    Integer nEligibleProducts = OrderableProductsController.countEligibleProducts(
      orders[0].Id
    );
    System.assertEquals(
      gNumProducts,
      nEligibleProducts,
      'Could not get eligible products count.'
    );
  }

  @isTest
  static void TestListEligibleProducts() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    // Verify Eligible Products
    List<PricebookEntry> pricebookentries = OrderableProductsController.listEligibleProducts(
      orders[0].Id,
      gOffset,
      gLimit
    );
    System.assertEquals(
      gLimit,
      pricebookentries.size(),
      'Could not get list of eligible products.'
    );
  }

  @isTest
  static void TestListEligibleProductsWithInvalidInput() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    // Verify Eligible Products
    List<PricebookEntry> pricebookentries = OrderableProductsController.listEligibleProducts(
      orders[0].Id,
      -1,
      -1
    );
    System.assertEquals(
      gLimit,
      pricebookentries.size(),
      'Expects ' +
      gLimit +
      ' products. Does not match.'
    );
  }
}
