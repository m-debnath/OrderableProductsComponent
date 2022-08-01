@IsTest
public class OrderProductsControllerTest {
  static Integer gNumProducts = 17;
  static Integer gNumOrders = 1;
  static Integer gOffset = 0;
  static Integer gLimit = 5;
  static String gDraftStatus = 'Draft';

  @testSetup
  static void setup() {
    Integer numProducts = 17;
    TestDataFactory.createProductsAndPrices(numProducts);
    TestDataFactory.createOrder();
  }

  @isTest
  static void TestGetOrderStatus() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    String orderStatus = OrderProductsController.getOrderStatus(orders[0].Id);
    System.assertEquals(
      gDraftStatus,
      orderStatus,
      'Order status is not ' +
      gDraftStatus +
      '.'
    );
  }

  @isTest
  static void TestAddProductToOrder() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    List<PricebookEntry> priceBookEntries = OrderableProductsController.listEligibleProducts(
      orders[0].Id,
      gOffset,
      gLimit
    );
    System.assertEquals(
      gLimit,
      priceBookEntries.size(),
      'Could not get list of eligble price book entries.'
    );

    for (PriceBookEntry priceBookEntry : priceBookEntries) {
      OrderProductsController.addProductToOrder(
        orders[0].Id,
        priceBookEntry.Product2Id,
        priceBookEntry.Id,
        priceBookEntry.UnitPrice
      );
    }

    Integer countOrderProducts = (Integer) OrderProductsController.getOrderProductsTotalQuantity(
      orders[0].Id
    );
    System.assertEquals(
      gLimit,
      countOrderProducts,
      'Order Products count mismatch. Expected ' +
      gLimit +
      '.'
    );
  }

  @isTest
  static void TestListOrderProducts() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    List<PricebookEntry> pricebookentries = OrderableProductsController.listEligibleProducts(
      orders[0].Id,
      gOffset,
      gLimit
    );
    List<String> priceBookEntryIds = new List<String>();
    System.assertEquals(
      gLimit,
      pricebookentries.size(),
      'Could not get list of eligble price book entries.'
    );

    // Add Products to Order
    for (PriceBookEntry priceBookEntry : pricebookentries) {
      OrderProductsController.addProductToOrder(
        orders[0].Id,
        priceBookEntry.Product2Id,
        priceBookEntry.Id,
        priceBookEntry.UnitPrice
      );
      priceBookEntryIds.add(priceBookEntry.Id);
    }
    priceBookEntryIds.sort();

    List<OrderItem> orderProducts = OrderProductsController.listOrderProducts(
      orders[0].Id
    );
    List<String> orderProductIds = new List<String>();
    System.assertEquals(
      gLimit,
      orderProducts.size(),
      'Could not get list of order products.'
    );

    for (OrderItem item : orderProducts) {
      orderProductIds.add(item.PricebookEntryId);
    }
    orderProductIds.sort();
    System.assertEquals(
      orderProductIds,
      priceBookEntryIds,
      'Price Book entries does not match Order Products.'
    );
  }
}
