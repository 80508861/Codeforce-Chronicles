public class OpportunityTriggerHandler {
    public static void afterUpdate(List<Opportunity> oppList,Map<Id,Opportunity>oldMap){
        try{
        if(OpportunityTriggerHelper.isFirstRun){
            return;
        }
        OpportunityTriggerHelper.isFirstRun=true;
        Set<id> accountIds=new Set<Id>();
        for(Opportunity opp:oppList){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.StageName == 'Closed Won' &&
                oldOpp != null &&
                oldOpp.StageName != 'Closed Won' &&
                opp.AccountId != null) {
                    
                    accountIds.add(opp.AccountId);
                }
        }
        if(accountIds.isEmpty()){
            return;
        }
        
        List<Account> accList=[SELECT Type FROM Account WHERE Id IN:accountIds];
        List<Account> accToUpdate=new List<Account>();
        for(Account acc:accList){
            if(acc.Type!='Customer - Direct'){
                acc.Type='Customer - Direct';
                accToUpdate.add(acc);
            }
        }
        if(!accToUpdate.isEmpty()){
            update accToUpdate; 
        }
        } finally{
            OpportunityTriggerHelper.isFirstRun=false;
        }
    }
}
