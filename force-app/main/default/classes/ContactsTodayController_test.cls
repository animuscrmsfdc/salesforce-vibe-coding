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

    @IsTest
    static void getContactsForToday_withEvent_returnsEventContact() {
        User u = [SELECT Id FROM User WHERE Username = 'contactstoday.test@animuscrm.test' LIMIT 1];

        System.runAs(u) {
            Contact c = new Contact(FirstName = 'Event', LastName = 'Contact');
            insert c;

            Event e = new Event(
                Subject = 'Client Call',
                WhoId = c.Id,
                StartDateTime = Datetime.now().addHours(1),
                EndDateTime = Datetime.now().addHours(2),
                DurationInMinutes = 60
            );
            insert e;

            List<Contact> result = ContactsTodayController.getContactsForToday();

            Assert.isTrue(result.size() >= 1, 'Event-linked contact should be returned');
            Boolean found = false;
            for (Contact r : result) {
                if (r.Id == c.Id) { found = true; break; }
            }
            Assert.isTrue(found, 'The event contact should be in the result list');
        }
    }

    @IsTest
    static void getContactsForToday_withCase_returnsCaseContact() {
        User u = [SELECT Id FROM User WHERE Username = 'contactstoday.test@animuscrm.test' LIMIT 1];

        System.runAs(u) {
            Account acc = new Account(Name = 'Case Test Account');
            insert acc;

            Contact c = new Contact(FirstName = 'Case', LastName = 'Contact', AccountId = acc.Id);
            insert c;

            Case cs = new Case(ContactId = c.Id, Subject = 'Support Issue', Status = 'New', OwnerId = u.Id);
            insert cs;

            List<Contact> result = ContactsTodayController.getContactsForToday();

            Assert.isTrue(result.size() >= 1, 'Case-linked contact should be returned');
            Boolean found = false;
            for (Contact r : result) {
                if (r.Id == c.Id) { found = true; break; }
            }
            Assert.isTrue(found, 'The case contact should be in the result list');
        }
    }

    @IsTest
    static void getContactsForToday_noData_returnsEmptyList() {
        User u = [SELECT Id FROM User WHERE Username = 'contactstoday.test@animuscrm.test' LIMIT 1];

        System.runAs(u) {
            List<Contact> result = ContactsTodayController.getContactsForToday();

            Assert.isNotNull(result, 'Result should never be null');
            Assert.areEqual(0, result.size(), 'No tasks/events/cases means no contacts returned');
        }
    }

}