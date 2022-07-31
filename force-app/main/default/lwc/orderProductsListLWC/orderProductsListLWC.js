import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex'
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import {loadStyle} from 'lightning/platformResourceLoader'
import customStyles from '@salesforce/resourceUrl/appCustom'
import getOrderProductsTotalPrice from '@salesforce/apex/OrderProductsController.getOrderProductsTotalPrice';
import getOrderProductsTotalQuantity from '@salesforce/apex/OrderProductsController.getOrderProductsTotalQuantity';
import listOrderProducts from '@salesforce/apex/OrderProductsController.listOrderProducts';
import getOrderStatus from '@salesforce/apex/OrderProductsController.getOrderStatus';
import addProductToOrder from '@salesforce/apex/OrderProductsController.addProductToOrder';
import deleteProductFromOrder from '@salesforce/apex/OrderProductsController.deleteProductFromOrder';
import submitOrderRequest from '@salesforce/apex/OrderProductsController.submitOrderRequest';
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import PRODUCTS_TO_CART_CHANNEL from '@salesforce/messageChannel/AvailableProductsToCart__c';
import CART_TO_PRODUCTS_CHANNEL from '@salesforce/messageChannel/CartsToAvailableProducts__c';

// Datatable column definiton
const columns = [
    { 
        label: 'Product', 
        fieldName: 'Name', 
        initialWidth: 200, 
        hideDefaultActions: true, 
    },
    {
        type: 'button-icon',
        fixedWidth: 32,
        typeAttributes: {
            iconName: 'action:delete',
            name: 'remove_from_order', 
            value: 'Id',
            title: '',
            variant: 'brand-outline',
            alternativeText: 'Remove',
            disabled: { fieldName: 'disabled' },
        }
    },
    { 
        label: 'Quantity', 
        fieldName: 'Quantity', 
        hideDefaultActions: true, 
        cellAttributes: { alignment: 'center', }, 
    },
    {
        type: 'button-icon',
        fixedWidth: 32,
        typeAttributes: {
            iconName: 'action:new',
            name: 'add_to_order', 
            value: 'Id',
            title: '',
            variant: 'brand-outline',
            alternativeText: 'Add',
            disabled: { fieldName: 'disabled' },
        }
    },
    { 
        label: 'Unit Price', 
        fieldName: 'UnitPrice', 
        type: 'currency', 
        hideDefaultActions: true, 
    },
    { 
        label: 'Subtotal',
        fieldName: 'TotalPrice',
        type: 'currency',
        hideDefaultActions: true,
        cellAttributes: {
            class: { fieldName: 'CSSClass' }
        },
    },
];

export default class OrderProductsListLWC extends LightningElement {
    @api recordId;
    @track error;
    columns = columns;
    @track orderProducts;
    @track draftStatus = false;  // To enable Confirm button
    @track activeStatus = false;  // To enable Complete button
    _orderProductsRaw;
    _orderStatusRaw;
    isCssLoaded = false
    @track clickedButtonLabel;
    @track isLoading = false;
    @track isNotEmpty = false;
    @track totalQuantity;

    // Load static CSS appCustom.css
    renderedCallback(){ 
        if (this.isCssLoaded) return;
        this.isCssLoaded = true;
        loadStyle(this, customStyles);
    }

    @wire(MessageContext)
    messageContext;

    // Get Order Status
    @wire(getOrderStatus, {sOrderId: '$recordId'})
    getOrderStatus(wireResult) {
        this._orderStatusRaw = wireResult;
        const { data, error } = wireResult;
        if (data) {
            this.draftStatus = data === "Draft";
            this.activeStatus = data === "Activated";
            this.error = undefined;
        } else {
            this.error = error;
        }
    }

    // Get Total Order Price
    @wire(getOrderProductsTotalPrice, {sOrderId: '$recordId'})
    totalPrice

    // Get Order Item Total Quantity
    @wire(getOrderProductsTotalQuantity, {sOrderId: '$recordId'})
    getOrderProductsTotalQuantity(wireResult) {
        this.totalQuantity = wireResult;
        const { data, error } = wireResult;
        if (data) {
            this.isNotEmpty = data > 0;
        } else {
            this.isNotEmpty = false;
            this.error = error;
            console.error('Error : ' + JSON.stringify(this.error));
        }
    }

    // Get Order Proucts
    @wire(listOrderProducts, {sOrderId: '$recordId'})
    listOrderProducts(wireResult) {
        const { data, error } = wireResult;
        this._orderProductsRaw = wireResult; // Cache original return value
        if (data) {
            this.orderProducts = data.map(elem => ({
                ...elem, 
                Name: elem.Product2.Name, // Flatten Product Name
                CSSClass: "total-padding-right",  // Adjust for datatable scrollbar for rows more than total height
                disabled: elem.Order.Status !== 'Draft'  // Add, Remove buttons disabled
            }));
            this.error = undefined;
        } else {
            this.orderProducts = undefined;
            this.error = error;
            console.error('Error : ' + JSON.stringify(this.error));
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            PRODUCTS_TO_CART_CHANNEL,
            (message) => this.handleMessage(message)
        );
    }

