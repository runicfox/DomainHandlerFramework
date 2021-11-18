public with sharing class TransactionManager {
    /**
     * This class' test coverage is found in ProfilerTest
     */
    static String transactionId;

    public static String getTransactionId() {
        transactionId = transactionId == null ? GuidUtility.generateGuid() : transactionId;
        return transactionId;
    }
    
}