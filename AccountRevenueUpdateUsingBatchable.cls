global class AccountRevenueUpdateUsingBatchable implements Database.Batchable<sobject> {

    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator('SELECT Id, AnnualRevenue FROM Account');
     }

    global void execute(Database.BatchableContext BC, List<sobject> scope){
        List<Account> accList = (List<Account>) scope;

        for(Account acc : accList){
            
            if(acc.AnnualRevenue == null){
                acc.AnnualRevenue = 90;
            }else{
                acc.AnnualRevenue += 90;
            }
        }

        update accList;

    } 

    global void finish(Database.BatchableContext BC){
        
    }

}