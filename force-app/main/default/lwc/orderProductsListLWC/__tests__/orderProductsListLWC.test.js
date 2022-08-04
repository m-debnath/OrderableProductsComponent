import { createElement } from 'lwc';
import LightningConfirm from 'lightning/confirm';

import OrderProductsListLWC from 'c/orderProductsListLWC';
import getOrderStatus from '@salesforce/apex/OrderProductsController.getOrderStatus';
import getOrderProductsTotalPrice from '@salesforce/apex/OrderProductsController.getOrderProductsTotalPrice';
import getOrderProductsTotalQuantity from '@salesforce/apex/OrderProductsController.getOrderProductsTotalQuantity';
import listOrderProducts from '@salesforce/apex/OrderProductsController.listOrderProducts';
import addProductToOrder from '@salesforce/apex/OrderProductsController.addProductToOrder';
import deleteProductFromOrder from '@salesforce/apex/OrderProductsController.deleteProductFromOrder';
import submitOrderRequest from '@salesforce/apex/OrderProductsController.submitOrderRequest';

jest.mock('lightning/confirm');

jest.mock(
    '@salesforce/apex/OrderProductsController.getOrderStatus',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/OrderProductsController.getOrderProductsTotalPrice',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/OrderProductsController.getOrderProductsTotalQuantity',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/OrderProductsController.listOrderProducts',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/OrderProductsController.addProductToOrder',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/OrderProductsController.deleteProductFromOrder',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/OrderProductsController.submitOrderRequest',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

const ShowToastEventName = 'lightning__showtoast';

const draftStatus = 'Draft';
const mockGetOrderStatus = draftStatus;
const mockListOrderProducts = require('./data/listOrderProducts.json');
let mockTotalOrderPrice = 0;
let mockTotalOrderQuantity = 0;
mockListOrderProducts.forEach(elem => {
    mockTotalOrderPrice = mockTotalOrderPrice + (elem.Quantity * elem.TotalPrice);
    mockTotalOrderQuantity = mockTotalOrderQuantity + elem.Quantity;
});
const dataTableColumnCount = 6;
const mockAddProductToOrderResponse = require('./data/addProductToOrder.json');
const mockDeleteProductFromOrder = require('./data/addProductToOrder.json');
const mockSubmitOrderResponse = require('./data/submitOrderResponse.json');
const mockSubmitOrderResponseFailed = require('./data/submitOrderResponseFailed.json');


describe('c-order-products-list-lwc', () => {
    beforeEach(async () => {
        addProductToOrder.mockResolvedValue(mockAddProductToOrderResponse);
        deleteProductFromOrder.mockResolvedValue(mockDeleteProductFromOrder);
        submitOrderRequest.mockResolvedValue(mockSubmitOrderResponse);
        LightningConfirm.open = jest.fn().mockResolvedValue(true);

        const element = createElement('c-order-products-list-lwc', {
            is: OrderProductsListLWC
        });

        document.body.appendChild(element);

        getOrderStatus.emit(mockGetOrderStatus);
        getOrderProductsTotalPrice.emit(mockTotalOrderPrice);
        listOrderProducts.emit(mockListOrderProducts);
        getOrderProductsTotalQuantity.emit(mockTotalOrderQuantity);

        await flushPromises();
    });
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return Promise.resolve();
    }

    it('displays the greeting text correctly', () => {
        const element = document.body.querySelector('c-order-products-list-lwc');
        
        const greetingText = element.shadowRoot.querySelector('p.greeting-text');
        expect(greetingText.textContent).toBe('Please click the confirm button to activate the order.');
    });

    it('displays the totals in footer correctly', () => {
        const element = document.body.querySelector('c-order-products-list-lwc');
        
        const footerSubject = element.shadowRoot.querySelector('div.footer-subject');
        const footerQuantity = element.shadowRoot.querySelector('div.footer-quantity');
        const footerPrice = element.shadowRoot.querySelector('lightning-formatted-number.footer-price');
        expect(footerSubject.textContent).toBe('Total');
        expect(footerQuantity.textContent).toBe(mockTotalOrderQuantity.toString());
        expect(footerPrice.value).toBe(mockTotalOrderPrice);
    });

    it('enables the confirm button when data is present', async () => {
        const element = document.body.querySelector('c-order-products-list-lwc');

        const addButton = element.shadowRoot.querySelector('lightning-button.confirm-order-button');
        expect(addButton.disabled).toBe(false);
    });

    it('displays the data table properly', async () => {
        const element = document.body.querySelector('c-order-products-list-lwc');

        const dataTable = element.shadowRoot.querySelector('lightning-datatable.order-products-table');
        dataTable.dispatchEvent(new CustomEvent('loadmore'));
        expect(dataTable.columns.length).toBe(dataTableColumnCount);
        expect(dataTable.data.length).toBe(mockListOrderProducts.length);
        for (let i = 0; i < mockListOrderProducts.length; i++) {
            expect(dataTable.data[i].Id).toBe(mockListOrderProducts[i].Id);
        }
        expect(dataTable.maxRowSelection).toBe("1");
        expect(dataTable.hideCheckboxColumn).toBe("true");
    });

    it('adds a product to order', async () => {
        const element = document.body.querySelector('c-order-products-list-lwc');

        const dataTable = element.shadowRoot.querySelector('lightning-datatable.order-products-table');
        const showToastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, showToastHandler);
        dataTable.dispatchEvent(new CustomEvent('rowaction',{
            "detail": {
                "action": {"name": "add_to_order"},
                "row": mockListOrderProducts[0]
            }
        }));
        await flushPromises();
        expect(showToastHandler).toHaveBeenCalled();
    });

    it('adds and deletes product in order', async () => {
        const element = document.body.querySelector('c-order-products-list-lwc');

        const dataTable = element.shadowRoot.querySelector('lightning-datatable.order-products-table');
        const showToastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, showToastHandler);

        // Adds one product and expects success toast message
        dataTable.dispatchEvent(new CustomEvent('rowaction',{
            "detail": {
                "action": {"name": "add_to_order"},
                "row": mockListOrderProducts[0]
            }
        }));
        await flushPromises();
        expect(showToastHandler).toBeCalledTimes(1);

        // Adds one product and expects success toast message
        dataTable.dispatchEvent(new CustomEvent('rowaction',{
            "detail": {
                "action": {"name": "add_to_order"},
                "row": mockListOrderProducts[0]
            }
        }));
        await flushPromises();
        expect(showToastHandler).toBeCalledTimes(2);

        // Deletes one product from more than 1 and does not expect success toast message
        dataTable.dispatchEvent(new CustomEvent('rowaction',{
            "detail": {
                "action": {"name": "remove_from_order"},
                "row": mockListOrderProducts[0]
            }
        }));
        await flushPromises();
        expect(showToastHandler).toBeCalledTimes(2);

        // Deletes one product from just 1 and expects confirm dialog and success toast message
        dataTable.dispatchEvent(new CustomEvent('rowaction',{
            "detail": {
                "action": {"name": "remove_from_order"},
                "row": mockListOrderProducts[1]
            }
        }));
        await flushPromises();
        expect(LightningConfirm.open.mock.calls).toHaveLength(1);
        expect(showToastHandler).toBeCalledTimes(3);
    });

    it('submits the order', async () => {
        const element = document.body.querySelector('c-order-products-list-lwc');

        const confirmButton = element.shadowRoot.querySelector('lightning-button.confirm-order-button');
        const showToastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, showToastHandler);
        confirmButton.click();
        await flushPromises();
        expect(showToastHandler).toHaveBeenCalled();
    });

    it('submits the order expects failure response', async () => {
        const element = document.body.querySelector('c-order-products-list-lwc');
        submitOrderRequest.mockResolvedValue(mockSubmitOrderResponseFailed);

        const confirmButton = element.shadowRoot.querySelector('lightning-button.confirm-order-button');
        const showToastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, showToastHandler);
        confirmButton.click();
        await flushPromises();
        expect(showToastHandler).toHaveBeenCalled();
    });
});