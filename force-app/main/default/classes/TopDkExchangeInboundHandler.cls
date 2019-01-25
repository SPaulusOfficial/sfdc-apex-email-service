global class TopDkExchangeInboundHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        System.debug('Email received from: ' + envelope.fromAddress + ' to: ' + envelope.toAddress);
        System.debug('email:' + email);
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        try {   
            InboundEmailHelper helper = new InboundEmailHelper(email, Opportunity.SObjectType, Opportunity.Id);
            helper.buildEmailMessage();
        } catch (Exception ex) {
           System.debug(LoggingLevel.ERROR, ex);
        }

        return result;
    }
}


