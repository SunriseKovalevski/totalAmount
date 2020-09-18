global class TotalAmountBatch implements 
    Database.Batchable<sObject>, Database.Stateful {
    
    private List<Account> resList = new List<Account>();
    
    global Integer amount = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Total_Amount__c, ParentId, '+
        '(SELECT Amount, StageName FROM Opportunities WHERE StageName = \'Closed Won\') FROM Account');
    }

    private List<Account> searchLinks (Id parent, List<Account> scope){
        List<Account> childAccs = new List<Account>();
        for (Account acc : scope) {
            if (acc.parentId == parent) {
                childAccs.add(acc);
            }
        }
        return childAccs;
    }

    public Account searchAccById (Id accId, List<Account> scope) {
        Account retAcc = new Account();
        for (Account acc : scope) {
            if (acc.Id == accId) {
                retAcc = acc;
            }
        }
        return retAcc;
    }

    // search elements on that nobody have link. return List of elements without links from other accs
    private List<Account> leafElements (List <Account> scope) {
        List<Account> leafs = (List<Account>) scope;
        Integer j = 0;
        for (Account acc : scope) {
            if (acc.ParentId != null) {
                j=0;
                while (j < leafs.size()) {
                    if (leafs.get(j).Id == acc.ParentId) {
                        leafs.remove(j);
                    }
                }
            }
        }
        return leafs;
        
    }

    //function that take low lvl acc list and return acc List higher lvl with calculate Total_Amounts
    public List<Account> upLvlList(List<Account> lowLvlList, List<Account> scope) {
        List<Account> acResList = new List<Account> ();
        Account tmp = new Account();
        for (Account ac : lowLvlList) {
            if (ac.ParentId != null) {
                // calculate for acc with id == parentId totalAmount abd increment with ac.totalAmount
                tmp = searchAccById(ac.ParentId,scope);
                tmp.Total_Amount__c += ac.Total_Amount__c;
                acResList.add(tmp);
            }
        }
        //calculate  ooportunities for the prev lvl acc list 
        for (Account ac : acResList) {
            for (Opportunity op : ac.Opportunities) {
                //in to the existing values
                ac.Total_Amount__c += op.Amount;    
            }
        }
        return acResList;
    }



    global void execute(Database.BatchableContext bc, List<Account> scope){
        // process each batch of records
        Decimal tA = 0;
        Decimal sum = 0;

        List<Account> leafAccs = new List<Account>();
        List<Account> fiveAccs = new List<Account>();
        // zeros into totalAmounts
        for (Account a : scope) {
            a.Total_Amount__c = 0;
        }
        // get List with leafs elements
        leafAccs = leafElements(scope);
        // calculate total amount for him
        for (Account ac : leafAccs) {
            ac.Total_Amount__c = 0;
            for (Opportunity opp : ac.Opportunities) {
                ac.Total_Amount__c += opp.Amount;
          }
          for (Account a : scope) {
              if (a.Id == ac.Id) {
                  a.Total_Amount__c = ac.Total_Amount__c;
              }
          }
        }
        
        // separate into diffrent List elements that at 5 lvl 
        Account tmp = new Account();
        for (Account ac : leafAccs) {
            if (ac.ParentId != null) {
                // calculate for account that have id == parentId totalAmount in that increment ac.totalAmount

                tmp = searchAccById(ac.ParentId, scope);
                tmp.Total_Amount__c += ac.Total_Amount__c;
                
                fiveAccs.add(tmp);

            }

        }
        //calculate opportunities for that account List 5 lvl
        for (Account ac : fiveAccs) {
            for (Opportunity op : ac.Opportunities) {
                //in to the existing values
                ac.Total_Amount__c += op.Amount;
            }
        }

        // here we have calculate accs lowless and prev lvl, similarly  calculate other lvls

        resList.addAll(leafAccs);
        //send to the res collection leaf elements
        List<Account> tmpList = new List<Account>();
        tmpList = upLvlList(leafAccs, scope);
        //tmpList here is a collection with accs from 5 lvl
        // send to res collection
        resList.addAll(tmpList);
        for (Integer i = 0; i < 4; i++) {
            tmpList = upLvlList(tmpList, scope);
            resList.addAll(tmpList); 
        }
        System.debug (' *-*-*-*-*-* ' + resList );
 
        upsert resList; 
        
    }    
    global void finish(Database.BatchableContext bc){
        
        // call some utility to send email

        System.debug(resList.size() + ' records processed. Shazam!');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
       

    }    
}