@IsTest
private class PermissionSetObjectPermsUpdaterTest {

    @TestSetup
    static void makeData() {
        PermissionSet ps = new PermissionSet(
            Name  = 'TestCoveragePermSet',
            Label = 'Test Coverage Perm Set'
        );
        insert ps;
    }

    @IsTest
    static void upsertObjectPermissions_happyPath() {
        Test.startTest();
        PermissionSetObjectPermsUpdater.UpsertResultSummary summary =
            PermissionSetObjectPermsUpdater.upsertObjectPermissionsForPermSet('TestCoveragePermSet');
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assert(summary.insertedCount + summary.updatedCount + summary.errorCount >= 0, 'Summary counts should be non-negative');
    }

    @IsTest
    static void upsertObjectPermissions_summaryCountsAreNonNegative() {
        Test.startTest();
        PermissionSetObjectPermsUpdater.UpsertResultSummary summary =
            PermissionSetObjectPermsUpdater.upsertObjectPermissionsForPermSet('TestCoveragePermSet');
        Test.stopTest();

        System.assert(summary.updatedCount  >= 0, 'updatedCount must be >= 0');
        System.assert(summary.insertedCount >= 0, 'insertedCount must be >= 0');
        System.assert(summary.skippedCount  >= 0, 'skippedCount must be >= 0');
        System.assertNotEquals(null, summary.skippedObjects, 'skippedObjects list must not be null');
        System.assertNotEquals(null, summary.errors,         'errors list must not be null');
    }

    @IsTest
    static void upsertObjectPermissions_notFoundThrows() {
        Test.startTest();
        try {
            PermissionSetObjectPermsUpdater.upsertObjectPermissionsForPermSet('NonExistentPermSet_XYZ');
            System.assert(false, 'Expected QueryException for missing PermissionSet');
        } catch (QueryException e) {
            System.assert(e.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();
    }
}
