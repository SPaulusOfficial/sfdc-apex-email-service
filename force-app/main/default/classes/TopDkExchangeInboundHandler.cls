global class TopDkExchangeInboundHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Logger.LogTrace('Email received from: ' + envelope.fromAddress + ' to: ' + envelope.toAddress);
        Logger.logTrace('email:' + JSON.serializePretty(email));
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        try {   
            InboundEmailHelper helper = new InboundEmailHelper(email, Opportunity.SObjectType, Opportunity.Id);
            helper.buildEmailMessage();

            // Logger.logTrace('Inbound email did not contain a reference pattern matching What was configured. Exiting.');
            // Logger.logTrace('Reference pattern found - emailMessage: ' + JSON.serializePretty(emailMessage));
            
        } catch (Exception ex) {
           Logger.logException(ex);
        }finally {
            Logger.emit();
        }

        return result;
    }
}


