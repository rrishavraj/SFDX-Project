global class UpdateCampaignStatusBatch implements Database.Batchable<sobject>{

    global Database.QueryLocator start(Database.BatchableContext BC){

        string query = 'Select Id, Name, Status from Campaign';
    }

    global void execute(Database.BatchableContext BC, List<Campaign> Campaigns){
        List<Campaign> CampList = new List<Campaign>();

        for(Campaign Camp : Camplist){
            if(Camp.Status != 'completed'){
                Camp.Status == 'Completed';
                CampList.add(Camp);

            }
            update CampList;
        }

    }
    
}