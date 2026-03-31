@IsTest
private class EmailManagerTest {

    @IsTest
    static void sendMail_doesNotThrow() {
        EmailManager em = new EmailManager();

        Test.startTest();
        em.sendMail('test@example.com', 'Test Subject', 'Test Body');
        Test.stopTest();

        // If no exception is thrown the test passes.
        // Messaging.sendEmail is a no-op in test context.
        System.assert(true, 'sendMail should complete without throwing an exception');
    }

    @IsTest
    static void sendMail_emptyBody_doesNotThrow() {
        EmailManager em = new EmailManager();

        Test.startTest();
        em.sendMail('noreply@example.com', 'Empty Body Test', '');
        Test.stopTest();

        System.assert(true, 'sendMail with empty body should not throw');
    }
}
