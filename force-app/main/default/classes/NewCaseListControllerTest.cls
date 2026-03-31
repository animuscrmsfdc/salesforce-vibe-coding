@IsTest
private class NewCaseListControllerTest {

    @TestSetup
    static void makeData() {
        insert new Case(Status = 'New', Origin = 'Web');
    }

    @IsTest
    static void getNewCases_returnsAtLeastOne() {
        NewCaseListController ctrl = new NewCaseListController();

        Test.startTest();
        List<Case> result = ctrl.getNewCases();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 New case');
    }
}
