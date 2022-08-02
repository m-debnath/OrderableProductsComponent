import { createElement } from 'lwc';

import OrderableProductsListLWC from 'c/orderableProductsListLWC';
import getOrderStatus from '@salesforce/apex/OrderProductsController.getOrderStatus';
import listEligibleProducts from '@salesforce/apex/OrderableProductsController.listEligibleProducts';
import countEligibleProducts from '@salesforce/apex/OrderableProductsController.countEligibleProducts';

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

const mockGetOrderStatus = require('./data/getOrderStatus.json');
const mockListEligibleProducts = require('./data/listEligibleProducts.json');
const mockCountEligibleProducts = mockListEligibleProducts.length;

describe('c-orderable-products-list-lwc', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return Promise.resolve();
    }

    it('displays the component', async () => {
        countEligibleProducts.mockResolvedValue(mockCountEligibleProducts);
        listEligibleProducts.mockResolvedValue(mockListEligibleProducts);

        const element = createElement('c-orderable-products-list-lwc', {
            is: OrderableProductsListLWC
        });

        document.body.appendChild(element);

        getOrderStatus.emit(mockGetOrderStatus);

        await flushPromises();

        const greetingText = element.shadowRoot.querySelector('p.greeting-text');
        expect(greetingText.textContent).toBe('Please select a product and click "Add to Cart" button to proceed.');

        // return Promise.resolve().then(() => {
        //     const greetingText = element.shadowRoot.querySelectorAll('p');
        //     expect(greetingText).toBe('Please select a product and click "Add to Cart" button to proceed.');
        // });
    });
});