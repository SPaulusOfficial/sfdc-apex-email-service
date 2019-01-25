public inherited sharing class InboundEmailHelper {

    private static final String DEFAULT_PATTERN_START = 'ref:';
    private static final String DEFAULT_PATTERN_END = ':ref';
    private Messaging.InboundEmail email;
    private SObjectType sObjectType;
    private SObjectField field;
    private String patternStart;
    private String patternEnd;
    
    @testVisible
    private EmailMessage emailMessage;

    public InboundEmailHelper(Messaging.InboundEmail email, SObjectType sObjectType, SObjectField field, String patternStart, String patternEnd){
        validateParameters(email, sObjectType, field);

        this.email = email;
        this.sObjectType = sObjectType;
        this.field = field;
        this.patternStart = patternStart != null ?  patternStart : DEFAULT_PATTERN_START;
        this.patternEnd = patternEnd != null ? patternEnd : DEFAULT_PATTERN_END;
    }

    public InboundEmailHelper(Messaging.InboundEmail email, SObjectType sObjectType, SObjectField field){
        validateParameters(email, sObjectType, field);

        this.email = email;
        this.sObjectType = sObjectType;
        this.field = field;
        this.patternStart = DEFAULT_PATTERN_START;
        this.patternEnd = DEFAULT_PATTERN_END;
    }

    private InboundEmailHelper(){}

    public void buildEmailMessage(){

        String reference = findReference();
        if(reference == null){
            System.debug('Inbound email did not contain a reference pattern matching what was configured. Exiting.');
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

        Recipients toRecipients = InboundEmailHelper.findRecipients(email.toAddresses);
        emailMessage.ToIds = toRecipients.idList;
        emailMessage.ToAddress = String.join(toRecipients.addressList, ','); 
        Recipients ccRecipients = InboundEmailHelper.findRecipients(email.ccAddresses);
        emailMessage.CcIds = ccRecipients.idList;
        emailMessage.CcAddress = String.join(ccRecipients.addressList, ',');  
        
        System.debug('emailMessage: ' +emailMessage);

        insert emailMessage;

        // This is apparently needed  - it seems to not be enough to set the status at time of insert
        emailMessage.Status = '3'; // Sent
        update emailMessage;

        // Create relations
        // TODO: List<EmailMessageRelation> relations = createEmailMessageRelations(emailMessage, fromId, toIds, ccIds);
        // insert relations;
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

    private void validateParameters(Messaging.InboundEmail email, SObjectType sObjectType, SObjectField field){
        if(email == null) throw new InvalidParameterValueException('email', String.valueOf(email));
        if(sObjectType == null) throw new InvalidParameterValueException('sObjectType', String.valueOf(sObjectType));
        if(field == null) throw new InvalidParameterValueException('field', String.valueOf(field));
    }

    private String findReference(){
        String ref = InboundEmailHelper.findReference(email.plainTextBody, patternStart, patternEnd);
        if(String.isBlank(ref)){
            ref = InboundEmailHelper.findReference(email.htmlBody, patternStart, patternEnd);
        }

        return ref;
    }

    /*
    * Returns the reference or null if not found
    */ 
    @testVisible
    private static String findReference(String body, String patternStart, String patternEnd){
        
        String reference;

        // Find the first part of the pattern or exit early
        String substringAfterPatternStart = body.substringAfter(patternStart);
        System.debug(substringAfterPatternStart);
        if(!String.isBlank(substringAfterPatternStart)){
            reference = substringAfterPatternStart.substringBefore(patternEnd);
        }

        return reference;
    }

    @testVisible
    private static Recipients findRecipients(List<String> emailAddresses){

        // Search all person types by email
        List<List<SObject>> results = [FIND :String.join(emailAddresses, ' OR ') IN EMAIL FIELDS RETURNING User(Email), Contact(Email), Lead(Email)];

        // Map email addresses to person type Ids
        Map<String, List<Id>> addressesWithMatchingIds = new Map<String, List<Id>>();
        for (List<SObject> objects : results) {
           for (SObject obj : objects) {
                String emailAddress = (String) obj.get('Email');
                if(addressesWithMatchingIds.containsKey(emailAddress)){
                    addressesWithMatchingIds.get(emailAddress).add(obj.Id);
                }else {
                   addressesWithMatchingIds.put(emailAddress, new List<Id>{ obj.Id });
                }
           }
        }

        // Sort recipient email addresses based on whether the address had a matching record in any of the person types
        Recipients recipients = new Recipients();
        for (String emailAddress : emailAddresses) {
            if(addressesWithMatchingIds.containsKey(emailAddress)){
                recipients.idList.addAll(addressesWithMatchingIds.get(emailAddress));
            }else {
               recipients.addressList.add(emailAddress);
            }
        }

        return recipients;
    }

    @testVisible
    private static Datetime getMessageDate(List<Messaging.InboundEmail.Header> headers){
        return Datetime.now();
    }

    private List<Id> findToIds(List<String> toAddresses){
        return findIdFromEmailAddress(toAddresses);
    }

    

    private List<Id> findIdFromEmailAddress(List<String> emailAddresses){
        List<Id> idList = new List<Id>();
        idList.addAll(new Map<Id, SObject>([SELECT Id FROM User WHERE Email IN: emailAddresses]).keySet());
        idList.addAll(new Map<Id, SObject>([SELECT Id FROM Contact WHERE Email IN: emailAddresses]).keySet());
        idList.addAll(new Map<Id, SObject>([SELECT Id FROM Lead WHERE Email IN: emailAddresses]).keySet());

        System.debug('idList: ' +idList);

        return idList;
    }

    private Id findFromId(String fromAddress){
        List<Id> fromIds = new List<Id>();
        fromIds.addAll(new Map<Id, SObject>([SELECT Id FROM User WHERE Email =: fromAddress]).keySet());
        fromIds.addAll(new Map<Id, SObject>([SELECT Id FROM Contact WHERE Email =: fromAddress]).keySet());
        fromIds.addAll(new Map<Id, SObject>([SELECT Id FROM Lead WHERE Email =: fromAddress]).keySet());

        System.debug('toIds: ' +fromIds);

        return fromIds.isEmpty() ? null : fromIds.get(0);
    }

    private class Recipients {

        public List<Id> idList { get; private set; }
        public List<String> addressList { get; private set; }

        public Recipients(){
            idList = new List<Id>();
            addressList = new List<String>();
        }
    }

}
