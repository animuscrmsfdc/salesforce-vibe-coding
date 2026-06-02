public with sharing class GetSpeakerSessionCount {

    public class Request {
        @InvocableVariable(label='Speaker Id' required=true)
        public Id speakerId;
    }

    public class Response {
        @InvocableVariable(label='Session Count')
        public Integer sessionCount;
    }

    @InvocableMethod(label='Get Speaker Session Count' description='Returns the number of Session_Speaker__c records associated with each Speaker.')
    public static List<Response> getSessionCounts(List<Request> requests) {
        Set<Id> speakerIds = new Set<Id>();
        for (Request req : requests) {
            if (req.speakerId == null) {
                throw new IllegalArgumentException('GetSpeakerSessionCount: speakerId must not be null');
            }
            speakerIds.add(req.speakerId);
        }

        Map<Id, Integer> countBySpeaker = new Map<Id, Integer>();
        for (Id sid : speakerIds) {
            countBySpeaker.put(sid, 0);
        }

        for (AggregateResult ar : [
            SELECT Speaker__c, COUNT(Id) cnt
            FROM Session_Speaker__c
            WHERE Speaker__c IN :speakerIds
            GROUP BY Speaker__c
        ]) {
            countBySpeaker.put((Id) ar.get('Speaker__c'), (Integer) ar.get('cnt'));
        }

        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            res.sessionCount = countBySpeaker.get(req.speakerId);
            System.debug('GetSpeakerSessionCount — speakerId=' + req.speakerId + ' sessionCount=' + res.sessionCount);
            responses.add(res);
        }
        return responses;
    }
}
