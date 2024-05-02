public class MktpQuoteAggregatorController {
    public MktpQuoteAggregatorController() {

    }

    
    public static String upsertMPO(Id offerId, String selectedQuote, string file, string fileName, String fileBase64,List<Dimension__c> dimList, List<Marketplace_Offer_Pricing__c> lstMarketplace_Offer_Pricing, Boolean sendEmail){
        Boolean isdeleted;
        try {
            deleteOfferLines(offerId);
            List<SelectedQuoteWrapper> selectedQuotes = new List<SelectedQuoteWrapper>();
            if(selectedQuote != null){
                selectedQuotes = (List<SelectedQuoteWrapper>)JSON.deserialize(selectedQuote, List<SelectedQuoteWrapper>.class);            
            }
            system.debug('selectedQuotes   '+selectedQuotes);

            List<Marketplace_Offerline__c> mpOfferLineInsert = new List<Marketplace_Offerline__c>();
            Marketplace_Offerline__c offerLine;
            
            if(offerId != null){
                ContentVersion contentVersionRec = new ContentVersion();  
                if(file != null && String.isBlank(file) == false && String.isNotEmpty(file) && String.IsNotBlank(fileName) && fileName!=null && String.isNotBlank(fileBase64) ) {
                    String base64File = EncodingUtil.urlDecode(file, 'UTF-8');     
                    contentVersionRec.Title = fileName;  
                    contentVersionRec.PathOnClient = fileName;  
                    contentVersionRec.FirstPublishLocationId = offerId;  
                    contentVersionRec.VersionData = EncodingUtil.base64Decode(fileBase64); 
                    contentVersionRec.Origin = 'H';  
                    contentVersionRec.IsMajorVersion = true;  
                    Insert contentVersionRec;  
                    createContentLink(contentVersionRec.Id, offerId);
                }  
                set<Id> setToAvoidDuplicates = new set<Id>();
                
                for (SelectedQuoteWrapper mpOfferLine: selectedQuotes){
                    if(!setToAvoidDuplicates.contains(mpOfferLine.quoteId)){
                        
                        setToAvoidDuplicates.add(mpOfferLine.quoteId);
                        offerLine = new Marketplace_Offerline__c();
                        system.debug('Outside loop'+selectedQuotes.size());
                        
                        offerLine.Marketplace_Offer__c = offerId;
                        
                        if(mpOfferLine.medium == 'Callidus'){
                            offerLine.CPQ_Quote__c = mpOfferLine.quoteId;
                        }
                        else{
                            offerLine.Steelbrick_Quote__c = mpOfferLine.quoteId;
                        }    
                        
                        offerLine.Quote_Processed_Status__c = 'Not Processed';
                        offerLine.Offerline_Status__c = 'Open';
                        mpOfferLineInsert.add(offerLine);
                    }
                }
            }

            if(mpOfferLineInsert != null && mpOfferLineInsert.size()>0 ){
                insert mpOfferLineInsert;
            }

            deleteOfferDimensions(offerId);
            if(offerId != null){
                for(Dimension__c dim :dimList){
                    dim.Marketplace_Offer__c = offerId;
                }
                if(dimList != null && !dimList.isEmpty()){
                    insert dimList;
                }
            }
            deleteOfferPricings(offerId);
            if(offerId != null){
                Marketplace_Offer_Pricing__c objMarketplace_Offer_PricingToInsert;
                list<Marketplace_Offer_Pricing__c> lstMarketplace_Offer_PricingToInsert  = new list<Marketplace_Offer_Pricing__c>();
                for(Marketplace_Offer_Pricing__c objMarketplace_Offer_Pricing :lstMarketplace_Offer_Pricing){
                    objMarketplace_Offer_PricingToInsert = new Marketplace_Offer_Pricing__c(Marketplace_Offer__c = offerId);
                    objMarketplace_Offer_PricingToInsert.Payment_Option__c = objMarketplace_Offer_Pricing.Payment_Option__c;
                    objMarketplace_Offer_PricingToInsert.Price_per_Payment__c = objMarketplace_Offer_Pricing.Price_per_Payment__c;
                    objMarketplace_Offer_PricingToInsert.Billing_Term__c = objMarketplace_Offer_Pricing.Billing_Term__c;
                    objMarketplace_Offer_PricingToInsert.Term__c = objMarketplace_Offer_Pricing.Term__c;
                    objMarketplace_Offer_PricingToInsert.Payment_Type__c = objMarketplace_Offer_Pricing.Payment_Type__c;
                    objMarketplace_Offer_PricingToInsert.Invoice_Date__c = objMarketplace_Offer_Pricing.Invoice_Date__c;
                    lstMarketplace_Offer_PricingToInsert.add(objMarketplace_Offer_PricingToInsert);
                }
                if(lstMarketplace_Offer_PricingToInsert != null && !lstMarketplace_Offer_PricingToInsert.isEmpty()){
                    Insert lstMarketplace_Offer_PricingToInsert;
                }
            }
            if(sendEmail){
                SBMarketplaceOffersEmailServices.initiateEmailTriggering(offerId);
            }
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
            String errorMsg = e.getMessage();
            String pureErrorMsg = errorMsg.substringAfter('_EXCEPTION,');
            pureErrorMsg = pureErrorMsg.Substring(0, (pureErrorMsg.length()-4));
            throw new AuraHandledException(pureErrorMsg);
        }
        return offerId;
    }

    /*POC*/


    public static String uploadFiles(String recordId, String filedata, String supdocumentIds, String strStatus) {
        try {
            if(String.isNotBlank(FileData)) {
                List<FileDataWP> files = (List<FileDataWP>) JSON.deserialize(filedata, List<FileDataWP>.class);
                System.debug(files);
 
                List<ContentVersion> cvList = new List<ContentVersion>();
                for(FileDataWP file : files) {
                    ContentVersion conVer = new ContentVersion();
                    conVer.ContentLocation = 'S'; // S = Salesforce, E = External Files
                    conVer.VersionData = EncodingUtil.base64Decode(file.fileContent);
                    conVer.Title = file.fileName;
                    conVer.PathOnClient = file.fileName;
                    cvList.add(conVer);
                }
                Insert cvList;
 
                List<ContentDocumentLink> cdList = new List<ContentDocumentLink>(); 
                for(ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cvList]) {
                    ContentDocumentLink conDocLink = New ContentDocumentLink();
                    conDocLink.LinkedEntityId = recordId;
                    conDocLink.ContentDocumentId = cv.ContentDocumentId;
                    if(String.isBlank(supdocumentIds)){
                        supdocumentIds = conDocLink.ContentDocumentId;
                    }else{
                        supdocumentIds = supdocumentIds + ','+ conDocLink.ContentDocumentId;
                    }
                    conDocLink.Visibility = 'AllUsers';
                    conDocLink.shareType = 'V'; // V = Viewer, C = Collaborator, I = Inferred
                    cdList.add(conDocLink);
                }
                Insert cdList;
      
                if(STRING.isNotBlank(supdocumentIds)){
                    UpdateMPO(recordId, strStatus, supdocumentIds);
                }
            } else {
                return 'record Id is Blank';
            }
            return supdocumentIds;
        } catch (Exception ex) {
            System.debug(ex.getMessage() + ' -> ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
 
    public class FileDataWP {
        public String fileName;
        public String fileContent;
    }

    /* POC End */
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [ SELECT ContentDocumentId 
                                        FROM ContentVersion 
                                        WHERE Id =: contentVersionId
                                        ].ContentDocumentId;
                cdl.LinkedEntityId = recordId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
            try {
                insert cdl;
                return cdl;
            } catch(DMLException e) {
                System.debug(e);
               return null;
            }
    }

    public static void deleteOfferLines(String offerId){
        List<Marketplace_Offerline__c> lstOfferLine = [SELECT Id, Name FROM Marketplace_Offerline__c
                                                        WHERE Marketplace_Offer__c =: offerId];
        if(!lstOfferLine.isEmpty()){
            Delete lstOfferLine;
        }
    }

    public static void deleteOfferDimensions(String offerId){
        List<Dimension__c> dimensionsList = [Select id from Dimension__c where Marketplace_Offer__c =: offerId];
        
        if(!dimensionsList.isEmpty()){
            Delete dimensionsList;
        }
    }

    public static void deleteOfferPricings(String offerId){
        List<Marketplace_Offer_Pricing__c> lstMarketplace_Offer_Pricing = [Select Id from Marketplace_Offer_Pricing__c where Marketplace_Offer__c =: offerId];
        
        if(!lstMarketplace_Offer_Pricing.isEmpty()){
            Delete lstMarketplace_Offer_Pricing;
        }
    }


    
    public static List<Dimension__c> getOfferDimensions(String offerId){
        List<Dimension__c> dimensionsList = [Select id,Description__c,SKU_API_Name__c,Units__c,Name  from Dimension__c where Marketplace_Offer__c =: offerId];
        return dimensionsList;
    }
    
    public static List<ContentDocument> getFiles(List<Id> converList){
        List<ContentDocument> condocList =[Select id,Title,ContentSize,FileExtension from ContentDocument where id in :converList];
        return condocList;  
    }

    
    public static void deleteContentDocument(Id converList){
        List<ContentDocument> condocList =[Select id,Title,ContentSize,FileExtension from ContentDocument where id = :converList];
        delete condocList;  
    }
    public static List<Marketplace_Offer_Pricing__c> getOfferPricing(String offerId){
        return [SELECT Id,Payment_Option__c, Price_per_Payment__c, Billing_Term__c, Term__c, Invoice_Date__c, Payment_Type__c FROM Marketplace_Offer_Pricing__c WHERE Marketplace_Offer__c =: offerId];
    } 
    public static void UpdateMPO(Id offerId,String status, String supportDocIds){
        
        Marketplace_Offer__c mpo = new Marketplace_Offer__c(Id=offerId,Status__c=status,Supporting_Docs_Names__c=String.valueof(supportDocIds)); 
        Update mpo;
    }

    public static List<SelectedQuoteWrapper> getOfferLineDetails(String offerId){
        List<SelectedQuoteWrapper> quoteWrapList= new List<SelectedQuoteWrapper>();
        SelectedQuoteWrapper objSelectedQuoteWrapper;
        set<Id> setQuotesLinked = new set<Id>();
        try {
            List<Marketplace_Offerline__c> lstMarketplaceOfferLines = [SELECT Id, Name, Steelbrick_Quote__c, CPQ_Quote__c , Steelbrick_Quote__r.Name, CPQ_Quote__r.Name, 
                                                                        Steelbrick_Quote__r.Billing_Frequency__c, Steelbrick_Quote__r.NextWave_Theatre__c, Steelbrick_Quote__r.SBQQ__NetAmount__c, Steelbrick_Quote__r.SBQQ__Type__c, Steelbrick_Quote__r.SBQQ__Primary__c,
                                                                        Steelbrick_Quote__r.Quote_Source_Type__c, Steelbrick_Quote__r.SBQQ__Opportunity2__c, Steelbrick_Quote__r.SBQQ__Opportunity2__r.Owner.Name, Steelbrick_Quote__r.SBQQ__Opportunity2__r.Name, Steelbrick_Quote__r.SBQQ__Status__c,Steelbrick_Quote__r.Cloud_NGFW_Overages_Fee__c,
                                                                        Steelbrick_Quote__r.SBQQ__Opportunity2__r.Quote_Type__c, Steelbrick_Quote__r.Opportunity_Owner__c,Steelbrick_Quote__r.SBQQ__ExpirationDate__c,Steelbrick_Quote__r.SBQQ__EndDate__c, Steelbrick_Quote__r.MarketPlace_Name__c,Steelbrick_Quote__r.SBQQ__StartDate__c,Steelbrick_Quote__r.CreatedDate,
                                                                        Steelbrick_Quote__r.SBQQ__Opportunity2__r.Account.Name, CPQ_Quote__r.CreatedDate,CPQ_Quote__r.Opportunity__r.Account.Name, CPQ_Quote__r.Status__c,
                                                                        CPQ_Quote__r.Billing_Frequency__c, CPQ_Quote__r.Total_Net_Price__c,CPQ_Quote__r.Quote_Source_Type__c, CPQ_Quote__r.Opportunity__c, CPQ_Quote__r.Quote_Expiration_Date__c, CPQ_Quote__r.Primary__c,
                                                                        CPQ_Quote__r.Opportunity__r.Name, CPQ_Quote__r.Opportunity__r.Quote_Type__c, CPQ_Quote__r.OpportunityOwner__c, CPQ_Quote__r.CPQ_Theatre__c, CPQ_Quote__r.Marketplace_Cloud__c
                                                                        FROM Marketplace_Offerline__c
                                                                        WHERE Marketplace_Offer__c =: offerId];
            
            for(Marketplace_Offerline__c objMarketplace_Offerline : lstMarketplaceOfferLines){
                objSelectedQuoteWrapper = new SelectedQuoteWrapper();
                if(String.isNotBlank(objMarketplace_Offerline.Steelbrick_Quote__c)){
                    objSelectedQuoteWrapper = prepareQuoteWrapper(objMarketplace_Offerline.Id, objMarketplace_Offerline.Steelbrick_Quote__r);
                    setQuotesLinked.add(objMarketplace_Offerline.Steelbrick_Quote__c);
                }else{
                    objSelectedQuoteWrapper = prepareQuoteWrapper(objMarketplace_Offerline.Id, objMarketplace_Offerline.CPQ_Quote__r);
                    setQuotesLinked.add(objMarketplace_Offerline.Steelbrick_Quote__c);
                }
                quoteWrapList.add(objSelectedQuoteWrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return quoteWrapList;        
    }

    public static List<Dimension__c> getQuoteDimensions(List<Id> lstQuoteId){

        List<SBQQ__QuoteLine__c> dimListfromSBQuote = new List<SBQQ__QuoteLine__c>([select id,Internal_SKU_Name__c, SBQQ__Quantity__c, SBQQ__Product__r.Description from SBQQ__QuoteLine__c where SBQQ__Quote__c in :lstQuoteId]);
        List<CPQ_Quote_Line_Item__c> dimListfrCallidus = new List<CPQ_Quote_Line_Item__c>([select id,Product_Code__c, Quantity__c, Product__r.Description  from CPQ_Quote_Line_Item__c where Product__c !=null and CPQ_Quote__c in :lstQuoteId]);
        List<Dimension__c> dimList = new List<Dimension__c>();
        integer productCount=0;
        
        for(SBQQ__QuoteLine__c QL :dimListfromSBQuote){
            Dimension__c dim = new Dimension__c();
            if(QL.SBQQ__Product__r.Description=='' || QL.SBQQ__Product__r.Description == null || (QL.SBQQ__Product__r.Description !=null && !QL.SBQQ__Product__r.Description.toLowerCase().contains('marketplace fee'))){
                
                if(QL.Internal_SKU_Name__c!= null){
                    QL.Internal_SKU_Name__c =QL.Internal_SKU_Name__c.removeStartIgnoreCase('PAN-');
                    
                    if(QL.Internal_SKU_Name__c.length()>22)
                        dim.Name = QL.Internal_SKU_Name__c.Substring(0,21);
                    else
                        dim.Name = QL.Internal_SKU_Name__c;
                    
                    dim.Name = dim.Name +productCount;

                    dim.SKU_API_Name__c = (QL.Internal_SKU_Name__c).remove('-');
                    //removing whitespaces
                    dim.SKU_API_Name__c = dim.SKU_API_Name__c.deleteWhitespace();
                    if(QL.Internal_SKU_Name__c.length()>14)
                        dim.SKU_API_Name__c = dim.SKU_API_Name__c.substring(0,13);
                    else
                        dim.SKU_API_Name__c = dim.SKU_API_Name__c;

                  if(dim.Name.contains('NGFW'))
                  dim.SKU_API_Name__c = 'CloudNGFWCredits';
                  else                  
                  dim.SKU_API_Name__c = dim.SKU_API_Name__c +productCount;

	
                }
                if(QL.SBQQ__Product__r.Description !=null)
                    dim.Description__c  = QL.SBQQ__Product__r.Description.abbreviate(69);
                dim.Units__c = QL.SBQQ__Quantity__c;
                dimList.add(dim);
                productCount++;
            }
        }

        for(CPQ_Quote_Line_Item__c QL :dimListfrCallidus){
            Dimension__c dim = new Dimension__c();
            if(QL.Product__r.Description=='' || QL.Product__r.Description == null || (QL.Product__r.Description !=null && !QL.Product__r.Description.toLowerCase().contains('marketplace fee'))){
                if(QL.Product_Code__c!= null){
 
                    QL.Product_Code__c =QL.Product_Code__c.removeStartIgnoreCase('PAN-');
                    
                    if(QL.Product_Code__c.length()>22)
                        dim.Name = QL.Product_Code__c.substring(0,21);
                    else
                        dim.Name = QL.Product_Code__c;
                    dim.Name =dim.Name + productCount;
                    dim.SKU_API_Name__c = (QL.Product_Code__c).remove('-');
                    dim.SKU_API_Name__c = dim.SKU_API_Name__c.deleteWhitespace();
                    if(dim.SKU_API_Name__c.length()>14)
                        dim.SKU_API_Name__c = dim.SKU_API_Name__c.substring(0,13);
                    else
                        dim.SKU_API_Name__c = dim.SKU_API_Name__c;
                    dim.SKU_API_Name__c = dim.SKU_API_Name__c +productCount;
                }
                if(QL.Product__r.Description != null)
                    dim.Description__c  = QL.Product__r.Description.abbreviate(69);
                dim.Units__c = QL.Quantity__c;
                dimList.add(dim);
                productCount++;
            }
        }
        return dimList;
    }

    public static OfferLevelDetails getQuoteReferences(Id accountId, List<Id> lstQuoteId){ //map<Id,List<Marketplace_Offer__c>>
        OfferLevelDetails objOfferLevelDetails = new OfferLevelDetails();
        list<String> setSteelbrickQuoteId = new list<String>();
        list<String> setCpqQuoteId = new list<String>();
        set<sObject> setQuotes = new set<sObject>();

        map<Id,List<Marketplace_Offer__c>> mapQuoteReferences = new map<Id,List<Marketplace_Offer__c>>(); 
        String OfferQuery;

        OfferQuery = 'SELECT Id, Name, Steelbrick_Quote__c, CPQ_Quote__c , Marketplace_Offer__c,Marketplace_Offer__r.Id, Marketplace_Offer__r.Name,Marketplace_Offer__r.Status__c, Steelbrick_Quote__r.Name, CPQ_Quote__r.Name,';
        OfferQuery += 'Steelbrick_Quote__r.Customer_Admin_Contact_Name__c, Steelbrick_Quote__r.Customer_Admin_Contact_Email__c,Steelbrick_Quote__r.Reseller_Marketplace_Account_Id__c, Steelbrick_Quote__r.Customer_Marketplace_AccountID__c,Steelbrick_Quote__r.SBQQ__ExpirationDate__c,Steelbrick_Quote__r.SBQQ__EndDate__c,Steelbrick_Quote__r.MarketPlace_Name__c, Steelbrick_Quote__r.SBQQ__Status__c,Steelbrick_Quote__r.Cloud_NGFW_Overages_Fee__c,';               
        OfferQuery += 'CPQ_Quote__r.Reseller_Customer_Marketplace_Account_Id__c,CPQ_Quote__r.Admin_Contact_Name__c, CPQ_Quote__r.Admin_Contact_Email_Address__c, CPQ_Quote__r.Customer_Marketplace_account__c, CPQ_Quote__r.Quote_Expiration_Date__c, CPQ_Quote__r.Marketplace_Cloud__c, CPQ_Quote__r.Status__c';                   
        OfferQuery += ' FROM Marketplace_Offerline__c';
        OfferQuery += ' WHERE Marketplace_Offer__r.End_Customer_Name__c = \''+accountId + '\'';
        
        for(Id quoteId : lstQuoteId){
            if(isSteelbrickQuote(QuoteId)){
                setSteelbrickQuoteId.add(QuoteId);
            }else{
                setCpqQuoteId.add(QuoteId);
            }    
        }

        if( !setSteelbrickQuoteId.isEmpty() && !setCpqQuoteId.isEmpty() ){
            OfferQuery += ' and (Steelbrick_Quote__c IN (\'' + String.join(setSteelbrickQuoteId,'\',\'') + '\') OR CPQ_Quote__c IN (\''+String.join(setCpqQuoteId,'\',\'') + '\'))';
        }else if( !setCpqQuoteId.isEmpty() ){ 
            OfferQuery += ' AND CPQ_Quote__c IN (\''+String.join(setCpqQuoteId,'\',\'') + '\')';
        }else if( !setSteelbrickQuoteId.isEmpty() ){
            OfferQuery += ' AND Steelbrick_Quote__c IN (\''+String.join(setSteelbrickQuoteId,'\',\'') + '\')';
        }else{

        }

        system.debug('Query is '+OfferQuery);
        List<Marketplace_Offerline__c> lstMarketplaceOfferLines = Database.Query(OfferQuery); 
        set<Marketplace_Offer__c> setMarketplace_Offer;
        for(Marketplace_Offerline__c objMarketplace_Offerline : lstMarketplaceOfferLines){
            if(STRING.IsNotBlank(objMarketplace_Offerline.Steelbrick_Quote__c)){
                setQuotes.add(objMarketplace_Offerline.Steelbrick_Quote__r);
                if(mapQuoteReferences.get(objMarketplace_Offerline.Steelbrick_Quote__c) == null || mapQuoteReferences.get(objMarketplace_Offerline.Steelbrick_Quote__c).isEmpty()){
                    mapQuoteReferences.put(objMarketplace_Offerline.Steelbrick_Quote__c, new list<Marketplace_Offer__c>{objMarketplace_Offerline.Marketplace_Offer__r});
                }else{
                    setMarketplace_Offer = new set<Marketplace_Offer__c>();
                    setMarketplace_Offer.addAll(mapQuoteReferences.get(objMarketplace_Offerline.Steelbrick_Quote__c));
                    setMarketplace_Offer.add(objMarketplace_Offerline.Marketplace_Offer__r);
                    mapQuoteReferences.put(objMarketplace_Offerline.Steelbrick_Quote__c, new list<Marketplace_Offer__c>());
                    mapQuoteReferences.get(objMarketplace_Offerline.Steelbrick_Quote__c).addAll(setMarketplace_Offer);
                }
            }else if(STRING.IsNotBlank(objMarketplace_Offerline.CPQ_Quote__c)){
                setQuotes.add(objMarketplace_Offerline.CPQ_Quote__r);
                if(mapQuoteReferences.get(objMarketplace_Offerline.CPQ_Quote__c) == null || mapQuoteReferences.get(objMarketplace_Offerline.CPQ_Quote__c).isEmpty()){
                    mapQuoteReferences.put(objMarketplace_Offerline.CPQ_Quote__c, new list<Marketplace_Offer__c>{objMarketplace_Offerline.Marketplace_Offer__r});
                }else{ 
                    setMarketplace_Offer = new set<Marketplace_Offer__c>();
                    setMarketplace_Offer.addAll(mapQuoteReferences.get(objMarketplace_Offerline.CPQ_Quote__c));
                    setMarketplace_Offer.add(objMarketplace_Offerline.Marketplace_Offer__r);
                    mapQuoteReferences.put(objMarketplace_Offerline.CPQ_Quote__c, new list<Marketplace_Offer__c>());
                    mapQuoteReferences.get(objMarketplace_Offerline.CPQ_Quote__c).addAll(setMarketplace_Offer);                }
            }
        }
        objOfferLevelDetails.theQuoteReferences = mapQuoteReferences;
        if(setQuotes !=null && !setQuotes.isEmpty()){
            prepareContactdetails(objOfferLevelDetails,setQuotes);
        }else{
            set<sObject> setfetchedQuotes = getSelectedQuotes(setSteelbrickQuoteId, setCpqQuoteId);
            if(setfetchedQuotes !=null && !setfetchedQuotes.isEmpty()){
                prepareContactdetails(objOfferLevelDetails,setfetchedQuotes);
            }
        }
        objOfferLevelDetails.maxContractDuration = getMaxContractDuration(setSteelbrickQuoteId, setCpqQuoteId, objOfferLevelDetails);
        
        //system.debug('Quote References are  '+JSON.serialize(mapQuoteReferences));
        system.debug('objOfferLevelDetails References are  '+JSON.serialize(objOfferLevelDetails));

        return objOfferLevelDetails;
        //return mapQuoteReferences;
    }

    public static set<sObject> getSelectedQuotes(List<id> listSteelbrickId, List<Id> lstCpqId){
        set<sObject> setQuotes = new set<sObject>();

        for(SBQQ__Quote__c objSBQuote  : [SELECT Id, Name, Customer_Admin_Contact_Name__c, Customer_Admin_Contact_Email__c,Reseller_Marketplace_Account_Id__c, Customer_Marketplace_AccountID__c, SBQQ__ExpirationDate__c,SBQQ__EndDate__c, MarketPlace_Name__c,Cloud_NGFW_Overages_Fee__c FROM SBQQ__Quote__c WHERE Id IN: listSteelbrickId]){   //STRAT-2543
            setQuotes.add(objSBQuote);
        }

        for(CPQ_Quote__c objCPQQuote : [SELECT Id, Name, Admin_Contact_Name__c, Admin_Contact_Email_Address__c,Reseller_Customer_Marketplace_Account_Id__c, Customer_Marketplace_account__c, Quote_Expiration_Date__c FROM CPQ_Quote__c WHERE Id IN: lstCpqId]){
            setQuotes.add(objCPQQuote);
        }
        return setQuotes;
    }

    public static void prepareContactdetails(OfferLevelDetails objOfferLevelDetails, set<sObject> setQuotes){
        set<String> setToAvoidDuplicates =  new set<String>();
        set<String> setToAvoidResellerDuplicates =  new set<String>();
        objOfferLevelDetails.mapContactNameWithEmail = new map<String,String>();
        //Map < String, String > values;
        objOfferLevelDetails.lstcustomerMarketplaceBillingAccount = new List<map<String,String>>();
        objOfferLevelDetails.lstResellerMarketplaceBillingAccount = new List<map<String,String>>();
        objOfferLevelDetails.customerAdminContactDetails = new List< Map < String, String >>();
        objOfferLevelDetails.cloudOverageDetails = new List< Map < String, String >>(); //STRAT-2543
        for(sObject objQuotes : setQuotes){
            if(isSteelbrickQuote(objQuotes.Id)){
                SBQQ__Quote__c objSBQuote = (SBQQ__Quote__c)objQuotes;
                if(STRING.isNotBlank(objSBQuote.Customer_Marketplace_AccountID__c) && !setToAvoidDuplicates.contains(objSBQuote.Customer_Marketplace_AccountID__c)){
                    setToAvoidDuplicates.add(objSBQuote.Customer_Marketplace_AccountID__c);
                    Map < String, String > values = new Map < String, String > {
                        'label' =>objSBQuote.Customer_Marketplace_AccountID__c,
                        'value' => objSBQuote.Customer_Marketplace_AccountID__c
                    };
                    objOfferLevelDetails.lstcustomerMarketplaceBillingAccount.add(values);
                }
                if(STRING.isNotBlank(objSBQuote.Reseller_Marketplace_Account_Id__c) && !setToAvoidResellerDuplicates.contains(objSBQuote.Reseller_Marketplace_Account_Id__c)){
                    setToAvoidResellerDuplicates.add(objSBQuote.Reseller_Marketplace_Account_Id__c);
                    Map < String, String > values = new Map < String, String > {
                        'label' =>objSBQuote.Reseller_Marketplace_Account_Id__c,
                        'value' => objSBQuote.Reseller_Marketplace_Account_Id__c
                    };
                    objOfferLevelDetails.lstResellerMarketplaceBillingAccount.add(values);
                }
                if(STRING.isNotBlank(objSBQuote.Customer_Admin_Contact_Name__c)  && !setToAvoidDuplicates.contains(objSBQuote.Customer_Admin_Contact_Name__c)){
                    setToAvoidDuplicates.add(objSBQuote.Customer_Admin_Contact_Name__c);
                    Map < String, String > values = new Map < String, String > {
                        'label' => objSBQuote.Customer_Admin_Contact_Name__c,
                        'value' => objSBQuote.Customer_Admin_Contact_Name__c
                    };
                    objOfferLevelDetails.customerAdminContactDetails.add(values);
                    objOfferLevelDetails.mapContactNameWithEmail.put(objSBQuote.Customer_Admin_Contact_Name__c,objSBQuote.Customer_Admin_Contact_Email__c);
                }
                if(STRING.isNotBlank(String.valueOf(objSBQuote.Cloud_NGFW_Overages_Fee__c))){  //STRAT-2543
                    Map < String, String > values = new Map < String, String > {
                        'label' =>String.valueOf(objSBQuote.Cloud_NGFW_Overages_Fee__c),
                        'value' => String.valueOf(objSBQuote.Cloud_NGFW_Overages_Fee__c)
                    };
                    objOfferLevelDetails.cloudOverageDetails.add(values);
                }
            }else{ 
                CPQ_Quote__c objCPQQuote = (CPQ_Quote__c)objQuotes;
                if(STRING.isNotBlank(objCPQQuote.Customer_Marketplace_account__c) && !setToAvoidDuplicates.contains(objCPQQuote.Customer_Marketplace_account__c)){
                    setToAvoidDuplicates.add(objCPQQuote.Customer_Marketplace_account__c);
                    Map < String, String > values = new Map < String, String > {
                        'label' => objCPQQuote.Customer_Marketplace_account__c,
                        'value' => objCPQQuote.Customer_Marketplace_account__c
                    };
                    objOfferLevelDetails.lstcustomerMarketplaceBillingAccount.add(values);
                }
                 if(STRING.isNotBlank(objCPQQuote.Reseller_Customer_Marketplace_Account_Id__c) && !setToAvoidResellerDuplicates.contains(objCPQQuote.Reseller_Customer_Marketplace_Account_Id__c)){
                    setToAvoidResellerDuplicates.add(objCPQQuote.Reseller_Customer_Marketplace_Account_Id__c);
                    Map < String, String > values = new Map < String, String > {
                        'label' =>objCPQQuote.Reseller_Customer_Marketplace_Account_Id__c,
                        'value' => objCPQQuote.Reseller_Customer_Marketplace_Account_Id__c
                    };
                    objOfferLevelDetails.lstResellerMarketplaceBillingAccount.add(values);
                }
                if(STRING.isNotBlank(objCPQQuote.Admin_Contact_Name__c) && !setToAvoidDuplicates.contains(objCPQQuote.Admin_Contact_Name__c)){
                    setToAvoidDuplicates.add(objCPQQuote.Admin_Contact_Name__c);
                    Map < String, String > values = new Map < String, String > {
                        'label' => objCPQQuote.Admin_Contact_Name__c,
                        'value' => objCPQQuote.Admin_Contact_Name__c
                    };
                    objOfferLevelDetails.customerAdminContactDetails.add(values);
                    objOfferLevelDetails.mapContactNameWithEmail.put(objCPQQuote.Admin_Contact_Name__c,objCPQQuote.Admin_Contact_Email_Address__c);
                }
            }
        }
    }

    public static SelectedQuoteWrapper prepareQuoteWrapper(Id offerlineId, sObject objectInstance){
        SelectedQuoteWrapper quoteWrap = new SelectedQuoteWrapper();
        quoteWrap.OfferLineId = offerlineId;
        if(isSteelbrickQuote(objectInstance.Id)){
            SBQQ__Quote__c sbq = (SBQQ__Quote__c)objectInstance;
            quoteWrap.quoteId = sbq.Id;
            quoteWrap.status = sbq.SBQQ__Status__c;
            quoteWrap.quote = sbq.Name;
            quoteWrap.isPrimary = sbq.SBQQ__Primary__c;
            quoteWrap.quoteExpiryDate = String.valueOf(sbq.SBQQ__ExpirationDate__c);
            quoteWrap.subscriptionEndDate = String.valueOf(sbq.SBQQ__EndDate__c);
            quoteWrap.invoiceStartDate = String.valueOf(sbq.CreatedDate);
            quoteWrap.opportunityName = sbq.SBQQ__Opportunity2__r.Name;
            quoteWrap.opportunityId = sbq.SBQQ__Opportunity2__c;
            quoteWrap.theatre = sbq.NextWave_Theatre__c;
            quoteWrap.quoteType = sbq.SBQQ__Type__c;
            quoteWrap.netAmount = sbq.SBQQ__NetAmount__c;
            quoteWrap.medium = 'Steelbrick';
            quoteWrap.cloud = sbq.MarketPlace_Name__c; //'GCP';
            quoteWrap.billingFrequency = sbq.Billing_Frequency__c;
            quoteWrap.billingFrequencyInternalReference = sbq.Billing_Frequency__c;
            quoteWrap.accountName = sbq.SBQQ__Opportunity2__r.Account.Name;
            quoteWrap.cloudNGFWOverages = String.valueOf(sbq.Cloud_NGFW_Overages_Fee__c); // STRAT-2543
        }
        else{
            CPQ_Quote__c cpq = (CPQ_Quote__c)objectInstance;
            quoteWrap.accountName = cpq.Opportunity__r.Account.Name;
            quoteWrap.status = cpq.Status__c;
            quoteWrap.billingFrequencyInternalReference = 'Invoice Plan'; 
            quoteWrap.isPrimary = cpq.Primary__c;
            quoteWrap.quoteId = cpq.Id;
            quoteWrap.quote = cpq.Name;
            quoteWrap.quoteExpiryDate = String.valueOf(cpq.Quote_Expiration_Date__c);
            quoteWrap.invoiceStartDate = String.valueOf(cpq.CreatedDate);
            quoteWrap.opportunityName = cpq.Opportunity__r.Name;
            quoteWrap.opportunityId = cpq.Opportunity__c;
            quoteWrap.theatre = cpq.CPQ_Theatre__c;
            quoteWrap.quoteType = cpq.Opportunity__r.Quote_Type__c;
            quoteWrap.netAmount = cpq.Total_Net_Price__c;
            quoteWrap.medium = 'Callidus';
            quoteWrap.cloud = cpq.Marketplace_Cloud__c;
            quoteWrap.billingFrequency = cpq.Billing_Frequency__c;    
            if(STRING.isBlank(cpq.Billing_Frequency__c)){
                quoteWrap.billingFrequencyInternalReference = 'Upfront';
            }
        }
        return quoteWrap;
    }
     // Added by Gowthami FOR CHNLS-502
     public static List<SelectedQuoteWrapper> getOfferLineDetails(String offerId){
        List<SelectedQuoteWrapper> quoteWrapList= new List<SelectedQuoteWrapper>();
        SelectedQuoteWrapper objSelectedQuoteWrapper;
        set<Id> setQuotesLinked = new set<Id>();
        try {
            List<Marketplace_Offerline__c> lstMarketplaceOfferLines = [SELECT Id, Name, Steelbrick_Quote__c, CPQ_Quote__c , Steelbrick_Quote__r.Name, CPQ_Quote__r.Name, 
                                                                        Steelbrick_Quote__r.Billing_Frequency__c, Steelbrick_Quote__r.NextWave_Theatre__c, Steelbrick_Quote__r.SBQQ__NetAmount__c, Steelbrick_Quote__r.SBQQ__Type__c, Steelbrick_Quote__r.SBQQ__Primary__c,
                                                                        Steelbrick_Quote__r.Quote_Source_Type__c, Steelbrick_Quote__r.SBQQ__Opportunity2__c, Steelbrick_Quote__r.SBQQ__Opportunity2__r.Owner.Name, Steelbrick_Quote__r.SBQQ__Opportunity2__r.Name, Steelbrick_Quote__r.SBQQ__Status__c,Steelbrick_Quote__r.Cloud_NGFW_Overages_Fee__c,
                                                                        Steelbrick_Quote__r.SBQQ__Opportunity2__r.Quote_Type__c, Steelbrick_Quote__r.Opportunity_Owner__c,Steelbrick_Quote__r.SBQQ__ExpirationDate__c,Steelbrick_Quote__r.SBQQ__EndDate__c, Steelbrick_Quote__r.MarketPlace_Name__c,Steelbrick_Quote__r.SBQQ__StartDate__c,Steelbrick_Quote__r.CreatedDate,
                                                                        Steelbrick_Quote__r.SBQQ__Opportunity2__r.Account.Name, CPQ_Quote__r.CreatedDate,CPQ_Quote__r.Opportunity__r.Account.Name, CPQ_Quote__r.Status__c,
                                                                        CPQ_Quote__r.Billing_Frequency__c, CPQ_Quote__r.Total_Net_Price__c,CPQ_Quote__r.Quote_Source_Type__c, CPQ_Quote__r.Opportunity__c, CPQ_Quote__r.Quote_Expiration_Date__c, CPQ_Quote__r.Primary__c,
                                                                        CPQ_Quote__r.Opportunity__r.Name, CPQ_Quote__r.Opportunity__r.Quote_Type__c, CPQ_Quote__r.OpportunityOwner__c, CPQ_Quote__r.CPQ_Theatre__c, CPQ_Quote__r.Marketplace_Cloud__c
                                                                        FROM Marketplace_Offerline__c
                                                                        WHERE Marketplace_Offer__c =: offerId];
            
            for(Marketplace_Offerline__c objMarketplace_Offerline : lstMarketplaceOfferLines){
                objSelectedQuoteWrapper = new SelectedQuoteWrapper();
                if(String.isNotBlank(objMarketplace_Offerline.Steelbrick_Quote__c)){
                    objSelectedQuoteWrapper = prepareQuoteWrapper(objMarketplace_Offerline.Id, objMarketplace_Offerline.Steelbrick_Quote__r);
                    setQuotesLinked.add(objMarketplace_Offerline.Steelbrick_Quote__c);
                }else{
                    objSelectedQuoteWrapper = prepareQuoteWrapper(objMarketplace_Offerline.Id, objMarketplace_Offerline.CPQ_Quote__r);
                    setQuotesLinked.add(objMarketplace_Offerline.Steelbrick_Quote__c);
                }
                quoteWrapList.add(objSelectedQuoteWrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return quoteWrapList;        
    }



    public static List<SelectedQuoteWrapper> getQuotesForAccount(String accId, String marketplaceCloudName,Boolean isCPPO){
        List<SelectedQuoteWrapper> quoteWrapList= new List<SelectedQuoteWrapper>();
        //List<QuoteListWrapper> quoteList = new List<QuoteListWrapper>();
        List<CPQ_Quote__c> cpqQuotes= [SELECT Id,Opportunity__r.Distributor__c,Opportunity__r.Second_Tier_Reseller__c,Opportunity__r.Distributor__r.Name,Opportunity__r.Second_Tier_Reseller__r.Name,Opportunity__r.Deal_Type__c, Primary__c, Name, Status__c, Quote_Expiration_Date__c, Billing_Frequency__c, Total_Net_Price__c,Quote_Source_Type__c,Opportunity__c,Opportunity__r.Name, Opportunity__r.Quote_Type__c, CPQ_Theatre__c,Marketplace_Cloud__c,CreatedDate,Opportunity__r.Account.Name  FROM CPQ_Quote__c WHERE Opportunity__r.isEDIOpportunity__c = false AND Opportunity__r.IsClosed= false AND Opportunity__r.Marketplace_Type__c = 'Private' AND Status__c='Approved' AND Opportunity__r.AccountId =: accId AND Marketplace_Cloud__c =: marketplaceCloudName]; //AND Primary__c =true
        List<SBQQ__Quote__c> sbQuotes =[SELECT Id,SBQQ__Opportunity2__r.Distributor__c,SBQQ__Opportunity2__r.Second_Tier_Reseller__c,SBQQ__Opportunity2__r.Distributor__r.Name,SBQQ__Opportunity2__r.Second_Tier_Reseller__r.Name,SBQQ__Opportunity2__r.Deal_Type__c, SBQQ__Primary__c, Name, SBQQ__Status__c, SBQQ__ExpirationDate__c,SBQQ__EndDate__c, Billing_Frequency__c,NextWave_Theatre__c,SBQQ__NetAmount__c,SBQQ__Type__c,Quote_Source_Type__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name, SBQQ__Opportunity2__r.Quote_Type__c,Opportunity_Owner__c, MarketPlace_Name__c,SBQQ__StartDate__c,CreatedDate,SBQQ__Opportunity2__r.Account.Name,Cloud_NGFW_Overages_Fee__c //STRAT-2543
                                        ,(SELECT Id, Name FROM SBQQ__LineItems__r WHERE SBQQ__ProductCode__c LIKE :SBMarketplaceConstants.MARKETPLACE_SKU_PRODUCTCODE)
                                        FROM SBQQ__Quote__c 
                                         WHERE SBQQ__Opportunity2__r.isEDIOpportunity__c = false AND 
                                                SBQQ__Opportunity2__r.IsClosed = false AND 
                                                Marketplace_Account_Lookup__c != null AND
                                                SBQQ__Status__c = 'Approved' AND 
                                                SBQQ__Opportunity2__r.AccountId =: accId AND 
                                                MarketPlace_Name__c =: marketplaceCloudName]; //AND SBQQ__Primary__c =true 
                                                
        SelectedQuoteWrapper quoteWrap;
        for(CPQ_Quote__c cpq: cpqQuotes) {
            if((isCPPO && cpq.Opportunity__r.Deal_Type__c!='Direct') || !isCPPO){
                quoteWrap = new SelectedQuoteWrapper();
                quoteWrap.accountName = cpq.Opportunity__r.Account.Name;
                if(cpq.Opportunity__r.Distributor__c!=null)
                    quoteWrap.DistiName = cpq.Opportunity__r.Distributor__r.Name;
                if(cpq.Opportunity__r.Second_Tier_Reseller__c!=null)
                    quoteWrap.ResellerName = cpq.Opportunity__r.Second_Tier_Reseller__r.Name;
                quoteWrap.isPrimary = cpq.Primary__c;
                quoteWrap.status = cpq.Status__c;
                quoteWrap.billingFrequencyInternalReference = 'Invoice Plan'; 
                quoteWrap.quoteExpiryDate = String.valueOf(cpq.Quote_Expiration_Date__c);
                quoteWrap.invoiceStartDate = String.valueOf(cpq.CreatedDate);
                quoteWrap.quoteId = cpq.Id;
                quoteWrap.quote = cpq.Name;
                quoteWrap.opportunityName = cpq.Opportunity__r.Name;
                quoteWrap.opportunityId = cpq.Opportunity__c;
                quoteWrap.theatre = cpq.CPQ_Theatre__c;
                quoteWrap.dealtype = cpq.Opportunity__r.Deal_Type__c ;
                quoteWrap.quoteType = cpq.Opportunity__r.Quote_Type__c;
                quoteWrap.netAmount = cpq.Total_Net_Price__c;
                quoteWrap.medium = 'Callidus';
                quoteWrap.cloud = cpq.Marketplace_Cloud__c; //'GCP';
                quoteWrap.billingFrequency = cpq.Billing_Frequency__c;
                if(STRING.isBlank(cpq.Billing_Frequency__c)){
                    quoteWrap.billingFrequencyInternalReference = 'Upfront';
                }
                quoteWrapList.add(quoteWrap);
            }
        }
        for(SBQQ__Quote__c sbQ: sbQuotes) {
            if((isCPPO && sbq.SBQQ__Opportunity2__r.Deal_Type__c!='Direct') || !isCPPO){
                if(sbQ.SBQQ__LineItems__r != null && !sbQ.SBQQ__LineItems__r.isEmpty() && sbQ.SBQQ__LineItems__r.Size() > 0){
                    quoteWrap = new SelectedQuoteWrapper();
                    quoteWrap.quoteId = sbq.Id;
                    quoteWrap.accountName = sbq.SBQQ__Opportunity2__r.Account.Name;
                    if(sbq.SBQQ__Opportunity2__r.Distributor__c!=null)
                        quoteWrap.DistiName = sbq.SBQQ__Opportunity2__r.Distributor__r.Name;
                    if(sbq.SBQQ__Opportunity2__r.Second_Tier_Reseller__c!=null)
                        quoteWrap.ResellerName = sbq.SBQQ__Opportunity2__r.Second_Tier_Reseller__r.Name;
                    quoteWrap.status = sbq.SBQQ__Status__c;
                    quoteWrap.isPrimary = sbq.SBQQ__Primary__c;
                    quoteWrap.quoteExpiryDate = String.valueOf(sbq.SBQQ__ExpirationDate__c);
                    quoteWrap.subscriptionEndDate = String.valueOf(sbq.SBQQ__EndDate__c);
                    quoteWrap.invoiceStartDate = String.valueOf(sbq.CreatedDate);
                    quoteWrap.quote = sbq.Name;
                    quoteWrap.opportunityName = sbq.SBQQ__Opportunity2__r.Name;
                    quoteWrap.opportunityId = sbq.SBQQ__Opportunity2__c;
                    quoteWrap.theatre = sbq.NextWave_Theatre__c;
                    quoteWrap.dealtype = sbq.SBQQ__Opportunity2__r.Deal_Type__c ;
                    quoteWrap.quoteType = sbq.SBQQ__Type__c;
                    quoteWrap.netAmount = sbq.SBQQ__NetAmount__c;
                    quoteWrap.medium = 'Steelbrick';
                    quoteWrap.cloud = sbq.MarketPlace_Name__c; //'GCP';
                    quoteWrap.billingFrequency = sbq.Billing_Frequency__c;
                    quoteWrap.billingFrequencyInternalReference = sbq.Billing_Frequency__c;
                    quoteWrap.cloudNGFWOverages= String.valueOf(sbq.Cloud_NGFW_Overages_Fee__c); //STRAT-2543
                    quoteWrapList.add(quoteWrap);
                }
            }
        }
        return quoteWrapList;
    }

    public Static Decimal getMaxContractDuration(List<id> listSteelbrickId, List<Id> lstCpqId,OfferLevelDetails objOfferLevelDetails){
        map<Id,Decimal> mapMaxTermPerQuote = new map<Id,Decimal>();
        List<CPQ_Quote_Line_Item__c> lstCPQ_Quote_Line_Item;
        List<SBQQ__QuoteLine__c> lstQuoteLine;
        Decimal cpqQuoteMaxTerm =0;
        Decimal sbQuoteMaxTerm = 0;

        if(!(lstCpqId.isEmpty())){
            lstCPQ_Quote_Line_Item = [SELECT Id, Name, Term_In_Mons__c,CPQ_Quote__c FROM CPQ_Quote_Line_Item__c WHERE CPQ_Quote__c IN: lstCpqId];
            for(CPQ_Quote_Line_Item__c objCPQ_Quote_Line_Item : lstCPQ_Quote_Line_Item){
                // find the maximum term through the quote being selected.
                if(cpqQuoteMaxTerm < objCPQ_Quote_Line_Item.Term_In_Mons__c){
                    cpqQuoteMaxTerm = objCPQ_Quote_Line_Item.Term_In_Mons__c;
                }
                // Prepare a map as well; This might be needed in future.
                if(mapMaxTermPerQuote.get(objCPQ_Quote_Line_Item.CPQ_Quote__c) == null ){
                    mapMaxTermPerQuote.put(objCPQ_Quote_Line_Item.CPQ_Quote__c, (Decimal)objCPQ_Quote_Line_Item.Term_In_Mons__c);
                }else{
                    if(mapMaxTermPerQuote.get(objCPQ_Quote_Line_Item.CPQ_Quote__c) < objCPQ_Quote_Line_Item.Term_In_Mons__c ){
                        mapMaxTermPerQuote.put(objCPQ_Quote_Line_Item.CPQ_Quote__c, (Decimal)objCPQ_Quote_Line_Item.Term_In_Mons__c);
                    }
                }
            }
        }
        if(!(listSteelbrickId.isEmpty())){
            lstQuoteLine = [SELECT Id, Name, Term__c, SBQQ__Quote__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN: listSteelbrickId];
            for(SBQQ__QuoteLine__c objSBQQ_QuoteLine : lstQuoteLine){
                // find the maximum term through the quote being selected.
                if(sbQuoteMaxTerm < objSBQQ_QuoteLine.SBQQ__SubscriptionTerm__c){
                    sbQuoteMaxTerm = objSBQQ_QuoteLine.SBQQ__SubscriptionTerm__c;
                }
                // Prepare a map as well; This might be needed in future.
                if(mapMaxTermPerQuote.get(objSBQQ_QuoteLine.SBQQ__Quote__c) == null ){
                    mapMaxTermPerQuote.put(objSBQQ_QuoteLine.SBQQ__Quote__c,objSBQQ_QuoteLine.SBQQ__SubscriptionTerm__c);
                }else{
                    if(mapMaxTermPerQuote.get(objSBQQ_QuoteLine.SBQQ__Quote__c) < objSBQQ_QuoteLine.SBQQ__SubscriptionTerm__c){
                        mapMaxTermPerQuote.put(objSBQQ_QuoteLine.SBQQ__Quote__c, objSBQQ_QuoteLine.SBQQ__SubscriptionTerm__c);
                    }
                }
            }
        }
        objOfferLevelDetails.mapMaxTermPerQuote = mapMaxTermPerQuote; 
        if(sbQuoteMaxTerm >= cpqQuoteMaxTerm){
            return sbQuoteMaxTerm;
        }

        return cpqQuoteMaxTerm;
    } 
    public class OfferLevelDetails{
        @AuraEnabled
        public map<Id,List<Marketplace_Offer__c>> theQuoteReferences;
        @AuraEnabled
        public List<map<String,String>> lstResellerMarketplaceBillingAccount;
        @AuraEnabled
        public List<map<String,String>> lstcustomerMarketplaceBillingAccount;
        @AuraEnabled
        public List<map<String,String>> customerAdminContactDetails;
        @AuraEnabled
        public List<map<String,String>> cloudOverageDetails; //STRAT-2543
        @AuraEnabled
        public map<String,String> mapContactNameWithEmail;
        @AuraEnabled
        public Decimal maxContractDuration;
        @AuraEnabled
        public map<Id,Decimal> mapMaxTermPerQuote;
    }

    public class SelectedQuoteWrapper{
        @AuraEnabled
        public Boolean isPrimary;
        @AuraEnabled
        public string quoteExpiryDate;
        @AuraEnabled
        public string invoiceStartDate;
        @AuraEnabled
        public string subscriptionEndDate;
        @AuraEnabled
        public string DistiName;
        @AuraEnabled
        public string ResellerName;
        @AuraEnabled
        public string accountName;
        @AuraEnabled
        public String offerLineId;
        @AuraEnabled
        public String quote, status;
        @AuraEnabled
        public String opportunityName, opportunityId;
        @AuraEnabled
        public String theatre;
        @AuraEnabled
        public String cloud;
        @AuraEnabled
        public String quoteType;
        @AuraEnabled
        public String dealtype;
        @AuraEnabled
        public String medium;
        @AuraEnabled
        public Decimal netAmount;
        @AuraEnabled
        public String quoteId, billingFrequency;     
        @AuraEnabled
        public String billingFrequencyInternalReference;
        @AuraEnabled
        public string cloudNGFWOverages; //STRAT-2543
        @AuraEnabled
        public string offerType;
    }

    public static Boolean isSteelbrickQuote(Id quoteId) {
        String steelbrickQuote = Schema.SObjectType.sbqq__quote__c.getKeyPrefix();
        if(((String)quoteId).startsWith(steelbrickQuote)){
          return true;
        } else {
          return false;
        }
      }
    
}