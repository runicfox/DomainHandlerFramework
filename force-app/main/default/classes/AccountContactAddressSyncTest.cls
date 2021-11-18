@isTest
public with sharing class AccountContactAddressSyncTest {
    @testSetup
    static void makeData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 1000; i++) {
            String countString = String.valueOf(i);
            accounts.add(
                new Account(
                    Name = 'AccountContactAddressSyncTest Account ' +
                        countString,
                    BillingStreet = countString + ' Street',
                    BillingCity = countString + ' City',
                    BillingState = countString,
                    BillingPostalCode = countString,
                    BillingCountry = countString
                )
            );
        }

        insert accounts;
    }

    @isTest
    static void testPrimaryContactAssignment() {
        Map<Id, Account> accounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    Primary_Contact__c,
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingPostalCode,
                    BillingCountry
                FROM Account
                LIMIT 1000
            ]
        );

        List<Contact> contacts = new List<Contact>();
        for (Id accountId : accounts.keySet()) {
            contacts.add(
                new Contact(
                    AccountId = accountId,
                    LastName = 'ContactAddressSync'
                )
            );
        }
        insert contacts;

        for (Contact contact : contacts) {
            accounts.get(contact.AccountId).Primary_Contact__c = contact.Id;
        }

        Test.startTest();

        update accounts.values();

        Test.stopTest();

        accounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    Primary_Contact__r.MailingStreet,
                    Primary_Contact__r.MailingCity,
                    Primary_Contact__r.MailingState,
                    Primary_Contact__r.MailingPostalCode,
                    Primary_Contact__r.MailingCountry,
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingPostalCode,
                    BillingCountry
                FROM Account
                WHERE Id IN :accounts.keySet()
            ]
        );

        for (Account account : accounts.values()) {
            System.assertEquals(
                Account.BillingStreet,
                Account.Primary_Contact__r.MailingStreet,
                'Mailing Street was not updated on the related Primary Contact.'
            );

            System.assertEquals(
                Account.BillingCity,
                Account.Primary_Contact__r.MailingCity,
                'Mailing City was not updated on the related Primary Contact.'
            );

            System.assertEquals(
                Account.BillingState,
                Account.Primary_Contact__r.MailingState,
                'Mailing State was not updated on the related Primary Contact.'
            );

            System.assertEquals(
                Account.BillingPostalCode,
                Account.Primary_Contact__r.MailingPostalCode,
                'Mailing Postal Code was not updated on the related Primary Contact.'
            );

            System.assertEquals(
                Account.BillingCountry,
                Account.Primary_Contact__r.MailingCountry,
                'Mailing Country was not updated on the related Primary Contact.'
            );
        }
    }
}
