trigger LimitProfileEventSubscriber on Limit_Profile__e (after insert) {
    LimitProfileEventProcessor.process(Trigger.new);
}