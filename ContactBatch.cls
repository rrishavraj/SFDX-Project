public class ContactBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('select Id, Phone from Contact');
    }

    public void execute(Database.BatchableContext BC, List<Contact> scope){
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Contact con : scope){
            
            con.Phone = '8709026746';
            contactsToUpdate.add(con);
        }
        try {
            update contactsToUpdate;
        } catch (Exception e) {
            System.debug('Error updating contacts: ' + e.getMessage());
            
        }
    }

    public void finish (Database.BatchableContext BC){
        
    }
}
