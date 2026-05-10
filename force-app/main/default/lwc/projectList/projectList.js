import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getProjectData from '@salesforce/apex/ProjectController.getProjectData';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { 
        label: 'Project Name', 
        fieldName: 'projectUrl', 
        type: 'url', 
        typeAttributes: { 
            label: { fieldName: 'Name' }, 
            target: '_self' 
        } 
    },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Budget', fieldName: 'Budget__c', type: 'currency' }
];

export default class ProjectList extends NavigationMixin(LightningElement) {
    @api recordId;
    @track allProjects = [];
    accountTotalProjects = 0;
    
    // Track current filter status
    statusFilter = 'All';
    isToggleActive = false;

    pageNumber = 1;
    pageSize = 5;
    columns = COLUMNS;
    wiredResult;

    // Dropdown options
    get statusOptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Active', value: 'Active' },
            { label: 'Planned', value: 'Planned' },
            { label: 'Completed', value: 'Completed' }
        ];
    }

    // Updated wire to react to statusFilter changes
    @wire(getProjectData, { accountId: '$recordId', statusFilter: '$statusFilter' })
    wiredData(result) {
        this.wiredResult = result;
        if (result.data) {
            this.allProjects = result.data.projects.map(record => {
                return {
                    ...record,
                    projectUrl: `/lightning/r/Project__c/${record.Id}/view`
                };
            });
            this.accountTotalProjects = result.data.totalProjects;
        }
    }

    // Logic for UI display
    get displayedProjects() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = this.pageNumber * this.pageSize;
        return this.allProjects.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.allProjects.length / this.pageSize) || 1;
    }

    get hasProjects() { return this.allProjects.length > 0; }
    get isFirstPage() { return this.pageNumber === 1; }
    get isLastPage() { return this.pageNumber >= this.totalPages; }

    // Handler for Dropdown Filter
    handleStatusChange(event) {
        this.statusFilter = event.detail.value;
        // Sync toggle state: if user selects 'Active' in dropdown, turn toggle on. Otherwise off.
        this.isToggleActive = (this.statusFilter === 'Active');
        this.pageNumber = 1;
    }

    // Handler for Toggle Filter
    handleToggleChange(event) {
        this.isToggleActive = event.target.checked;
        this.statusFilter = this.isToggleActive ? 'Active' : 'All';
        this.pageNumber = 1;
    }

    handleNext() { if (this.pageNumber < this.totalPages) this.pageNumber++; }
    handlePrevious() { if (this.pageNumber > 1) this.pageNumber--; }

    @api refresh() { return refreshApex(this.wiredResult); }
}