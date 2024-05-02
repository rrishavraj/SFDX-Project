public class CustomQuoteAggregator extends MktpQuoteAggregatorController {
    public CustomQuoteAggregator() {
    }
    
    public static List<Dimension__c> getQuoteDimensions(List<Id> lstQuoteId){
        List<SBQQ__QuoteLine__c> dimListfromSBQuote = new List<SBQQ__QuoteLine__c>([
            SELECT Id, Internal_SKU_Name__c, SBQQ__Quantity__c, SBQQ__Product__r.Description 
            FROM SBQQ__QuoteLine__c 
            WHERE SBQQ__Quote__c IN :lstQuoteId
        ]);
        
        List<CPQ_Quote_Line_Item__c> dimListfrCallidus = new List<CPQ_Quote_Line_Item__c>([
            SELECT Id, Product_Code__c, Quantity__c, Product__r.Description  
            FROM CPQ_Quote_Line_Item__c 
            WHERE Product__c != null AND CPQ_Quote__c IN :lstQuoteId
        ]);
        	
        List<Dimension__c> dimList = new List<Dimension__c>();
        Integer productCount = 0;
        
        for(SBQQ__QuoteLine__c QL : dimListfromSBQuote){
            Dimension__c dim = new Dimension__c();
            if(QL.SBQQ__Product__r.Description == null || 
               QL.SBQQ__Product__r.Description == '' || 
               (!QL.SBQQ__Product__r.Description.toLowerCase().contains('marketplace fee'))){
                
                if(QL.Internal_SKU_Name__c != null){
                    QL.Internal_SKU_Name__c = QL.Internal_SKU_Name__c.removeStartIgnoreCase('PAN-');
                    
                    dim.Name = (QL.Internal_SKU_Name__c.length() > 22) ? QL.Internal_SKU_Name__c.substring(0, 21) : QL.Internal_SKU_Name__c;
                    dim.Name = dim.Name + productCount;
                    
                    dim.SKU_API_Name__c = QL.Internal_SKU_Name__c.remove('-').deleteWhitespace();
                    dim.SKU_API_Name__c = (dim.SKU_API_Name__c.length() > 14) ? dim.SKU_API_Name__c.substring(0, 13) : dim.SKU_API_Name__c;
                    
                    if(dim.Name.contains('NGFW'))
                        dim.SKU_API_Name__c = 'CloudNGFWCredits';
                    else                  
                        dim.SKU_API_Name__c = dim.SKU_API_Name__c + productCount;
                }
                if(QL.SBQQ__Product__r.Description != null)
                    dim.Description__c = QL.SBQQ__Product__r.Description.abbreviate(69);
                dim.Units__c = QL.SBQQ__Quantity__c;
                dimList.add(dim);
                productCount++;
            }
        }
        
        for(CPQ_Quote_Line_Item__c QL : dimListfrCallidus){
            Dimension__c dim = new Dimension__c();
            if(QL.Product__r.Description == null || 
               QL.Product__r.Description == '' || 
               (!QL.Product__r.Description.toLowerCase().contains('marketplace fee'))){
                if(QL.Product_Code__c != null){
                    QL.Product_Code__c = QL.Product_Code__c.removeStartIgnoreCase('PAN-');
                    
                    dim.Name = (QL.Product_Code__c.length() > 22) ? QL.Product_Code__c.substring(0, 21) : QL.Product_Code__c;
                    dim.Name = dim.Name + productCount;
                    
                    dim.SKU_API_Name__c = QL.Product_Code__c.remove('-').deleteWhitespace();
                    dim.SKU_API_Name__c = (dim.SKU_API_Name__c.length() > 14) ? dim.SKU_API_Name__c.substring(0, 13) : dim.SKU_API_Name__c;
                    dim.SKU_API_Name__c = dim.SKU_API_Name__c + productCount;
                }
                if(QL.Product__r.Description != null)
                    dim.Description__c = QL.Product__r.Description.abbreviate(69);
                dim.Units__c = QL.Quantity__c;
                dimList.add(dim);
                productCount++;
            }
        }
        return dimList;
    }

    // public static List<SelectedQuoteWrapper> getQuotesForAccount(String accId, String marketplaceCloudName, Boolean isCPPO){
    //     List<SelectedQuoteWrapper> quoteWrapList = new List<SelectedQuoteWrapper>();
    //     List<CPQ_Quote__c> cpqQuotes = [Selected]
    // }
}
