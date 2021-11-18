trigger AccountTrigger on Account(after update) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}
