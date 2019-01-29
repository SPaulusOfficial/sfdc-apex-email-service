@isTest
private class InboundEmailHelperTest {
    
    
    /***************** findReference() tests start ***************************/ 
    
    @isTest static void test_findsReference(){
        String plainTextBody = 'dawhuihduiahwd wudhai dwahdihfhi ref:djaowdjioawjio:ref dwbaybdwuabdu';
        String htmlBody = '';
        String expected = 'djaowdjioawjio';
        findsReferenceTestHelper(plainTextBody, htmlBody, expected);
    }

    @isTest static void test_findsReference2(){
        String plainTextBody = 'ref:djaowdjioawjio:refdawhuihduiahwd wudhai dwahdihfhi dwbaybdwuabdu';
        String htmlBody = '';
        String expected = 'djaowdjioawjio';
        findsReferenceTestHelper(plainTextBody, htmlBody, expected);
    }

    @isTest static void test_findsReference3(){
        String plainTextBody = 'dawhuihduiahwd ref::refwudhai dwahdihfhi dwbaybdwuabdu';
        String htmlBody = 'dawhuihduiahwd ref::refwudhai dwahdihfhi dwbaybdwuabdu';
        String expected = '';
        findsReferenceTestHelper(plainTextBody, htmlBody, expected);
    }

    @isTest static void test_findsReference4(){
        String plainTextBody = 'dawhuihduiahwd ref:wudhai dwahdihfhi dwbaybdwuabdu';
        String htmlBody = '';
        String expected = 'wudhai dwahdihfhi dwbaybdwuabdu';
        findsReferenceTestHelper(plainTextBody, htmlBody, expected);
    }

    @isTest static void test_findsReference5(){
        String plainTextBody = 'dawhuihduiahwdwudhai dwahdihfhi dwbaybdwuabdu';
        String htmlBody = '';
        String expected = null;
        findsReferenceTestHelper(plainTextBody, htmlBody, expected);
    }

    @isTest static void test_findsReference_AlsoFindsInHtmlBody(){
        String plainTextBody = 'dawhuihduiahwdwudhai dwahdihfhi dwbaybdwuabdu';
        String htmlBody = 'dawhuihduiahwd ref:dwawd:refwudhai';
        String expected = 'dwawd';
        findsReferenceTestHelper(plainTextBody, htmlBody, expected);
    }

    private static void findsReferenceTestHelper(String plainTextBody, String htmlBody, String expected){
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = plainTextBody;
        email.htmlBody = htmlBody;
        InboundEmailHelper helper = new InboundEmailHelper(email);
        String patternStart = 'ref:';
        String patternEnd = ':ref';
        String reference = helper.findReference(email);
        System.assertEquals(expected, reference);
    }

    /***************** findReference() tests end ***************************/

    @isTest static void test_ValidateParameters_NullParams(){
        Messaging.InboundEmail email;
        SObjectType sobjType;
        SObjectField sobjField;

        try {
            InboundEmailHelper helper = new InboundEmailHelper(email, sobjType, sobjField);
            System.assert(false, 'InboundEmailHelper must not accept null params.');
        } catch (InvalidParameterValueException ex) {
            System.assert(true);
        }
    }

    @isTest static void test_ValidateParameters_ParamNotFilterable(){
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        SObjectType sobjType = Opportunity.SObjectType;
        SObjectField sobjField = Opportunity.Description; // Not filterable

        try {
            InboundEmailHelper helper = new InboundEmailHelper(email, sobjType, sobjField);
            System.assert(false, 'InboundEmailHelper must not accept unfilterable fields.');
        } catch (InvalidParameterValueException ex) {
            System.assert(true);
        }
    }

    @isTest static void test_ValidateParameters_ParamsOk(){
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        SObjectType sobjType = Opportunity.SObjectType;
        SObjectField sobjField = Opportunity.Id;

        try {
            InboundEmailHelper helper = new InboundEmailHelper(email, sobjType, sobjField);
            System.assert(true);
        } catch (InvalidParameterValueException ex) {
            System.assert(false, ex.getMessage());
        }
    }

