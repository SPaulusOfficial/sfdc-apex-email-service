public inherited sharing class InboundEmailHelper {

    private static final String DEFAULT_PATTERN_START = 'ref:';
    private static final String DEFAULT_PATTERN_END = ':ref';
    private Messaging.InboundEmail email;
    private SObjectType sObjectType;
    private SObjectField sObjectField;
    private String patternStart;
    private String patternEnd;
    
    @testVisible
    private EmailMessage emailMessage;

    public InboundEmailHelper(Messaging.InboundEmail email, SObjectType sObjectType, SObjectField sObjectField, String patternStart, String patternEnd){
        validateParameters(email, sObjectType, sObjectField);

        this.email = email;
        this.sObjectType = sObjectType;
        this.sObjectField = sObjectField;
        this.patternStart = patternStart != null ?  patternStart : DEFAULT_PATTERN_START;
        this.patternEnd = patternEnd != null ? patternEnd : DEFAULT_PATTERN_END;
    }

    public InboundEmailHelper(Messaging.InboundEmail email, SObjectType sObjectType, SObjectField sObjectField){
        validateParameters(email, sObjectType, sObjectField);

        this.email = email;
        this.sObjectType = sObjectType;
        this.sObjectField = sObjectField;
        this.patternStart = DEFAULT_PATTERN_START;
        this.patternEnd = DEFAULT_PATTERN_END;
    }

    public InboundEmailHelper(Messaging.InboundEmail email){
        validateParameters(email, Opportunity.SObjectType, Opportunity.Id);

        this.email = email;
        this.sObjectType = Opportunity.SObjectType;
        this.sObjectField = Opportunity.Id;
        this.patternStart = DEFAULT_PATTERN_START;
        this.patternEnd = DEFAULT_PATTERN_END;
    }

    @testVisible
    private InboundEmailHelper(){
        this.email = new Messaging.InboundEmail();
        this.sObjectType = Opportunity.SObjectType;
        this.sObjectField = Opportunity.Id;
        this.patternStart = DEFAULT_PATTERN_START;
        this.patternEnd = DEFAULT_PATTERN_END;
    }

    public void buildEmailMessage(){

        String reference = findReference(email);
        if(reference == null){
            System.debug('Inbound email did not contain a reference pattern matching what was configured. Exiting...');
            return;
        }

        emailMessage = new EmailMessage();
        //emailMessage.RelatedToId = opptyId;
        
        emailMessage.Status = '5'; // Draft
        emailMessage.FromAddress = email.fromAddress;
        emailMessage.FromName = email.fromName;
        emailMessage.Subject = email.subject;
        emailMessage.TextBody = email.plainTextBody;
        emailMessage.HtmlBody = email.htmlBody;
        emailMessage.MessageIdentifier = email.messageId;
        
        //emailMessage.ReplyToEmailMessageId // TODO: Is this needed?
        //emailMessage.ThreadIdentifier //TODO: Is this needed?

        emailMessage.MessageDate = getMessageDate(email.headers);

        // Recipients toRecipients = InboundEmailHelper.findRecipients(email.toAddresses);
        // emailMessage.ToIds = toRecipients.idList;
        // emailMessage.ToAddress = String.join(toRecipients.addressList, ','); 
        // Recipients ccRecipients = InboundEmailHelper.findRecipients(email.ccAddresses);
        // emailMessage.CcIds = ccRecipients.idList;
        // emailMessage.CcAddress = String.join(ccRecipients.addressList, ',');  
        
        System.debug('emailMessage: ' +emailMessage);

        insert emailMessage;

        // This is apparently needed  - it seems to not be enough to set the status at time of insert
        emailMessage.Status = '3'; // Sent
        update emailMessage;

        // Create relations
        // TODO: List<EmailMessageRelation> relations = createEmailMessageRelations(emailMessage, fromId, toIds, ccIds);
        // insert relations;
    }

    @testVisible
    private Id findRelatedToId(String reference, SObjectType sObjectType, SObjectField sObjectField){
        String sObjectTypeName = sObjectType.getDescribe().getName();
        String sObjectFieldName = sObjectField.getDescribe().getLocalName();
        String query = String.format(
            'SELECT Id FROM {0} WHERE {1} = :reference LIMIT 1', 
            new List<String> {sObjectTypeName, sObjectFieldName});

        List<SObject> results = Database.query(query);

        if(results.isEmpty()){
            System.debug('Did not find a matching '+sObjectTypeName+' record for the reference: ' + reference);
            return null;
        }

        Id sObjId = results.get(0).Id;
        System.debug('Found '+sObjectTypeName+' record: '+sObjId+' for the reference: ' + reference);
        
        return sObjId; 
    }

    private List<EmailMessageRelation> createEmailMessageRelations(EmailMessage emailMessage, Id fromId, List<Id> toIds, List<Id> ccIds){
        // EmailMessageRelation emr = new EmailMessageRelation();
        // emr.emailMessageId = emailMessage.Id;
        // emr.relationId = '0056E000004dMZHQA2'; // user id of the sender
        // emr.relationType = 'ToAddress';
        // insert emr;

        // EmailMessageRelation emr2 = new EmailMessageRelation();
        // emr2.emailMessageId = emailMessage.Id;
        // emr2.relationId = '0036E00000WUkw6QAD'; // user id of the sender
        // emr2.relationType = 'FromAddress';
        // insert emr2;

        return new List<EmailMessageRelation>();
    }

    private void validateParameters(Messaging.InboundEmail email, SObjectType sObjectType, SObjectField sObjectField){
        if(email == null) throw createInvalidParameterValueException('email', String.valueOf(email), 'Cannot be null.');
        if(sObjectType == null) throw createInvalidParameterValueException('sObjectType', String.valueOf(sObjectType), 'Cannot be null.');
        if(sObjectField == null) throw createInvalidParameterValueException('field', String.valueOf(sObjectField), 'Cannot be null.');
        if(!sObjectField.getDescribe().isFilterable()) throw createInvalidParameterValueException('sObjectField', String.valueOf(sObjectField), 'Field must be filterable.');
    }

    private InvalidParameterValueException createInvalidParameterValueException(String paramName, String paramValue, String message){
        InvalidParameterValueException ex = new InvalidParameterValueException(paramName, paramValue);
        ex.setMessage(String.format(
            'paramName: {0} - paramValue: {1} - message: {2}', 
            new List<String>{ paramName, paramValue, message }
            ));

        return ex;
    }

    /*
    * Returns the reference or null if not found
    */ 
    @testVisible
    private String findReference(Messaging.InboundEmail email){
        String ref = findReference(email.plainTextBody, patternStart, patternEnd);
        if(String.isBlank(ref)){
            ref = findReference(email.htmlBody, patternStart, patternEnd);
        }

        return ref;
    }

    private String findReference(String body, String patternStart, String patternEnd){
        
        String reference;

        // Find the first part of the pattern or exit early
        String substringAfterPatternStart = body.substringAfter(patternStart);
        System.debug('substringAfterPatternStart: '+substringAfterPatternStart);
        if(!String.isBlank(substringAfterPatternStart)){
            reference = substringAfterPatternStart.substringBefore(patternEnd);
            System.debug('reference: '+reference);
        }

        return reference;
    }

    @testVisible
    private SenderAndRecipients findSenderAndRecipients(Messaging.InboundEmail email){

        SenderAndRecipients recipients = new SenderAndRecipients();
        EmailAddressSearchResult toAddressesSearchResult = searchEmailAddresses(email.toAddresses);
        EmailAddressSearchResult ccAddressesSearchResult = searchEmailAddresses(email.ccAddresses);
        recipients.fromIds = findFromIds(email.fromAddress);
        recipients.toIdList = toAddressesSearchResult.idList;
        recipients.toAddressList = toAddressesSearchResult.addressList;
        recipients.ccIdList = ccAddressesSearchResult.idList;
        recipients.ccAddressList = ccAddressesSearchResult.addressList;

        System.debug('recipients: '+recipients);

        return recipients;
    }

    private List<Id> findFromIds(String fromAddress){
        return searchEmailAddresses(new List<String>{ fromAddress }).idList;
    }

    @testVisible
    private EmailAddressSearchResult searchEmailAddresses(List<String> emailAddresses){

        System.debug('emailAddresses: '+emailAddresses);

        // Convert to Set to avoid returning duplicate results
        Set<String> addressSet = new Set<String>(emailAddresses);

        System.debug('addressSet: '+addressSet);

        // Search all person types by email - SOSL is too unreliable here...
        List<SObject> allResults = new List<SObject>();
        allResults.addAll([SELECT Id, Email FROM User WHERE Email IN: addressSet AND Email != null]);
        allResults.addAll([SELECT Id, Email FROM Contact WHERE Email IN: addressSet AND Email != null]);
        allResults.addAll([SELECT Id, Email FROM Lead WHERE Email IN: addressSet AND Email != null]);
        System.debug(allResults);

        // Map email addresses to person type Ids
        Map<String, List<Id>> addressesWithMatchingIds = new Map<String, List<Id>>();
        for (SObject obj : allResults) {

            // We know that all the searched objects have an email field called "Email"
            String emailAddress = (String) obj.get('Email');
            if(addressesWithMatchingIds.containsKey(emailAddress)){
                addressesWithMatchingIds.get(emailAddress).add(obj.Id);
            }else {
                addressesWithMatchingIds.put(emailAddress, new List<Id>{ obj.Id });
            }
        }

        System.debug('addressesWithMatchingIds: '+addressesWithMatchingIds);

        // Sort recipient email addresses based on whether the address had a matching record in any of the person types
        EmailAddressSearchResult eaSearchResult = new EmailAddressSearchResult();
        for (String emailAddress : addressSet) {

            // Lowercase email to be able to match
            emailAddress = emailAddress.toLowerCase();
            
            if(addressesWithMatchingIds.containsKey(emailAddress)){
                System.debug('addressesWithMatchingIds contained: '+emailAddress);
                eaSearchResult.idList.addAll(addressesWithMatchingIds.get(emailAddress));
            }else {
                System.debug('addressesWithMatchingIds did not contain: '+emailAddress);
                eaSearchResult.addressList.add(emailAddress);
            }
        }

        System.debug('eaSearchResult: '+eaSearchResult);
        return eaSearchResult;
    }

    @testVisible
    private Datetime getMessageDate(List<Messaging.InboundEmail.Header> headers){

        // Cannot reliably parse the Date string from the header.
        // Revert to Now() until another solution can be found.
        return Datetime.now();
    }

    @testVisible
    private class SenderAndRecipients {

        public List<Id> fromIds { get; private set; }
        public List<Id> toIdList { get; private set; }
        public List<String> toAddressList { get; private set; }
        public List<Id> ccIdList { get; private set; }
        public List<String> ccAddressList { get; private set; }

        public SenderAndRecipients(){
            toIdList = new List<Id>();
            toAddressList = new List<String>();
            ccIdList = new List<Id>();
            ccAddressList = new List<String>();
        }
    }

    @testVisible
    private class EmailAddressSearchResult {
        public List<Id> idList { get; private set; }
        public List<String> addressList { get; private set; }

        public EmailAddressSearchResult(){
            idList = new List<Id>();
            addressList = new List<String>();
        }
    }

}
