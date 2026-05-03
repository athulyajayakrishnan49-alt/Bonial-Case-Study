import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'; // 1. REQUIRED for navigation
import getProjectData from '@salesforce/apex/ProjectController.getProjectData';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { 
        label: 'Project Name', 
        fieldName: 'projectUrl', // This matches the property we create in wiredData
        type: 'url', 
        typeAttributes: { 
            label: { fieldName: 'Name' }, // This keeps the clickable text as the Project Name
            target: '_self' // Opens in the same tab, use '_blank' for new tab
        } 
    },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Budget', fieldName: 'Budget__c', type: 'currency' }
];

export default class ProjectList extends NavigationMixin(LightningElement) {
    @api recordId;
    allProjects = [];
    accountTotalProjects = 0;
    showOnlyActive = false;
    pageNumber = 1;
    pageSize = 5;
    columns = COLUMNS;
    wiredResult;

    @wire(getProjectData, { accountId: '$recordId' })
    wiredData(result) {
        this.wiredResult = result;
        if (result.data) {
            // massaging the data to add the URL property for each row
            this.allProjects = result.data.projects.map(record => {
                return {
                    ...record,
                    projectUrl: `/lightning/r/Project__c/${record.Id}/view`
                };
            });
            this.accountTotalProjects = result.data.totalProjects;
        }
    }

    
    get filteredProjects() {
        return this.showOnlyActive 
            ? this.allProjects.filter(p => p.Status__c === 'Active') 
            : this.allProjects;
    }

    get displayedProjects() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = this.pageNumber * this.pageSize;
        return this.filteredProjects.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.filteredProjects.length / this.pageSize) || 1;
    }

    get hasProjects() { return this.filteredProjects.length > 0; }
    get isFirstPage() { return this.pageNumber === 1; }
    get isLastPage() { return this.pageNumber >= this.totalPages; }

    handleToggleChange(event) {
        this.showOnlyActive = event.target.checked;
        this.pageNumber = 1;
    }

    handleNext() { if (this.pageNumber < this.totalPages) this.pageNumber++; }
    handlePrevious() { if (this.pageNumber > 1) this.pageNumber--; }

    @api refresh() { return refreshApex(this.wiredResult); }
}