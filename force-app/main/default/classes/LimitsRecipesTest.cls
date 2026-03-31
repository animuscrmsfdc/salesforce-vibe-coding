@IsTest
private class LimitsRecipesTest {

    @IsTest
    static void getQueries_doesNotThrow() {
        Test.startTest();
        LimitsRecipes.getQueries();
        Test.stopTest();

        System.assert(true, 'getQueries should complete without throwing an exception');
    }
}