    @isTest static void test_GetMessageDate(){
        String jsonString = '[{"value":"rasmuszimmernielsen@gmail.com","name":"Return-Path"},{"value":"Thu, 24 Jan 2019 16:01:43 +0100","name":"Date"}]';
        List<Messaging.InboundEmail.Header> headers = (List<Messaging.InboundEmail.Header>) JSON.deserialize(jsonString, List<Messaging.InboundEmail.Header>.class);
        Datetime expectedDate = Datetime.now();
        InboundEmailHelper helper = new InboundEmailHelper();
        Datetime messageDate = helper.getMessageDate(headers);

        System.assertEquals(expectedDate.format(), messageDate.format());
    }

    @isTest static void test_SearchEmailAddresses(){
        Contact c = new Contact(LastName = 'testContact', Email = 'test@test.com');
        insert c;
        
        Lead l = new Lead(LastName = 'testLead', Email = 'test@test.com', Company = 'testCompany');
        insert l;

        Contact c2 = new Contact(LastName = 'testContact2', Email = 'test@test2.com');
        insert c2;

        User u = createTestUser('testUser', 'test@test.com', 'randomtest@test.com');
        insert u;

        InboundEmailHelper helper = new InboundEmailHelper();
        InboundEmailHelper.EmailAddressSearchResult result = helper.searchEmailAddresses(new List<String>{ c.Email, l.Email, c2.Email, u.Email, 'emailnotinsalesforce@test.com' });

        System.assertEquals(4, result.idList.size());
        System.assert(result.idList.contains(c.Id));
        System.assert(result.idList.contains(l.Id));
        System.assert(result.idList.contains(c2.Id));
        System.assert(result.idList.contains(u.Id));
        System.assertEquals(1, result.addressList.size());
        System.assert(result.addressList.contains('emailnotinsalesforce@test.com'));
    }

    @isTest static void test_findRelatedToId_OpportunityStageName(){
        InboundEmailHelper helper = new InboundEmailHelper();
        Opportunity oppty = createOpportunity('testOpp');
        oppty.NextStep = 'testStep';
        insert oppty;

        Id expected = oppty.Id;
        Id actual = helper.findRelatedToId('testStep', Opportunity.SObjectType, Opportunity.NextStep);
        System.assertEquals(expected, actual);
    }

    @isTest static void test_findRelatedToId_OpportunityId(){
        InboundEmailHelper helper = new InboundEmailHelper();
        Opportunity oppty = createOpportunity('testOpp');
        insert oppty;

        Id expected = oppty.Id;
        Id actual = helper.findRelatedToId(expected, Opportunity.SObjectType, Opportunity.Id);
        System.assertEquals(expected, actual);
    }

    @isTest static void test_findRelatedToId_Account(){
        InboundEmailHelper helper = new InboundEmailHelper();
        Account acc = new Account(Name = 'testAcc', Sic = 'testSic');
        insert acc;

        Id expected = acc.Id;
        Id actual = helper.findRelatedToId('testSic', Account.SObjectType, Account.Sic);
        System.assertEquals(expected, actual);
    }

    @isTest static void test_findRelatedToId_ReturnsNullIfRecordNotFound(){
        InboundEmailHelper helper = new InboundEmailHelper();
        Account acc = new Account(Name = 'testAcc', Sic = 'testSic');
        insert acc;

        Id expected = null;
        Id actual = helper.findRelatedToId('dank', Account.SObjectType, Account.Sic);
        System.assertEquals(expected, actual);
    }

    @isTest static void test_findRelatedToId_FindsAmongMultiple(){
        InboundEmailHelper helper = new InboundEmailHelper();
        Account acc = new Account(Name = 'testAcc', Sic = 'testSic');
        insert acc;
        Account acc2 = new Account(Name = 'testAcc2', Sic = 'testSic2');
        insert acc2;
        Account acc3 = new Account(Name = 'testAcc3', Sic = 'testSic3');
        insert acc3;

        Id expected = acc2.Id;
        Id actual = helper.findRelatedToId('testSic2', Account.SObjectType, Account.Sic);
        System.assertEquals(expected, actual);
    }

    /******************************* HELPERS *************************************************************/

    private static User createTestUser(String lastName, String emailAddress, String userName){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email=emailAddress, 
            EmailEncodingKey='UTF-8', LastName=lastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName=userName
        );

        return u;
    }

    private static Opportunity createOpportunity(String name){
        Opportunity oppty = new Opportunity(
            Name = name,
            StageName = 'lol',
            CloseDate = Date.today().addDays(1)
        );

        return oppty;
    }
}
