global class TopDkExchangeInboundHandler implements Messaging.InboundEmailHandler {
    
    private static final String REF_START = 'ref:';
    private static final String REF_END = ':ref';

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Logger.LogTrace('Email received from: ' + envelope.fromAddress + ' to: ' + envelope.toAddress);
        Logger.logTrace('email:' + JSON.serializePretty(email));
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        try {   
            Id opptyId = findOpportunityId(email.plainTextBody);
            if(opptyId == null){
                Logger.logTrace('opptyId not found in plain text body');
                opptyId = findOpportunityId(email.htmlBody);
                if(opptyId == null){
                    Logger.logTrace('opptyId not found in html body');
                    Logger.emit();
                    return result;
                }
            }        

            // At this point we have a valid oppty Id
            List<Opportunity> opptys = [SELECT Id, Name FROM Opportunity WHERE Id =:opptyId];
            Logger.logTrace(JSON.serializePretty(opptys));
            
            
        } catch (Exception ex) {
           Logger.logException(ex);
        }finally {
            Logger.emit();
        }

        return result;
    }

    private Id findOpportunityId(String body){
        
        // Find the first part of the ref: pattern or exit early
        String substringAfterRefStart = body.substringAfter(REF_START);
        if(String.isBlank(substringAfterRefStart)){
            return null;
        }

        String substringBeforeRefEnd = substringAfterRefStart.substringBefore(REF_END);
        Id opptyId = Id.valueOf(substringBeforeRefEnd);
        Boolean isOpptyId = opptyId != null && opptyId.getSobjectType() == Opportunity.getSObjectType();
        if(!isOpptyId){
            return null;
        }

        return opptyId;
    }
}


