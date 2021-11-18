public with sharing class Profiler {
    // usageMap is used to house the running totals of limit usage and is the source
    // of the final numbers for limit usage.
    Map<String, Double> usageMap;

    // instanceMap is used to track the limit usage during a DomainLogicHandler segment
    // i.e. check(newObj), check(newObj, oldObj), and processRecords()
    // instanceMap is then added to the the usageMap at the end of the segment execution.
    Map<String, Double> instanceMap;

    // allowanceMap is an ease-of-reference data structure that stores the the allowed
    // limits.
    Map<String, Double> allowanceMap;

    List<Double> levels;
    String className;
    String transactionId = TransactionManager.getTransactionId();
    String objectId;
    Id logRecordTypeId = Log__c.getSObjectType()
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Limit Profile')
        .getRecordTypeId();

    public Profiler(String className) {
        init(className);
    }

    public void startTracking() {
        this.instanceMap = getCurrentLimits();
    }

    public Limit_Profile__e process() {
        updateUsage();

        Log__c log = new Log__c(
            RecordTypeId = logRecordTypeId,
            Queries_Used__c = usageMap.get('Queries'),
            Query_Rows_Used__c = usageMap.get('Query Rows'),
            DML_Used__c = usageMap.get('DML Statements'),
            DML_Rows_Used__c = usageMap.get('DML Rows'),
            CPU_Used__c = usageMap.get('CPU Time'),
            Heap_Used__c = usageMap.get('Heap Usage'),
            Severity__c = 'Info',
            Source__c = className,
            Running_User__c = UserInfo.getUserId(),
            Transaction_Id__c = transactionId,
            Object_Id__c = objectId
        );
        return new Limit_Profile__e(Log_JSON__c = JSON.serialize(log));
    }

    public void publish(DomainHandlerUtility handler) {
        List<Limit_Profile__e> events = new List<Limit_Profile__e>{
            process()
        };
        events.addAll(handler.getLimitProfileEvents());
        Eventbus.publish(events);
    }

    public void updateUsage() {
        calcDelta();
        for (String key : usageMap.keySet()) {
            Double instanceValue = instanceMap.get(key);
            Double usageValue = usageMap.get(key) + instanceValue;
            usageMap.put(key, usageValue);
        }
    }

    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    public void setObjectId(String objectId) {
        this.objectId = objectId;
    }

    void init(String className) {
        this.className = className;
        this.instanceMap = getCurrentLimits();
        zeroMap();
        setAllowanceMap();
    }

    void zeroMap() {
        this.usageMap = new Map<String, Double>{
            'Queries' => 0,
            'Query Rows' => 0,
            'DML Statements' => 0,
            'DML Rows' => 0,
            'CPU Time' => 0,
            'Heap Usage' => 0
        };
    }

    void calcDelta() {
        Map<String, Double> m = getCurrentLimits();
        for (String key : m.keySet()) {
            Double instanceValue = instanceMap.get(key);
            Double currentValue = m.get(key);
            Double delta = currentValue - instanceValue;
            instanceMap.put(key, delta);
        }
    }

    Map<String, Double> getCurrentLimits() {
        return new Map<String, Double>{
            'Queries' => Limits.getQueries(),
            'Query Rows' => Limits.getQueryRows(),
            'DML Statements' => Limits.getDmlStatements(),
            'DML Rows' => Limits.getDmlRows(),
            'CPU Time' => Limits.getCpuTime(),
            'Heap Usage' => Limits.getHeapSize()
        };
    }

    void setAllowanceMap() {
        allowanceMap = new Map<String, Double>{
            'Queries' => Limits.getLimitQueries(),
            'Query Rows' => Limits.getLimitQueryRows(),
            'DML Statements' => Limits.getLimitDmlStatements(),
            'DML Rows' => Limits.getLimitDmlRows(),
            'CPU Time' => Limits.getLimitCpuTime(),
            'Heap Usage' => Limits.getLimitHeapSize()
        };
    }
}