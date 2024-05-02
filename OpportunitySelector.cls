public with sharing class OpportunitySelector extends BaseSelector {
	public OpportunitySelector() {
	}

	static List<String> baseFieldList = new List<String>{
		'Id',
		'Name',
		'StageName',
		'SBQQ__RenewedContract__c',
		'SBQQ__RenewedContract__r.ContractNumber',
		'Is_Merged__c'
	};

    public List<sObject> getAll(String objectName, List<String> fieldList, Set<Id> recordIds, String whereClause, String orderBy) {
        Map<String, Object> bindParams = new Map<String, Object>{'recordIds' => recordIds};

        if (recordIds != null && !recordIds.isEmpty()) {
            bindParams.put('recordIds', recordIds);
        }

		if (whereClause != null && whereClause != '') {
            bindParams.put('whereClause', whereClause);
        }
		 
		
        return getOpportunities(objectName, fieldList, bindParams, orderBy);
    }

	public List<sObject> getOpportunities(String objectName, List<String> fieldList, Map<String, Object> bindParams, String orderBy) {
        String soql = 'SELECT ' + String.join(fieldList, ',') + ' FROM ' + objectName;

        if (bindParams.containsKey('recordIds')) {
            soql += ' WHERE Id IN :recordIds';
        }

        if (bindParams.containsKey('whereClause')) {
            soql += ' AND ' + bindParams.get('whereClause');
        }

        if (orderBy != null && orderBy != '') {
            soql += ' ORDER BY ' + orderBy;
        }
        List<sObject> result = Database.query(soql);

        return result;
    }


	public List<sObject> getOpportunities(List<String> fieldList, Map<String, Object> bindParams) {
        List<String> whereClauseList = new List<String>();
        for (String fieldName : bindParams.keySet()) { 
            whereClauseList.add(fieldName + ' = :' + fieldName);
        }
        String soql = '';
        if (null != fieldList && fieldList.size() > 0) {
            soql = super.soqlBuilder('Opportunity', fieldList, whereClauseList, true, null, false);
        } else {
            soql = super.soqlBuilder('Opportunity', baseFieldList, whereClauseList, true, null, false);
        }
        return Database.queryWithBinds(soql, bindParams, AccessLevel.SYSTEM_MODE);
    }

	public List<Opportunity> getOpportunities(Set<Id> oppIds, List<String> fieldList) {
		List<String> whereClauseList = new List<String>{ 'ID = : oppIds' };
		String soql;
		if (fieldList.size() > 0) {
			soql = super.soqlBuilder('Opportunity', fieldList, whereClauseList, true, null, false);
		} else {
			soql = super.soqlBuilder('Opportunity', baseFieldList, whereClauseList, true, null, false);
		}
		return Database.query(soql);
	}


	public List<Opportunity> getOpenOpportunitiesByAccount(Set<Id> accountIds) {
		final List<String> FIELD_LIST = new List<String>{
			'Id',
			'OwnerId',
			'Owner.Name',
			'AccountId',
			'Account.Name',
			'IsExcludedFromTerritory2Filter__c',
			'Name',
			'StageName',
			'CloseDate',
			'Type',
			'Amount'
		};
		final List<String> CONDITIONS_LIST = new List<String>{ 'IsClosed = false', 'AccountId IN :accountIds', 'IsExcludedFromTerritory2Filter__c = false' };

		string soql;
		soql = super.soqlBuilder('Opportunity', FIELD_LIST, CONDITIONS_LIST, true, null, false);
		return (List<Opportunity>) Database.query(soql);
	}

	public Map<Id, Opportunity> getOpportunitiesMap(Set<Id> oppIds, List<String> fieldList) {
		List<String> whereClauseList = new List<String>{ 'ID = : oppIds' };
		String soql;
		if (fieldList.size() > 0) {
			soql = super.soqlBuilder('Opportunity', fieldList, whereClauseList, true, null, false);
		} else {
			soql = super.soqlBuilder('Opportunity', baseFieldList, whereClauseList, true, null, false);
		}
		return new Map<Id, opportunity>((List<opportunity>) Database.query(soql));
	}

	public List<Opportunity> getOpportunitiesByOfferId(List<String> offerIds, List<String> fieldList) {
		List<String> whereClauseList = new List<String>{ 'GCP_Offer_Id__c =: offerIds order by CloseDate desc' };
		String soql;
		if (fieldList.size() > 0) {
			soql = super.soqlBuilder('Opportunity', fieldList, whereClauseList, true, null, false);
		} else {
			soql = super.soqlBuilder('Opportunity', baseFieldList, whereClauseList, true, null, false);
		}
		return Database.query(soql);
	}

	public class Mock implements System.StubProvider {
		public List<Opportunity> opportunitiesList;

		public Object createStub() {
			return Test.createStub(OpportunitySelector.class, this);
		}

		public Object handleMethodCall(
			Object stubbedObject,
			String stubbedMethodName,
			Type returnType,
			List<Type> listOfParamTypes,
			List<String> listOfParamNames,
			List<Object> listOfArgs
		) {
			return this.opportunitiesList;
		}
	}

	public String getActiveOpportunities() {
		String activeOpportunities = 'SELECT Id, IsActive__c FROM Opportunity WHERE IsClosed = True AND Start_Date__c <= Today AND End_Date__c >= Today AND StageName != \'Closed Lost\' AND StageName != \'Disqualified\' AND IsActive__c = False';
		return activeOpportunities;
	}

	public String getInActiveOpportunities() {
		String inActiveOpportunities = 'SELECT Id, IsActive__c FROM Opportunity WHERE IsClosed = True AND ((Start_Date__c > Today AND End_Date__c > Today) OR (Start_Date__c < Today AND End_Date__c < Today)) AND IsActive__c = True';
		return inActiveOpportunities;       
	}

	//Method to retrive list of Opportunites based on the Param AccountId
	public List<Opportunity> getOpportunitiesListbyAccount(Set<Id> accIds, List<String> fieldList) {
		List<String> whereClauseList = new List<String>{ 'accountId IN : accIds' };
		String soql = '';
		if (fieldList.size() > 0) {
			soql = super.soqlBuilder('Opportunity', fieldList, whereClauseList, false, null, false);
		} else {
			soql = super.soqlBuilder('Opportunity', baseFieldList, whereClauseList, false, null, false);
		}
		return Database.query(soql);
	}
}