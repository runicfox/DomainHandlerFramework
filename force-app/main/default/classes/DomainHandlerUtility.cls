public with sharing class DomainHandlerUtility {
    List<Limit_Profile__e> limitProfileEvents = new List<Limit_Profile__e>();
    List<DomainLogicHandler> handlers;
    String triggerEvent = Trigger.operationType.name();
    Map<DomainLogicHandler, Profiler> domainProfilers = new Map<DomainLogicHandler, Profiler>();

    public DomainHandlerUtility() {
        setDomainHandlers();
    }

    public void process() {
        String dml = triggerEvent.split('_')[1];
        switch on dml {
            when 'INSERT' {
                processInsert();
            }
            when 'UPDATE' {
                processUpdate();
            }
            when 'DELETE' {
                processDelete();
            }
        }

        processHandlers();
    }

    public List<Limit_Profile__e> getLimitProfileEvents() {
        return limitProfileEvents;
    }

    void processInsert() {
        for (SObject newObj : Trigger.new) {
            for (DomainLogicHandler handler : handlers) {
                domainProfilers.get(handler)?.startTracking();
                handler.check(newObj);
                domainProfilers.get(handler)?.updateUsage();
            }
        }
    }

    void processUpdate() {
        for (SObject newObj : Trigger.new) {
            SObject oldObj = Trigger.oldMap.get(newObj.Id);
            for (DomainLogicHandler handler : handlers) {
                domainProfilers.get(handler)?.startTracking();
                handler.check(newObj, oldObj);
                domainProfilers.get(handler)?.updateUsage();
            }
        }
    }

    void processDelete() {
        for (SObject oldObj : Trigger.old) {
            for (DomainLogicHandler handler : handlers) {
                domainProfilers.get(handler)?.startTracking();
                handler.check(oldObj);
                domainProfilers.get(handler)?.updateUsage();
            }
        }
    }

    void processHandlers() {
        for (DomainLogicHandler handler : handlers) {
            domainProfilers.get(handler)?.startTracking();
            handler.processRecords();
            limitProfileEvents.add(domainProfilers.get(handler)?.process());
        }

        Eventbus.publish(limitProfileEvents);
    }

    void setDomainHandlers() {
        String sobjectName = getSObjectName();
        List<Domain_Handler__mdt> domainHandlers = [
            SELECT Label, Handler_Class__c, Trigger_Event__c, Profile_Limits__c
            FROM Domain_Handler__mdt
            WHERE
                SObject_Name__c = :sobjectName
                AND Trigger_Event__c = :triggerEvent
                AND Active__c = TRUE
        ];

        handlers = new List<DomainLogicHandler>();
        for (Domain_Handler__mdt domainHandler : domainHandlers) {
            Type myType = Type.forName(domainHandler.Handler_Class__c);
            if (myType != null) {
                DomainLogicHandler handler = (DomainLogicHandler) myType.newInstance();
                handlers.add(handler);
                if (domainHandler.Profile_Limits__c) {
                    domainProfilers.put(
                        handler,
                        new Profiler(domainHandler.Label)
                    );
                }
            }
        }
    }

    String getSObjectName() {
        SObject sobj = Trigger.new == null ? Trigger.old[0] : Trigger.new[0];
        return sobj.getSobjectType().getDescribe().getName();
    }
}
