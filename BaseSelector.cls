public abstract class BaseSelector extends MktpQuoteAggregatorController {
    /*****************************************************************************************************************************
     *
     * Constants
     *
     *****************************************************************************************************************************/
    public final String SOQL = 'SELECT {0} FROM {1}';
    public final String SOQL_WHERE = ' WHERE {0}';
    public final String SOQL_GROUPBY = ' GROUP BY {0}';
    public final String SOQL_GROUPBY_ROLLUP = ' GROUP BY ROLLUP({0})';
    public final String SOQL_ORDERBY = ' ORDER BY {0}';
    public final String SOQL_DELIMITER_AND = ' AND ';
    public final String SOQL_DELIMITER_OR = ' OR ';
    public final String SQL_SECURITY_ENFORCED = ' WITH SECURITY_ENFORCED ';

    // Maximum number of fields allowed in the GROUP BY ROLLUP field list
    public final Integer GROUPBY_ROLLUP_MAX_FIELDS = 3;

    // Method to fetch quote dimensions
    public List<Dimension__c> fetchQuoteDimensions(List<Id> lstQuoteId) {
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

        //Logic for CPQ_Quote_Line_Item__c
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
        
        //Logic for CPQ_Quote_Line_Item__c
        for(CPQ_Quote_Line_Item__c QL : dimListfrCallidus){
            Dimension__c dim = new Dimension__c();
            if(QL.Product__r.Description=='' || QL.Product__r.Description == null || (QL.Product__r.Description !=null && !QL.Product__r.Description.toLowerCase().contains('marketplace fee'))){
                if(QL.Product_Code__c!= null){
    
                    QL.Product_Code__c =QL.Product_Code__c.removeStartIgnoreCase('PAN-');
                    
                    if(QL.Product_Code__c.length()>22)
                        dim.Name = QL.Product_Code__c.substring(0,21);
                    else
                        dim.Name = QL.Product_Code__c;
                    dim.Name =dim.Name + productCount;
                    dim.SKU_API_Name__c = (QL.Product_Code__c).remove('-');
                    dim.SKU_API_Name__c = dim.SKU_API_Name__c.deleteWhitespace();
                    if(dim.SKU_API_Name__c.length()>14)
                        dim.SKU_API_Name__c = dim.SKU_API_Name__c.substring(0,13);
                    else
                        dim.SKU_API_Name__c = dim.SKU_API_Name__c;
                    dim.SKU_API_Name__c = dim.SKU_API_Name__c +productCount;
                }
                if(QL.Product__r.Description != null)
                    dim.Description__c  = QL.Product__r.Description.abbreviate(69);
                dim.Units__c = QL.Quantity__c;
                dimList.add(dim);
                productCount++;
            }
        }
        
        return dimList;
    }

    public String soqlBuilder(String objectName, List<String> fieldList, List<String> whereClauseList, Boolean isAndClause, 
        List<String> orderByList, Boolean isSecurityEnforced) {
        return soqlBuilder(objectName, fieldList, whereClauseList, isAndClause, orderByList, -1, isSecurityEnforced);
    }

    public String soqlBuilder(String objectName, List<String> fieldList, List<String> whereClauseList, Boolean isAndClause, 
        List<String> orderByList, Integer objectLimit, Boolean isSecurityEnforced) {
        return soqlBuilder(objectName, fieldList, whereClauseList, isAndClause, null, false, orderByList, objectLimit, isSecurityEnforced);
    }

    public String soqlBuilder(String objectName, List<String> fieldList, List<String> whereClauseList, Boolean isAndClause, 
        List<String> groupByList, Boolean isRollup, List<String> orderByList, Integer objectLimit, Boolean isSecurityEnforced ) {
        // Validate
        if (String.isEmpty(objectName)) { 
            //throw new CustomException('BaseSelector.soqlBuilder: An object name must be specified');
        }
        if (fieldList == null || fieldList.isEmpty()) {
            //throw new CustomException('BaseSelector.soqlBuilder: Field list must not be empty');
        }
        if (groupByList != null && isRollup && groupByList.size() > GROUPBY_ROLLUP_MAX_FIELDS) {
           // throw new CustomException('BaseSelector.soqlBuilder: GROUP BY ROLLUP field list cannot be more than ' + 
               // GROUPBY_ROLLUP_MAX_FIELDS + '.');
        }

        // Build SOQL command
        String soqlCmd = String.format(SOQL, new List<String>{String.join(fieldList, ','), objectName});

        if (whereClauseList != null && !whereClauseList.isEmpty()) soqlCmd += String.format(SOQL_WHERE, new List<String>{
            String.join(whereClauseList, isAndClause ? SOQL_DELIMITER_AND : SOQL_DELIMITER_OR)});

        if (isSecurityEnforced == true) soqlCmd += SQL_SECURITY_ENFORCED;
            
        if (groupByList != null && !groupByList.isEmpty()) {
            if (isRollup) soqlCmd += String.format(SOQL_GROUPBY_ROLLUP, new List<String>{String.join(groupByList,  ',')});
            else soqlCmd += String.format(SOQL_GROUPBY, new List<String>{String.join(groupByList, ',')});
        }
        
        if (orderByList != null && !orderByList.isEmpty()) soqlCmd += String.format(SOQL_ORDERBY, new List<String>{
            String.join(orderByList,  ',')});
            
        if (objectLimit > 0) soqlCmd += ' LIMIT ' + String.valueOf(objectLimit).replace( ',',  '');

        return soqlCmd;
    }
}
