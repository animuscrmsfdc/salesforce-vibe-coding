@IsTest
private class UdemyOpportunityCcontrollerTest {

    @TestSetup
    static void makeData() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name = 'Null Amount Opp',   StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Amount = null),
            new Opportunity(Name = 'Low Amount Opp',    StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Amount = 5000),
            new Opportunity(Name = 'Medium Amount Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Amount = 25000),
            new Opportunity(Name = 'High Amount Opp',   StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Amount = 75000)
        };
        insert opps;
    }

    @IsTest
    static void updateProfile_nullAmount_setsLow() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Null Amount Opp' LIMIT 1];

        Test.startTest();
        UdemyOpportunityCcontroller.updateProfile(new List<Id>{ opp.Id });
        Test.stopTest();

        Opportunity result = [SELECT Profile__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Low', result.Profile__c, 'Null amount should map to Low profile');
    }

    @IsTest
    static void updateProfile_amountLessThan10k_setsLow() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Low Amount Opp' LIMIT 1];

        Test.startTest();
        UdemyOpportunityCcontroller.updateProfile(new List<Id>{ opp.Id });
        Test.stopTest();

        Opportunity result = [SELECT Profile__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Low', result.Profile__c, 'Amount < 10000 should map to Low profile');
    }

    @IsTest
    static void updateProfile_amountBetween10kAnd50k_setsMedium() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Medium Amount Opp' LIMIT 1];

        Test.startTest();
        UdemyOpportunityCcontroller.updateProfile(new List<Id>{ opp.Id });
        Test.stopTest();

        Opportunity result = [SELECT Profile__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Medium', result.Profile__c, 'Amount between 10000-50000 should map to Medium profile');
    }

    @IsTest
    static void updateProfile_amountGreaterThan50k_setsHigh() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'High Amount Opp' LIMIT 1];

        Test.startTest();
        UdemyOpportunityCcontroller.updateProfile(new List<Id>{ opp.Id });
        Test.stopTest();

        Opportunity result = [SELECT Profile__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High', result.Profile__c, 'Amount > 50000 should map to High profile');
    }

    @IsTest
    static void updateProfile_bulk200Records_noDmlErrors() {
        List<Opportunity> bulkOpps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            bulkOpps.add(new Opportunity(
                Name      = 'Bulk Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount    = 5000 * i
            ));
        }
        insert bulkOpps;

        List<Id> oppIds = new List<Id>();
        for (Opportunity o : bulkOpps) {
            oppIds.add(o.Id);
        }

        Test.startTest();
        UdemyOpportunityCcontroller.updateProfile(oppIds);
        Test.stopTest();

        List<Opportunity> results = [SELECT Profile__c FROM Opportunity WHERE Id IN :oppIds];
        System.assertEquals(200, results.size(), 'All 200 records should be updated');
    }
}
