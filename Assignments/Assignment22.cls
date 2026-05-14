/*
 * ============================================================================
 * Class Name    : OpportunityTriggerHandler
 * Description   : This handler class manages post-update business logic for Opportunity records.
 * Current Functionality:
 * - Detects when an Opportunity stage changes to 'Closed Won'
 * - Collects related Account records
 * - Updates Account Type to 'Customer - Direct'
 * Author         : Harsh
 * ============================================================================
 */

public class OpportunityTriggerHandler {

    // Constants to avoid hardcoded values in logic
    private static final String CLOSED_WON_STAGE = 'Closed Won';
    private static final String CUSTOMER_DIRECT_TYPE = 'Customer - Direct';

    public static void afterUpdate(
        List<Opportunity> newOpportunities,
        Map<Id, Opportunity> oldOpportunityMap
    ) {

        /*
         * Prevent recursive trigger execution.
         * Example:
         * Opportunity update → Account update
         * Account trigger/process may again update Opportunity.
         */
        if (OpportunityTriggerHelper.hasAlreadyExecuted) {
            return;
        }

        OpportunityTriggerHelper.hasAlreadyExecuted = true;

        try {

            // Fetch Account Ids linked with Opportunities
            // that recently moved to Closed Won stage
            Set<Id> accountIdsToProcess = getClosedWonAccountIds(
                newOpportunities,
                oldOpportunityMap
            );

            // No Accounts found → no further processing required
            if (accountIdsToProcess.isEmpty()) {
                return;
            }

            // Update Account Type for eligible Accounts
            updateAccountType(accountIdsToProcess);

        } catch (Exception ex) {

            System.debug(
                'Error occurred in OpportunityTriggerHandler.afterUpdate : '
                + ex.getMessage()
            );

        } finally {

            // Reset recursion guard flag
            OpportunityTriggerHelper.hasAlreadyExecuted = false;
        }
    }

    /**
     * Returns Account Ids where Opportunity stage
     * changed from any stage to Closed Won.
     */
    private static Set<Id> getClosedWonAccountIds(
        List<Opportunity> opportunities,
        Map<Id, Opportunity> oldOpportunityMap ) {

        Set<Id> accountIds = new Set<Id>();

        for (Opportunity currentOpportunity : opportunities) {

            Opportunity oldOpportunity =
                oldOpportunityMap.get(currentOpportunity.Id);

            /*
             * Validate whether Opportunity has moved
             * to Closed Won stage in current transaction.
             */
            Boolean isConvertedToClosedWon =
                currentOpportunity.StageName == CLOSED_WON_STAGE
                && oldOpportunity != null
                && oldOpportunity.StageName != CLOSED_WON_STAGE;

            // Add Account Id only if Account exists
            if (
                isConvertedToClosedWon &&
                currentOpportunity.AccountId != null
            ) {
                accountIds.add(currentOpportunity.AccountId);
            }
        }

        return accountIds;
    }
    /**
     * Updates Account Type to Customer - Direct
     * only when current Account Type is different.
     */
    private static void updateAccountType(Set<Id> accountIds) {

        List<Account> accountsToUpdate = new List<Account>();

        for (Account accountRecord : [
            SELECT Id, Type
            FROM Account
            WHERE Id IN :accountIds
        ]) {

            // Avoid unnecessary DML updates
            if (accountRecord.Type != CUSTOMER_DIRECT_TYPE) {

                accountRecord.Type = CUSTOMER_DIRECT_TYPE;
                accountsToUpdate.add(accountRecord);
            }
        }

        // Perform bulk update only when records exist
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}
