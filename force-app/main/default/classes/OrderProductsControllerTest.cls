@IsTest
public class OrderProductsControllerTest {
  static Integer gNumProducts = 17;
  static Integer gNumOrders = 1;
  static Integer gOffset = 0;
  static Integer gLimit = 5;
  static String gDraftStatus = 'Draft';
  static String gActivetStatus = 'Activated';
  static String gSubmitResponseSuccessCode = '200';
  static String gSubmitResponseFailure = '400';
  static String gSubmitOrderNotFound = 'Order not found.';
  static String gSubmitOrderNotDraft = 'Order should be in "Draft" status.';
  static String gSubmitOrderSubmitFailed = 'Order submit failed.';
  static String gAccountNumberMissingMessage = 'Account Number should be present.';
  static String gActiveContractMissingMessage = 'Order should have an Activated Contract.';

  private class RestMockSuccess implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HTTPResponse res = new HTTPResponse();
      res.setStatusCode(Integer.valueOf(gSubmitResponseSuccessCode));
      return res;
    }
  }

  private class RestMockFailure implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HTTPResponse res = new HTTPResponse();
      res.setStatusCode(Integer.valueOf(gSubmitResponseFailure));
      return res;
    }
  }

  @testSetup
  static void setup() {
    Integer numProducts = 17;
    TestDataFactory.createProductsAndPrices(numProducts);
    TestDataFactory.createOrder();
    TestDataFactory.createOrderDraftContract();
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
    System.assertEquals(gDraftStatus, orderStatus, 'Order status mismatch.');
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
      'Order Products count mismatch.'
    );
  }

  @isTest
  static void TestAddExistingProductToOrder() {
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

    // Add those products again
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
      (gLimit * 2),
      countOrderProducts,
      'Order Products count mismatch.'
    );
  }

  @isTest
  static void TestGetOrderProductsTotalQuantity() {
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

    Integer countOrderProducts = (Integer) OrderProductsController.getOrderProductsTotalQuantity(
      orders[0].Id
    );
    System.assertEquals(
      gLimit,
      countOrderProducts,
      'Order Products count mismatch.'
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

  @isTest
  static void TestDeleteProductFromOrder() {
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
    List<String> priceBookEntryIds = new List<String>();
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
      priceBookEntryIds.add(priceBookEntry.Id);
    }
    priceBookEntryIds.sort();

    // Add those products again
    for (PriceBookEntry priceBookEntry : priceBookEntries) {
      OrderProductsController.addProductToOrder(
        orders[0].Id,
        priceBookEntry.Product2Id,
        priceBookEntry.Id,
        priceBookEntry.UnitPrice
      );
    }

    // List the order products
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
      orderProductIds.add(item.Id);
    }
    orderProductIds.sort();
    Integer countOrderProducts = (Integer) OrderProductsController.getOrderProductsTotalQuantity(
      orders[0].Id
    );
    System.assertEquals(
      (gLimit * 2),
      countOrderProducts,
      'Order Products count mismatch.'
    );

    // Delete products once
    for (String orderProductId : orderProductIds) {
      OrderProductsController.deleteProductFromOrder(
        orders[0].Id,
        orderProductId
      );
    }
    countOrderProducts = (Integer) OrderProductsController.getOrderProductsTotalQuantity(
      orders[0].Id
    );
    System.assertEquals(
      gLimit,
      countOrderProducts,
      'Order Products count mismatch after delete.'
    );

    // Delete products again
    for (String orderProductId : orderProductIds) {
      OrderProductsController.deleteProductFromOrder(
        orders[0].Id,
        orderProductId
      );
    }
    countOrderProducts = (Integer) OrderProductsController.getOrderProductsTotalQuantity(
      orders[0].Id
    );
    System.assertEquals(
      0,
      countOrderProducts,
      'Order Products count mismatch after last products delete.'
    );
  }

  @isTest
  static void TestGetOrderProductsTotalPrice() {
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
    Decimal totalProductPrice = 0;
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
      totalProductPrice = totalProductPrice + priceBookEntry.UnitPrice;
    }

    // List the order products
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
      orderProductIds.add(item.Id);
    }
    orderProductIds.sort();

    // Get Order total price
    Decimal totalOrderPrice = OrderProductsController.getOrderProductsTotalPrice(
      orders[0].id
    );
    System.assertEquals(
      totalProductPrice,
      totalOrderPrice,
      'Order total price not matched.'
    );

    // Delete products
    for (String orderProductId : orderProductIds) {
      OrderProductsController.deleteProductFromOrder(
        orders[0].Id,
        orderProductId
      );
    }
    Decimal countOrderProducts = (Integer) OrderProductsController.getOrderProductsTotalQuantity(
      orders[0].Id
    );
    System.assertEquals(
      0,
      countOrderProducts,
      'Order Products count mismatch after delete.'
    );

    // Get Order total price
    totalOrderPrice = OrderProductsController.getOrderProductsTotalPrice(
      orders[0].id
    );
    System.assertEquals(0.0, totalOrderPrice, 'Order total price not matched.');
  }

  @isTest
  static void TestSubmitOrderRequest() {
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
    Decimal totalProductPrice = 0;
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
      totalProductPrice = totalProductPrice + priceBookEntry.UnitPrice;
    }

    // List the order products
    List<OrderItem> orderProducts = OrderProductsController.listOrderProducts(
      orders[0].Id
    );
    List<String> orderProductIds = new List<String>();
    System.assertEquals(
      gLimit,
      orderProducts.size(),
      'Could not get list of order products.'
    );

    // Submit Order
    Test.setMock(HttpCalloutMock.class, new RestMockSuccess());
    Test.startTest();
    Map<String, String> response = OrderProductsController.submitOrderRequest(
      orders[0].Id
    );
    Test.StopTest();
    System.assertEquals(
      gSubmitResponseSuccessCode,
      response.get('code'),
      'Submit order response not success.'
    );

    // Check order status to be Activated
    orders = [SELECT Id, Status FROM Order WHERE Account.Name = 'Test Account'];
    System.assertEquals(
      gActivetStatus,
      orders[0].Status,
      'Order not activated.'
    );
  }

  @isTest
  static void TestSubmitOrderRequestFailed() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    // Get eligibile products
    List<PricebookEntry> priceBookEntries = OrderableProductsController.listEligibleProducts(
      orders[0].Id,
      gOffset,
      gLimit
    );
    Decimal totalProductPrice = 0;
    System.assertEquals(
      gLimit,
      priceBookEntries.size(),
      'Could not get list of eligble price book entries.'
    );

    // Add products to order
    for (PriceBookEntry priceBookEntry : priceBookEntries) {
      OrderProductsController.addProductToOrder(
        orders[0].Id,
        priceBookEntry.Product2Id,
        priceBookEntry.Id,
        priceBookEntry.UnitPrice
      );
      totalProductPrice = totalProductPrice + priceBookEntry.UnitPrice;
    }

    // List the order products
    List<OrderItem> orderProducts = OrderProductsController.listOrderProducts(
      orders[0].Id
    );
    List<String> orderProductIds = new List<String>();
    System.assertEquals(
      gLimit,
      orderProducts.size(),
      'Could not get list of order products.'
    );

    // Submit Order
    Test.setMock(HttpCalloutMock.class, new RestMockFailure());
    Test.startTest();
    Map<String, String> response = OrderProductsController.submitOrderRequest(
      orders[0].Id
    );
    Test.StopTest();
    System.assertEquals(
      gSubmitResponseFailure,
      response.get('code'),
      'Submit order response not failure.'
    );
    System.assertEquals(
      gSubmitOrderSubmitFailed,
      response.get('message'),
      'Submit order response message does not match.'
    );

    // Check order status to be Activated
    orders = [SELECT Id, Status FROM Order WHERE Account.Name = 'Test Account'];
    System.assertEquals(
      gDraftStatus,
      orders[0].Status,
      'Order status does not match.'
    );
  }

  @isTest
  static void TestSubmitOrderRequestNotDraft() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    // Get eligible products
    List<PricebookEntry> priceBookEntries = OrderableProductsController.listEligibleProducts(
      orders[0].Id,
      gOffset,
      gLimit
    );
    Decimal totalProductPrice = 0;
    System.assertEquals(
      gLimit,
      priceBookEntries.size(),
      'Could not get list of eligble price book entries.'
    );

    // Add products to order
    for (PriceBookEntry priceBookEntry : priceBookEntries) {
      OrderProductsController.addProductToOrder(
        orders[0].Id,
        priceBookEntry.Product2Id,
        priceBookEntry.Id,
        priceBookEntry.UnitPrice
      );
      totalProductPrice = totalProductPrice + priceBookEntry.UnitPrice;
    }

    // Activate the order
    for (Order order : orders) {
      order.Status = gActivetStatus;
    }
    update orders;

    // Submit Order
    Test.setMock(HttpCalloutMock.class, new RestMockSuccess());
    Test.startTest();
    Map<String, String> response = OrderProductsController.submitOrderRequest(
      orders[0].Id
    );
    Test.StopTest();
    System.assertEquals(
      gSubmitResponseFailure,
      response.get('code'),
      'Submit order response not failure.'
    );
    System.assertEquals(
      gSubmitOrderNotDraft,
      response.get('message'),
      'Submit order response message does not match.'
    );
  }

  @isTest
  static void TestSubmitOrderRequestNotFound() {
    // Submit Order
    Test.setMock(HttpCalloutMock.class, new RestMockSuccess());
    Test.startTest();
    Map<String, String> response = OrderProductsController.submitOrderRequest(
      '801Iw000000FXXyIAO'
    );
    Test.StopTest();
    System.assertEquals(
      gSubmitResponseFailure,
      response.get('code'),
      'Submit order response not failure.'
    );
    System.assertEquals(
      gSubmitOrderNotFound,
      response.get('message'),
      'Submit order response message does not match.'
    );
  }

  @isTest
  static void TestSubmitOrderMissingAccountNumber() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    // Nullify Account Number
    List<Account> accounts = [
      SELECT Id, AccountNumber
      FROM Account
      WHERE Name = 'Test Account'
    ];
    for (Account account : accounts) {
      account.AccountNumber = '';
    }
    update accounts;

    // Get eligible products
    List<PricebookEntry> priceBookEntries = OrderableProductsController.listEligibleProducts(
      orders[0].Id,
      gOffset,
      gLimit
    );
    Decimal totalProductPrice = 0;
    System.assertEquals(
      gLimit,
      priceBookEntries.size(),
      'Could not get list of eligble price book entries.'
    );

    // Add products to order
    for (PriceBookEntry priceBookEntry : priceBookEntries) {
      OrderProductsController.addProductToOrder(
        orders[0].Id,
        priceBookEntry.Product2Id,
        priceBookEntry.Id,
        priceBookEntry.UnitPrice
      );
      totalProductPrice = totalProductPrice + priceBookEntry.UnitPrice;
    }

    // Submit Order
    Test.setMock(HttpCalloutMock.class, new RestMockSuccess());
    Test.startTest();
    Map<String, String> response = OrderProductsController.submitOrderRequest(
      orders[0].Id
    );
    Test.StopTest();
    System.assertEquals(
      gSubmitResponseFailure,
      response.get('code'),
      'Submit order response not failure.'
    );
    System.assertEquals(
      gAccountNumberMissingMessage,
      response.get('message'),
      'Submit order response message does not match.'
    );
  }

  @isTest
  static void TestSubmitOrderMissingActiveContract() {
    List<Order> orders = [
      SELECT Id
      FROM Order
      WHERE Account.Name = 'Test Account Draft Contract'
    ];
    System.assertEquals(gNumOrders, orders.size(), 'Order creation failed.');

    // Get eligible products
    List<PricebookEntry> priceBookEntries = OrderableProductsController.listEligibleProducts(
      orders[0].Id,
      gOffset,
      gLimit
    );
    Decimal totalProductPrice = 0;
    System.assertEquals(
      gLimit,
      priceBookEntries.size(),
      'Could not get list of eligble price book entries.'
    );

    // Add products to order
    for (PriceBookEntry priceBookEntry : priceBookEntries) {
      OrderProductsController.addProductToOrder(
        orders[0].Id,
        priceBookEntry.Product2Id,
        priceBookEntry.Id,
        priceBookEntry.UnitPrice
      );
      totalProductPrice = totalProductPrice + priceBookEntry.UnitPrice;
    }

    // Submit Order
    Test.setMock(HttpCalloutMock.class, new RestMockSuccess());
    Test.startTest();
    Map<String, String> response = OrderProductsController.submitOrderRequest(
      orders[0].Id
    );
    Test.StopTest();
    System.assertEquals(
      gSubmitResponseFailure,
      response.get('code'),
      'Submit order response not failure.'
    );
    System.assertEquals(
      gActiveContractMissingMessage,
      response.get('message'),
      'Submit order response message does not match.'
    );
  }
}
