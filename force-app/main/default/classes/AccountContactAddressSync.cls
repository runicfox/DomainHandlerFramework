public with sharing class AccountContactAddressSync extends DomainLogicHandler {
    List<Contact> contacts = new List<Contact>();
    List<Account> accounts = new List<Account>();
    Map<SObjectField, SObjectField> fieldsMap = new Map<SObjectField, SObjectField>{
        Account.BillingStreet => Contact.MailingStreet,
        Account.BillingCity => Contact.MailingCity,
        Account.BillingState => Contact.MailingState,
        Account.BillingPostalCode => Contact.MailingPostalCode,
        Account.BillingCountry => Contact.MailingCountry,
        Account.Primary_Contact__c => Contact.Id
    };

    public override void check(SObject newObj, SObject oldObj) {
        Account newAccount = (Account) newObj;
        Account oldAccount = (Account) oldObj;

        if (isQualified(newAccount, oldAccount)) {
            addContact(newAccount);
        }
    }

    public override void processRecords() {
        update contacts;
    }

    Boolean isQualified(Account newAccount, Account oldAccount) {
        return hasPrimaryContact(newAccount) &&
            isChanged(newAccount, oldAccount);
    }

    Boolean hasPrimaryContact(Account newAccount) {
        return newAccount.Primary_Contact__c != null;
    }

    Boolean isChanged(Account newAccount, Account oldAccount) {
        for (SObjectField field : fieldsMap.keySet()) {
            if (newAccount.get(field) != oldAccount.get(field)) {
                return true;
            }
        }
        return false;
    }

    void addContact(Account newAccount) {
        Contact contact = new Contact();
        for (SObjectField accountField : fieldsMap.keySet()) {
            SObjectField contactField = fieldsMap.get(accountField);
            contact.put(contactField, newAccount.get(accountField));
        }
        contacts.add(contact);
    }
}
