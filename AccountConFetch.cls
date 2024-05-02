/**
 * @description This class provides functionalities to fetch contacts related to a specific account.
 * It includes methods to retrieve contact details based on the account ID provided.
 * @author Rishav Raj
 * @date 2026-04-23
 * @see AccountConFetch
 * @since 2024
 * @returns Contact[]
 * @group-content D:\apex dev\apex development\apex-documentation
 * @group Contacts
 * @example
 * 
 * Id accountId = '001O800000AsS6PIAV';
 * 
 * List<Contact> relatedContacts = AccountConFetch.getContactsByAccountId(accountId);
 * 
 * System.debug(relatedContacts);
 */
public with sharing class AccountConFetch {

    /**
     * @description Retrieves all contacts related to a specified account ID.
     * @param accountId The ID of the account for which contacts are being requested. Must not be null.
     * @return List<Contact> A list of Contact records associated with the given account. Returns an empty list if no contacts are found.
     * @exception Throws an 'Illegal Argument Exception'
     * @group Contacts
     * @example
     *
     * Id accountId = '001O800000AsS6PIAV';
     * 
     * List<Contact> relatedContacts = AccountConFetch.getContactsByAccountId(accountId);
     *
     * System.debug(relatedContacts);
     * @deprecated	This method is no longer used now
     */ 
    public static List<Contact> getContactsByAccountId(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null');
        }

        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, Phone, AccountId
            FROM Contact
            WHERE AccountId = :accountId
        ];

        return contacts;
    }

    /**
     * @description Populates the Status__c picklist field for active contacts related to a specified account ID.
     * @param accountId The ID of the account for which contacts' status needs to be updated.
     * @group Contacts
     * @deprecated This method is deprecated. Please use the updateStatusPicklist method instead.
     * @example
     * 
     * Id accountId = '001O800000AsS6PIAV';
     * 
     * AccountConFetch.populateStatusPicklist(accountId);
     * 
     */

    public static void populateStatusPicklist(Id accountId) {
        List<Contact> activeContacts = [
            SELECT Id, Status__c
            FROM Contact
            WHERE AccountId = :accountId
                AND Status__c = 'Active'
        ];

        for (Contact con : activeContacts) {
            con.Status__c = 'Active';
        }

        update activeContacts;
    }
}