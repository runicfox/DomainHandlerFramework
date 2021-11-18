public with sharing class LimitProfileEventProcessor {
    public static void process(List<Limit_Profile__e> events) {
        List<Log__c> logs = new List<Log__c>();

        for(Limit_Profile__e event : events) {
            Log__c log = (Log__c)JSON.deserialize(event.Log_JSON__c, Log__c.class);
            logs.add(log);
        }

        insert logs;
    }
}