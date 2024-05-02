@isTest
private class TestAccountRevenueUpdateUsingBatchable{
	@isTest
	private static void testBatch() {

		List<Account> accRecords = new List<Account>();
		Account accRecord = new Account();
		accRecord.Name = 'testAcc';
		accRecord.AnnualRevenue = 100;
		accRecords.add(accRecord);
		insert accRecords;

		Test.startTest();
		  AccountRevenueUpdateUsingBatchable batch = new AccountRevenueUpdateUsingBatchable();
		Database.executeBatch(batch);
		Test.stopTest();
		  List<Account> updateRecords = [Select Id from Account];
		system.assertEquals(1, updateRecords.size());    

		
	}

}