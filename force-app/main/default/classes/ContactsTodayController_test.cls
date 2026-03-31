@isTest
public class ContactsTodayController_test {

    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'contactstoday.test@animuscrm.test',
            Username = 'contactstoday.test@animuscrm.test',
            Alias = 'cttest',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert u;
    }

    @IsTest
    public static void TestContactsTodayController() {
        User u = [SELECT Id FROM User WHERE Username = 'contactstoday.test@animuscrm.test' LIMIT 1];

        System.runAs(u) {
            Contact c = new Contact(FirstName = 'Joe', LastName = 'Test');
            insert c;

            Task t = new Task(Subject = 'test', WhoId = c.Id, Status = 'Open');
            insert t;

            System.assertNotEquals(0, ContactsTodayController.getContactsForToday().size());
        }
    }

}