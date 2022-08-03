import { createElement } from 'lwc';

import OrderableProductsListLWC from 'c/orderableProductsListLWC';
import getOrderStatus from '@salesforce/apex/OrderProductsController.getOrderStatus';
import addProductToOrder from '@salesforce/apex/OrderProductsController.addProductToOrder';
import listEligibleProducts from '@salesforce/apex/OrderableProductsController.listEligibleProducts';
import countEligibleProducts from '@salesforce/apex/OrderableProductsController.countEligibleProducts';

import { subscribe, MessageContext, publish } from 'lightning/messageService';
import CART_TO_PRODUCTS_CHANNEL from '@salesforce/messageChannel/CartsToAvailableProducts__c';

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
    '@salesforce/apex/OrderableProductsController.listEligibleProducts',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/OrderableProductsController.countEligibleProducts',
    () => {
        return {
            default: jest.fn()
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

const ShowToastEventName = 'lightning__showtoast';

const draftStatus = 'Draft';
const dataTableColumnCount = 3;
const mockGetOrderStatus = draftStatus;
const mockListEligibleProducts = require('./data/listEligibleProducts.json');
const mockListEligibleProductsWithCss = mockListEligibleProducts.map(elem => ({
    ...elem, 
    CSSClass: "total-padding-right"
}));
const mockCountEligibleProducts = mockListEligibleProducts.length;
const mockAddProductToOrderResponse = require('./data/addProductToOrder.json');

describe('c-orderable-products-list-lwc', () => {
    beforeEach(async () => {
        countEligibleProducts.mockResolvedValue(mockCountEligibleProducts);
        listEligibleProducts.mockResolvedValue(mockListEligibleProducts);
        addProductToOrder.mockResolvedValue(mockAddProductToOrderResponse);

        const element = createElement('c-orderable-products-list-lwc', {
            is: OrderableProductsListLWC
        });

        document.body.appendChild(element);

        getOrderStatus.emit(mockGetOrderStatus);

        await flushPromises();
    });
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return Promise.resolve();
    }

    it('displays the greeting text correctly', async () => {
        const element = document.body.querySelector('c-orderable-products-list-lwc');

        const greetingText = element.shadowRoot.querySelector('p.greeting-text');
        expect(greetingText.textContent).toBe('Please select a product and click "Add to Cart" button to proceed.');
    });
    
    it('displays the footer count correctly', async () => {
        const element = document.body.querySelector('c-orderable-products-list-lwc');

        const footerTitle = element.shadowRoot.querySelector('div.footer-text');
        expect(footerTitle.textContent).toBe(`Loaded ${mockListEligibleProducts.length} of ${mockListEligibleProducts.length} products.`);
    });
       
    it('disables the add button on initial load', async () => {
        const element = document.body.querySelector('c-orderable-products-list-lwc');

        const addButton = element.shadowRoot.querySelector('lightning-button.add-to-cart-button');
        expect(addButton.disabled).toBe(true);
    });

    it('displays the data table properly', async () => {
        const element = document.body.querySelector('c-orderable-products-list-lwc');

        const dataTable = element.shadowRoot.querySelector('lightning-datatable.eligible-products-table');
        dataTable.dispatchEvent(new CustomEvent('loadmore'));
        expect(dataTable.columns.length).toBe(dataTableColumnCount);
        expect(dataTable.data.length).toBe(mockListEligibleProducts.length);
        expect(JSON.stringify(dataTable.data)).toBe(JSON.stringify(mockListEligibleProductsWithCss));
        expect(dataTable.maxRowSelection).toBe("1");
    });

    it('enables the add button after selecting product', async () => {
        const element = document.body.querySelector('c-orderable-products-list-lwc');

        const dataTable = element.shadowRoot.querySelector('lightning-datatable.eligible-products-table');
        dataTable.dispatchEvent(new CustomEvent('rowselection',{
            "detail": {
                "selectedRows": mockListEligibleProductsWithCss.slice(0, 1)
            }
        }));

        await flushPromises();

        const addButton = element.shadowRoot.querySelector('lightning-button.add-to-cart-button');
        expect(addButton.disabled).toBe(false);
    });

    it('adds a product to order', async () => {
        const element = document.body.querySelector('c-orderable-products-list-lwc');

        const dataTable = element.shadowRoot.querySelector('lightning-datatable.eligible-products-table');
        dataTable.dispatchEvent(new CustomEvent('rowselection',{
            "detail": {
                "selectedRows": mockListEligibleProductsWithCss.slice(0, 1)
            }
        }));
        await flushPromises();
        const showToastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, showToastHandler);
        const addButton = element.shadowRoot.querySelector('lightning-button.add-to-cart-button');
        addButton.click();
        await flushPromises();
        expect(showToastHandler).toHaveBeenCalled();
    });

    it('subscribes to message channel successfully', async () => {
        expect(subscribe).toHaveBeenCalled();
        expect(subscribe.mock.calls[0][1]).toBe(CART_TO_PRODUCTS_CHANNEL);
    });

    it('refreshes cache after message received', async () => {
        const element = document.body.querySelector('c-orderable-products-list-lwc');
        const messagePayload = { 
            code: 'REFRESH_CACHE',
            message: 'Refresh Cache'
        };
        publish(MessageContext, CART_TO_PRODUCTS_CHANNEL, messagePayload);

        await flushPromises();

        const addButton = element.shadowRoot.querySelector('lightning-button.add-to-cart-button');
        expect(addButton.disabled).toBe(true);
    });
});