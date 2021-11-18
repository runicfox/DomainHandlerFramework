trigger LogTrigger on Log__c(after insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}