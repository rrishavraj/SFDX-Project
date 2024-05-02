/**
 * @description This class provides functionalities to fetch contacts related to a specific account.
 * It includes methods to retrieve contact details based on the account ID provided.
 * @author Rishav Raj
 * @date 2024-04-23
 */
public class AccountContactsFetcher {
    /**
     * Retrieves all contacts related to a specified account ID.
     *
     * This method queries the Contact object to find contacts that are linked to the provided account ID.
     * It is designed to handle the scenario where the account ID is not null, throwing an exception otherwise.
     *
     * @param accountId The ID of the account for which contacts are being requested. Must not be null.
     * @return List<Contact> A list of Contact records associated with the given account. Returns an empty list if no contacts are found.
     * @throws IllegalArgumentException if the accountId is null, indicating that the input is not valid.
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
}
        