    handleMessage(message) {
        if (message.code === 'REFRESH_CACHE') {
            refreshApex(this.totalPrice);
            refreshApex(this.totalQuantity);
            refreshApex(this._orderProductsRaw);
        }
    }

    // Actions
    handleRowAction(event) {
        const action = event.detail.action;
        switch (action.name) {
            case 'add_to_order':
                addProductToOrder({
                    sOrderId: this.recordId,
                    sProductId: event.detail.row.Product2Id,
                    sPricebookEntryId: event.detail.row.PricebookEntryId,
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
                    // Refresh Cache
                    const updatedOrders = result.map(rec => {
                        return { 'recordId': rec };
                    });
                    const updatedOrderProducts = [event.detail.row.Id];
                    getRecordNotifyChange(updatedOrders);
                    getRecordNotifyChange(updatedOrderProducts);
                    refreshApex(this.totalPrice);
                    refreshApex(this.totalQuantity);
                    refreshApex(this._orderProductsRaw);
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
            case 'remove_from_order':
                if (event.detail.row.Quantity > 1) {  // No confirmation before removing order products
                    deleteProductFromOrder({
                        sOrderId: this.recordId,
                        sOrderItemId: event.detail.row.Id
                    })
                    .then(result_inner  => {
                        // Refresh Cache
                        const updatedOrders = result_inner.map(rec => {
                            return { 'recordId': rec };
                        });
                        const updatedOrderProducts = [event.detail.row.Id];
                        getRecordNotifyChange(updatedOrders);
                        getRecordNotifyChange(updatedOrderProducts);
                        refreshApex(this.totalPrice);
                        refreshApex(this.totalQuantity);
                        refreshApex(this._orderProductsRaw);
                    })
                    .catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting product from the order.',
                                message: error.body.message,
                                variant: 'error'
                            })
                        );
                    });
                } else {  // Confirmation before removing last of each order products
                    LightningConfirm.open({
                        message: 'Are you sure you want to delete the last "' +  event.detail.row.Name + '" product from the order?',
                        variant: 'header',
                        label: 'Delete Order Product',
                    })
                    .then(result  => {
                        if (result) {
                            deleteProductFromOrder({
                                sOrderId: this.recordId,
                                sOrderItemId: event.detail.row.Id
                            })
                            .then(result_inner  => {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Success',
                                        message: 'Order product "' + event.detail.row.Name + '" was deleted.',
                                        variant: 'success'
                                    })
                                );
                                // Refresh Cache
                                const updatedOrders = result_inner.map(rec => {
                                    return { 'recordId': rec };
                                });
                                const updatedOrderProducts = [event.detail.row.Id];
                                getRecordNotifyChange(updatedOrders);
                                getRecordNotifyChange(updatedOrderProducts);
                                const payload = { 
                                    code: 'REFRESH_CACHE',
                                    message: 'Refresh Cache'
                                };
                                publish(this.messageContext, CART_TO_PRODUCTS_CHANNEL, payload);
                                refreshApex(this.totalPrice);
                                refreshApex(this.totalQuantity);
                                refreshApex(this._orderProductsRaw);
                            })
                            .catch(error => {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error deleting product from the order.',
                                        message: error.body.message,
                                        variant: 'error'
                                    })
                                );
                            });
                        }
                    })
                    .catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting product from the order.',
                                message: error.body.message,
                                variant: 'error'
                            })
                        );
                    });
                }
                break;
            default:
                break;
        }
    }

    handleClick(event) {
        this.clickedButtonLabel = event.target.label;
        switch (this.clickedButtonLabel) {
            case 'Confirm':
                this.isLoading = true;
                submitOrderRequest({sOrderId: this.recordId})
                .then(result => {
                    if (result.code) {
                        if (result.code === '200') {
                            // Refresh cache
                            getRecordNotifyChange([{recordId: this.recordId}]);
                            const payload = { 
                                code: 'REFRESH_CACHE',
                                message: 'Refresh Cache'
                            };
                            publish(this.messageContext, CART_TO_PRODUCTS_CHANNEL, payload);
                            refreshApex(this._orderStatusRaw);
                            refreshApex(this._orderProductsRaw);
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Order was activated successfully.',
                                    variant: 'success'
                                })
                            );
                        } else {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error activating order.',
                                    message: result.message,
                                    variant: 'error'
                                })
                            );
                        }
                    }
                    this.isLoading = false;
                })
                .catch(error => {
                    this.error = error;
                    console.error(error);
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error activating order.',
                            message: error.message,
                            variant: 'error'
                        })
                    );
                })
                break;
            default:
                break;
        }
    }
}