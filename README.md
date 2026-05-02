# Junior Salesforce Engineer Case Study - Bonial

## Overview
This project implements an automated tracking system for **Projects** linked to **Accounts**. It ensures data integrity through Apex triggers and provides a modern UI using Lightning Web Components (LWC).

## Key Features
*   **Automation:** Apex Trigger/Handler to maintain a roll-up count of Projects on the Parent Account (`Total_Projects__c`).
*   **Data Integrity:** Bulk-safe logic that handles project creation, deletion, and account re-parenting.
*   **Custom UI:** A Lightning Web Component that displays related projects with:
    *   Client-side filtering (Show only 'Active' projects).
    *   Pagination for large data sets.
    *   Dynamic total project badges.
*   **Testing:** 100% unit test coverage ensuring robust logic across edge cases.

## Technical Stack
*   **Apex:** Trigger Framework, Aggregate SOQL, Test Classes.
*   **LWC:** Wire Service, Tracked properties, Lightning Datatable.
*   **SOQL:** Optimized queries with limits for performance.

*   ## File Structure & Brief Explanation

### Backend (Apex & Triggers)
*   **ProjectTrigger.trigger**: The entry point for automation. It listens for Insert, Update, Delete, and Undelete events on Projects.
*   **ProjectTriggerHandler.cls**: The "Brain" of the automation. It contains the logic to calculate the number of projects per Account using Aggregate SOQL.
*   **ProjectController.cls**: The API for the LWC. It fetches Account details and related Project records efficiently in a single server call.
*   **ProjectTriggerTest.cls & ProjectControllerTest.cls**: Comprehensive test suites that simulate bulk data (200+ records) and edge cases like record re-parenting.

### Frontend (LWC)
*   **`projectList.html`**: The UI template using `lightning-datatable` and `lightning-button` for a clean user experience.
*   **`projectList.js`**: The logic layer that handles pagination, toggling the "Active" status filter, and wiring data from Apex.
