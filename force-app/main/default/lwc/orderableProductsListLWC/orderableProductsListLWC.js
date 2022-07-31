import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex'
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import listEligibleProducts from '@salesforce/apex/OrderableProductsController.listEligibleProducts';
import countEligibleProducts from '@salesforce/apex/OrderableProductsController.countEligibleProducts';
import addProductToOrder from '@salesforce/apex/OrderProductsController.addProductToOrder';
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import PRODUCTS_TO_CART_CHANNEL from '@salesforce/messageChannel/AvailableProductsToCart__c';
import CART_TO_PRODUCTS_CHANNEL from '@salesforce/messageChannel/CartsToAvailableProducts__c';
import getOrderStatus from '@salesforce/apex/OrderProductsController.getOrderStatus';

const columns = [
    { label: 'Product', fieldName: 'Name', hideDefaultActions: true, },
    { label: 'Code', fieldName: 'ProductCode', hideDefaultActions: true, },
    { 
        label: 'Price',
        fieldName: 'UnitPrice',
        type: 'currency',
        hideDefaultActions: true,
        cellAttributes: {
            class: { fieldName: 'CSSClass' }
        },
    }
];


export default class OrderableProductsListLWC extends NavigationMixin(LightningElement) {
    @api recordId;
    @track error;
    data = [];
    columns = columns;
    @track nOffset = 0;
    nStep = 5;
    targetDatatable;
    @track draftStatus = false;
    _orderStatusRaw;
    @track noRowSelected = true;
    _selectedProduct;

    @wire(MessageContext)
    messageContext;

    @wire(getOrderStatus, {sOrderId: '$recordId'})
    getOrderStatus(wireResult) {
        this._orderStatusRaw = wireResult;
        const { data, error } = wireResult;
        if (data) {
            this.draftStatus = data === "Draft";
            this.error = undefined;
        } else {
            this.error = error;
        }
    }
    
    @wire(countEligibleProducts, {sOrderId: '$recordId'})
    totalNumberOfRows

    connectedCallback() {
        this.listEligibleProducts();
        this.subscribeToMessageChannel();
    }

    listEligibleProducts() {
        listEligibleProducts({ sOrderId: this.recordId, nOffset: this.nOffset, nLimit: this.nStep })
        .then(result => {
            result = JSON.parse(JSON.stringify(result));
            result = result.map(elem => ({
                ...elem, 
                CSSClass: "total-padding-right"  // Adjust for datatable scrollbar for rows more than total height
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
        this.nOffset = this.nOffset + this.nStep;
        event.target.isLoading = true;
        this.targetDatatable = event.target;
        this.listEligibleProducts();
    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            CART_TO_PRODUCTS_CHANNEL,
            (message) => this.handleMessage(message)
        );
    }

    handleMessage(message) {
        if (message.code === 'REFRESH_CACHE') {
            refreshApex(this._orderStatusRaw);
        }
    }

    getSelectedProduct(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.noRowSelected = false;
            this._selectedProduct = selectedRows[0];
        }
    }

    handleClick(event) {
        this.clickedButtonLabel = event.target.label;
        switch (this.clickedButtonLabel) {
            case 'Add to Cart':
                addProductToOrder({
                    sOrderId: this.recordId,
                    sProductId: this._selectedProduct.Product2Id,
                    sPricebookEntryId: this._selectedProduct.Id,
                    nUnitPrice: this._selectedProduct.UnitPrice
                })
                .then(result  => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: this._selectedProduct.Name + ' added to the order.',
                            variant: 'success'
                        })
                    );
                    const updatedRecords = result.map(rec => {
                        return { 'recordId': rec };
                    });
                    const payload = { 
                        code: 'REFRESH_CACHE',
                        message: 'Refresh Cache'
                    };
                    // Refresh cache in Carts component
                    publish(this.messageContext, PRODUCTS_TO_CART_CHANNEL, payload);
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
                break;
            default:
                break;
        }
    }
}