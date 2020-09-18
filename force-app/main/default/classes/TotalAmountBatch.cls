global class TotalAmountBatch implements 
    Database.Batchable<sObject>, Database.Stateful {
    
    global Integer amount = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Total_Amount__c, ParentId, '+
        '(SELECT Amount, StageName FROM Opportunities WHERE StageName = \'Closed Won\') FROM Account');
    }
    //
    // !!!!! НЕ ЗАБЫТЬ ОБНУЛИТЬ tA
    //

    List<Account> searchLinks (Id parent, List<Account> scope){
        List<Account> childAccs = new List<Account>();
        for (Account acc : scope) {
            if (acc.parentId == parent) {
                childAccs.add(acc);
            }
        }
        return childAccs;
    }

    Account searchById (Id accId, List<Account> scope) {
        for (Account acc : scope) {
            if (acc.Id == accId) {
                return acc;
            }
        }
    }

    // поиск элементов на которые никто не ссылается
    // метод вовращает лист элементов на которые нету ссылок

    List<Account> leafElements (List <Account> scope) {
        List<Account> leafs = new List<Account> ();
        leafs.addAll(scope);
        for (Account acc : scope) {
            if (acc.ParentId != null) {
                Account rem = new Account();
                for (Account accS : scope) {
                    if (accS.Id == acc.ParentId) {
                        leafs.remove(accS);
                    }
                }
            }
        }
        System.debug(' ----   ' + leafs);
    }

//account.Total_Amount__c

    global void execute(Database.BatchableContext bc, List<Account> scope){
        // process each batch of records
        Decimal tA = 0;
        Decimal sum = 0;
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> leafAccs = new List<Account>();
        List<Account> fiveAccs = new List<Account>();
        //получаем лист нижних элементов
        leafAccs = leafElements(scope);
        // считаем для них total amount
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
        
        //выделяем в отдельный лист элементы на которые ссылаются нижние
        Account tmp = Account();
        for (Account ac : leafAccs) {
            if (ac.ParentId != null) {
                // считаем для акка с id == parentId totalAmount в который заплюсовываем ac.totalAmount

                tmp = searchById(ac.ParentId);
                tmp.Total_Amount__c += ac.Total_Amount__c;
                
                fiveAccs.add(tmp)

            }
            //fiveAccs.addAll(searchLinks(ac.Id));
            //в fiveAccs 
        }
        //считаем оппсы для полученного листа аккаунтов предпоследнего уровня
        for (Account ac : fiveAccs) {
            for (Opportunity op : ac.Opportunities) {
                // в уже имеющие значения
                ac.Total_Amont__c += op.Amount;
            }
        }
        

        for (Account account : scope) {
            if (account.ParentId != null) {
                //сюда пишем то, что делать если это не вершина
            } else {
                //обнуляем сумму для этой вершины
                sum = 0;
                //сюда, если вершина. Ищем ссылки на вершину
                for (Account ac :  searchLinks(account.Id, scope)) {
                    sum = 0;
                    //смотрим каждый ссылающийся на наш акк другой акк
                    //для каждого акка берем список его оппсов и суммируем их эмаунты
                    for (Opportunity opp : ac.Opportunities) {
                        sum += opp.Amount;
                    }
                    ac.Total_Amount__c += sum;
                    
                    //для каждого из акков также ищем, есть ли у него родитель
                    if (ac.ParentId != null) {
                        
                    }



                    sum += ac.Total_Amount__c;
                    //opportunities .amount sum
                }
            }
          
        }
        
    }    
    global void finish(Database.BatchableContext bc){
        
        // call some utility to send email
    }    
}