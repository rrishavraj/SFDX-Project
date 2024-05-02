/**
 * @description This class provides functionalities to fetch accounts related to a specific contact.
 * It includes methods to retrieve account details based on the contact ID provided.
 * @author Rishav Raj
 * @date 2024-04-29
 * @see ContactAccountFetch
 * @since 2024
 * @returns Account[]
 * @example
 * 
 * Id contactId = '003O800000DAowvIAD';
 * 
 * List<Account> relatedAccounts = ContactAccountFetch.getAccountsByContactId(contactId);
 * 
 * System.debug(relatedAccounts);
 */
public with sharing class ContactAccountFetch {
    
    /**
     * @description Retrieves all accounts related to a specified contact ID.
     * @param contactId The ID of the contact for which accounts are being requested. Must not be null.
     * @return List<Account> A list of Account records associated with the given contact. Returns an empty list if no accounts are found.
     * @exception Throws an 'Illegal Argument Exception' if the contactId is null.
     * @group Accounts
     * @deprecated This method is deprecated. Use the new method getRelatedAccountsByContactId(Id contactId) instead.
     * @example
     * 
     * Id contactId = '003O800000DAowvIAD';
     * 
     * List<Account> relatedAccounts = ContactAccountFetch.getAccountsByContactId(contactId);
     * 
     * System.debug(relatedAccounts);
     */
    
    public static List<Account> getAccountsByContactId(Id contactId) {
        if (contactId == null) {
            throw new IllegalArgumentException('Contact ID cannot be null ');
        }

        List<Account> accounts = [
            SELECT Id, Name, Industry, Phone
            FROM Account
            WHERE Id IN (
                SELECT AccountId
                FROM Contact
                WHERE Id = :contactId
            )
        ];

        return accounts;
    }
}
