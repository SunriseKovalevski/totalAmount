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

            for (Contact contact : account.contacts) {
                contact.MailingStreet = account.BillingStreet;
                contact.MailingCity = account.BillingCity;
                contact.MailingState = account.BillingState;
                contact.MailingPostalCode = account.BillingPostalCode;
                // add contact to list to be updated
                contacts.add(contact);
                // increment the instance member counter
                recordsProcessed = recordsProcessed + 1;
            }
        }
        update contacts;
    }    
    global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed. Shazam!');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
        // call some utility to send email
    }    
}