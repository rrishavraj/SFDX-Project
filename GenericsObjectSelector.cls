public class GenericsObjectSelector extends BaseSelector {
    public GenericsObjectSelector() {

    }

    public List<sObject> getAll(String objectName, List<String> fieldList, Set<Id> recordIdsParam, List<String>  whereClauseList, String orderBy) {
        Map<String, Object> bindParams = new Map<String, Object>{'recordIdsParam' => recordIdsParam};

        if (recordIdsParam != null && !recordIdsParam.isEmpty()) {
            bindParams.put('recordIdsParam', recordIdsParam);
        }

		if (whereClauseList != null && !whereClauseList.isEmpty()) {
            bindParams.put('whereClauseList', whereClauseList);
        }
		 
		
        return getSObjects(objectName, fieldList, bindParams, orderBy);
    }    

    public List<sObject> getSObjects(String objectName, List<String> fieldList, Map<String, Object> bindParams, String orderBy) {
        String soql = 'SELECT ' + String.join(fieldList, ',') + ' FROM ' + objectName;

        if (bindParams.containsKey('recordIdsParam')) {
            soql += ' WHERE Id IN :recordIdsParam';
        }

        if (bindParams.containsKey('whereClauseList')) {
            soql += ' AND ' + bindParams.get('whereClauseList');
        }

        if (orderBy != null && orderBy != '') {
            soql += ' ORDER BY ' + orderBy;
        }
        List<sObject> result = Database.query(soql);

        return result;
    }    
}