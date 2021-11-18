public with sharing class LimitProfilerLogTest {
    static Map<String, Double> thresholdMap = new Map<String, Double>();
    static Double coefficient = 0.75;

    public static void checkLimits(Double coefficientOverride) {
        coefficient = coefficientOverride;
        checkLimits();
    }

    public static void checkLimits() {
        setThresholdMap();
        process();
    }

    static void process() {
        List<Log__c> logs = [
            SELECT
                Id,
                Source__c,
                DML_Used__c,
                DML_Rows_Used__c,
                Queries_Used__c,
                Query_Rows_Used__c,
                CPU_Used__c,
                Heap_Used__c
            FROM Log__c
            WHERE RecordType.Name = 'Limit Profile'
        ];

        if (logs.isEmpty()) {
            throw new LimitProfilerException(
                'No Limit Profile was generated in the Log__c object.'
            );
        }

        for (Log__c log : logs) {
            for (String limitField : thresholdMap.keySet()) {
                Double threshold = Double.valueOf(thresholdMap.get(limitField));
                Integer used = Integer.valueOf(log.get(limitField));
                if (used > threshold) {
                    throw new LimitProfilerException(
                        log.Source__c +
                        ' process exceeded ' + String.valueOf(coefficient * 100) + '% usage of ' +
                        limitField +
                        ' (' +
                        used +
                        ')'
                    );
                }
            }
        }
    }

    static void setThresholdMap() {
        thresholdMap = new Map<String, Double>{
            'DML_Used__c' => Limits.getLimitDmlStatements() * coefficient,
            'DML_Rows_Used__c' => Limits.getLimitDmlRows() * coefficient,
            'Queries_Used__c' => Limits.getLimitQueries() * coefficient,
            'Query_Rows_Used__c' => Limits.getLimitQueryRows() * coefficient,
            'Heap_Used__c' => Limits.getLimitHeapSize() * coefficient,
            'CPU_Used__c' => Limits.getLimitCpuTime() * coefficient
        };
    }

    class LimitProfilerException extends Exception {
    }
}