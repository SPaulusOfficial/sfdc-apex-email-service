@isTest
private class InboundEmailHelperTest {
    
    
    /***************** findReference() tests start ***************************/ 
    @isTest static void findsReference(){
        String body = 'dawhuihduiahwd wudhai dwahdihfhi ref:djaowdjioawjio:ref dwbaybdwuabdu';
        String expected = 'djaowdjioawjio';
        testfindsReference(body, expected);
    }

    @isTest static void findsReference2(){
        String body = 'ref:djaowdjioawjio:refdawhuihduiahwd wudhai dwahdihfhi dwbaybdwuabdu';
        String expected = 'djaowdjioawjio';
        testfindsReference(body, expected);
    }

    @isTest static void findsReference3(){
        String body = 'dawhuihduiahwd ref::refwudhai dwahdihfhi dwbaybdwuabdu';
        String expected = '';
        testfindsReference(body, expected);
    }

    @isTest static void findsReference4(){
        String body = 'dawhuihduiahwd ref:wudhai dwahdihfhi dwbaybdwuabdu';
        String expected = 'wudhai dwahdihfhi dwbaybdwuabdu';
        testfindsReference(body, expected);
    }

    @isTest static void findsReference5(){
        String body = 'dawhuihduiahwdwudhai dwahdihfhi dwbaybdwuabdu';
        String expected = null;
        testfindsReference(body, expected);
    }

    private static void testfindsReference(String body, String expected){
        String patternStart = 'ref:';
        String patternEnd = ':ref';
        String reference = InboundEmailHelper.findReference(body, patternStart, patternEnd);
        System.assertEquals(expected, reference);
    }

    /***************** findReference() tests end ***************************/

    @isTest static void testValidateParameters_NullParams(){
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

    @isTest static void testValidateParameters_ParamsOk(){
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

    @isTest static void testGetMessageDate(){
        String jsonString = '[{"value":"rasmuszimmernielsen@gmail.com","name":"Return-Path"},{"value":"Thu, 24 Jan 2019 16:01:43 +0100","name":"Date"}]';
        List<Messaging.InboundEmail.Header> headers = (List<Messaging.InboundEmail.Header>) JSON.deserialize(jsonString, List<Messaging.InboundEmail.Header>.class);
        Datetime expectedDate = Datetime.valueOf('Thu, 24 Jan 2019 16:01:43 +0100');
        Datetime messageDate = InboundEmailHelper.getMessageDate(headers);

        System.assertEquals(expectedDate, messageDate);
    }
}
