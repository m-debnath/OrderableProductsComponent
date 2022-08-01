@isTest
public class TestDataFactory {
  public static void createProductsAndPrices(Integer numProducts) {
    // Create the Products
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < numProducts; i++) {
      products.add(
        new Product2(
          Name = 'GenWatt Diesel ' + i + '01kW',
          ProductCode = 'GC' + i + '01',
          IsActive = true
        )
      );
    }
    insert products;

    // Get Standard Price Book
    Pricebook2 pricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );

    // Create Price Book Entries
    List<PricebookEntry> pricebookentries = new List<PricebookEntry>();
    for (Integer j = 0; j < numProducts; j++) {
      pricebookentries.add(
        new PricebookEntry(
          Pricebook2Id = pricebook.Id,
          Product2Id = products[j].Id,
          UnitPrice = ((j + 1) * 2),
          IsActive = true
        )
      );
    }
    insert pricebookentries;
  }

  public static void createOrder() {
    // Create the Account
    Account account = new Account(
      Name = 'Test Account',
      AccountNumber = '00001000'
    );
    insert account;

    // Create and Activate the contract
    Contract contract = new Contract(
      AccountId = account.Id,
      ContractTerm = 24,
      Status = 'Draft'
    );
    insert contract;
    contract.Status = 'Activated';
    update contract;

    // Create the Draft Order
    Order order = new Order(
      AccountId = account.Id,
      ContractId = contract.Id,
      Pricebook2Id = Test.getStandardPricebookId(),
      EffectiveDate = Date.Today(),
      Status = 'Draft'
    );
    insert order;
  }
}
