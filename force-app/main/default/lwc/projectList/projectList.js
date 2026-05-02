import { LightningElement, api, wire, track } from 'lwc';
import getProjectData from '@salesforce/apex/ProjectController.getProjectData';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Project Name', fieldName: 'Name', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Budget', fieldName: 'Budget__c', type: 'currency' }
];

export default class ProjectList extends LightningElement {
    @api recordId;
    @track allProjects = [];
    @track filteredProjects = [];
    @track accountTotalProjects = 0;

    wiredResult;

    columns = COLUMNS;
    showOnlyActive = false;
    @track pageNumber = 1;
    pageSize = 5;

    @wire(getProjectData, { accountId: '$recordId' })
    wiredData(result) {
        this.wiredResult = result;

        if (result.data) {
            this.allProjects = result.data.projects;
            this.accountTotalProjects = result.data.totalProjects;
            this.updateFilter();
        } else if (result.error) {
            console.error(result.error);
        }
    }

    // FIX: Manual refresh support
    refreshData() {
        refreshApex(this.wiredResult);
    }

    get hasProjects() {
        return this.filteredProjects && this.filteredProjects.length > 0;
    }

    // FIX: Improved empty state message logic
    get emptyMessage() {
        if (this.showOnlyActive) {
            return 'No Active Projects found for this Account.';
        }
        return 'No Projects found for this Account.';
    }

    handleToggleChange(event) {
        this.showOnlyActive = event.target.checked;
        this.pageNumber = 1;
        this.updateFilter();
    }

    updateFilter() {
        if (this.showOnlyActive) {
            this.filteredProjects = this.allProjects.filter(
                p => p.Status__c === 'Active'
            );
        } else {
            this.filteredProjects = this.allProjects;
        }
    }

    get displayedProjects() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = this.pageNumber * this.pageSize;
        return this.filteredProjects.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.filteredProjects.length / this.pageSize) || 1;
    }

    get isFirstPage() { return this.pageNumber === 1; }
    get isLastPage() { return this.pageNumber >= this.totalPages; }

    handleNext() { if (!this.isLastPage) this.pageNumber++; }
    handlePrevious() { if (!this.isFirstPage) this.pageNumber--; }
}