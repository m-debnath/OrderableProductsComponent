import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex'
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import listEligibleProducts from '@salesforce/apex/OrderableProductsController.listEligibleProducts';
import countEligibleProducts from '@salesforce/apex/OrderableProductsController.countEligibleProducts';
import addProductToOrder from '@salesforce/apex/OrderProductsController.addProductToOrder';
import getOrderProductsTotalPrice from '@salesforce/apex/OrderProductsController.getOrderProductsTotalPrice';
import getOrderProductsTotalQuantity from '@salesforce/apex/OrderProductsController.getOrderProductsTotalQuantity';
import listOrderProducts from '@salesforce/apex/OrderProductsController.listOrderProducts';

const columns = [
    { label: 'Product', fieldName: 'Name', hideDefaultActions: true, },
    { label: 'Code', fieldName: 'ProductCode', hideDefaultActions: true, },
    { label: 'Price', fieldName: 'UnitPrice', type: 'currency', hideDefaultActions: true, },
    {
        label: 'Add to Cart',
        type: 'button-icon',
        fixedWidth: 100,
        hideDefaultActions: true,
        typeAttributes: {
            iconName: 'action:new',
            name: 'add_to_cart', 
            value: 'Product2Id',
            title: 'Add to Cart',
            variant: 'brand',
            alternativeText: 'Add',
            disabled: { fieldName: 'disabled' },
        }
    }
];


export default class OrderableProductsListLWC extends NavigationMixin(LightningElement) {
    @api recordId;
    @track error;
    data = [];
    columns = columns;
    sOffset = 0;
    sStep = 5;
    targetDatatable;
    
    @wire(countEligibleProducts, {sOrderId: '$recordId'})
    totalNumberOfRows

    connectedCallback() {
        this.listEligibleProducts();
    }

    @wire(getOrderProductsTotalPrice, {sOrderId: '$recordId'})
    totalPrice

    @wire(getOrderProductsTotalQuantity, {sOrderId: '$recordId'})
    totalQuantity

    @wire(listOrderProducts, {sOrderId: '$recordId'})
    orderProducts

    listEligibleProducts() {
        listEligibleProducts({ sOrderId: this.recordId, sOffset: this.sOffset })
        .then(result => {
            const orders = JSON.parse(JSON.stringify(result.Order));
            result = JSON.parse(JSON.stringify(result.PricebookEntry));
            result = result.map(elem => ({
                ...elem, 
                disabled: orders[0].Status !== 'Draft'
            }));
            this.data = [...this.data, ...result];
            this.error = undefined;
            if (this.targetDatatable && this.data.length >= this.totalNumberOfRows.data) {
                this.targetDatatable.enableInfiniteLoading = false;
            }
            if (this.targetDatatable) this.targetDatatable.isLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.data = undefined;
            if (this.targetDatatable) this.targetDatatable.isLoading = false;
            console.error('Error : ' + JSON.stringify(this.error));
        })
    }

    loadMoreData(event) {
        event.preventDefault();
        this.sOffset = this.sOffset + this.sStep;
        event.target.isLoading = true;
        this.targetDatatable = event.target;
        this.listEligibleProducts();
    }

    addProudctToOrder(event) {
        addProductToOrder({
            sOrderId: this.recordId,
            sProductId: event.detail.row.Product2Id,
            sPricebookEntryId: event.detail.row.Id,
            nUnitPrice: event.detail.row.UnitPrice
        })
        .then(result  => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: event.detail.row.Name + ' added to the order.',
                    variant: 'success'
                })
            );
            const updatedRecords = result.map(rec => {
                return { 'recordId': rec };
            });
            refreshApex(this.totalPrice);
            refreshApex(this.totalQuantity);
            refreshApex(this.orderProducts);
            getRecordNotifyChange(updatedRecords);
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error adding product to the order.',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }
}