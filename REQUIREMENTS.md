# Use Case: Build an order record page consisting of 2 LWC components

1. One which displays available products and
2. One which displays order products from Order

# Acceptance Criteria

1. **Orderable **product will be displayed in a 2-column list displaying **Name and List Price and Add Button** (component 1) **Sort Order? - Assumed Name - Done**
   1. Products are orderable when they have a Pricebook Entry in the Pricebook related to the current order (standard pricebook for this assignment) and when that Pricebook Entry is active
   2. Each product can only appear once in the list - **Deduplication SOQL? - Done**
2. The UI needs to provide the ability for the user to add a product from the list (component 1) to the order - **see column list from 1st point - Done** 3. When the same product is not yet added to the order it will be added with a quantity of 1 4. When the product already exists the quantity of the existing order product be increased by 1
3. All Order Products in the **current **order will be displayed in a table displaying the **Name, Unit Price, Quantity and Total Price and Add Remove buttons** (component 2) **- Done** 5. When the user adds a new product or updates an existing product on the order (see point 2) the list needs to display the newly added
4. A test coverage of at least 80% for both APEX components is required. **- Done** 6. **The use of Aura components is prohibited.**
5. Create a Salesforce Developer login for this assignment and build it as a SFDX project.** - Done**

# Extra Acceptance Criteria

1. The number of products can exceed 200; the solution needs to be able to handle this while providing a proper user experience. - **Pagination - Done**
2. To ensure an optimal user experience the page should not be reloaded and only the changed or new items should be refreshed/added - **Reactive - Done**
3. The end user needs to be able to **Confirm** the order in an external system with the click of a button. **- Done** 1. The request format expected by the external system should follow the following JSON structure: \
   { \
    "accountNumber": "", \
    "orderNumber": "", \
    "type": "order type", \
    "status": "order status", \
    "orderProducts": [{ \
    "name": "product name", \
    "code": "product code", \
    "unitPrice": 10.00, \
    "quantity": 1 \
    }] \
   } **- Done** 2. Request is sent as POST **- Done** 3. Order of the JSON fields in the above JSON structure is not relevant but the data type is. **- Done** 4. Errors and time-outs of the external system need to be handled 1. i. All 200 responses are considered OK 2. ii. Any non-200 response is handled as ERROR 5. For this use case generate a new endpoint URL at **https://requestcatcher.com/ \
   Using [https://mco.requestcatcher.com/](https://mco.requestcatcher.com/)**
4. 4. After the order is confirmed successfully in the external system the status of the order and order items will be updated to “Activated” **- Done**
   5. When activated the end user will not be able to add new order items or confirm the order for a second time. - **Validation Order Status - Done**
5. A test coverage of at least 80% for both LWC components is required.** - Done**

Once you build this, create a private repository on GitHub, check in all the components and share the repository path & login details with us.
