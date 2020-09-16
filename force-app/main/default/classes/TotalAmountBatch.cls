global class TotalAmountBatch implements 
    Database.Batchable<sObject>, Database.Stateful {
    
    global Integer amount = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Total_Amount__c, ParentId, '+
        '(SELECT Amount, StageName FROM Opportunities WHERE StageName = \'Closed Won\') FROM Account');
    }

    List<Account> searchLinks (Id parent, List<Account> scope){
        List<Account> childAccs = new List<Account>();
        for (Account acc : scope) {
            if (acc.parentId == parent) {
                childAccs.add(acc);
            }
        }
        return childAccs;
    }

    global void execute(Database.BatchableContext bc, List<Account> scope){
        // process each batch of records
        List<Opportunity> opps = new List<Opportunity>();
        for (Account account : scope) {
            //if (account)
          
        }
        
    }    
    global void finish(Database.BatchableContext bc){
        
        // call some utility to send email
    }    
}