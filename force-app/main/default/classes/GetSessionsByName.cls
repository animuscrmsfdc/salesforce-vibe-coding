global with sharing class GetSessionsByName {

    global class Request {
        @InvocableVariable(label='Session Name' required=true description='Full or partial session name to search for.')
        public String sessionName;

        global Request() {}
    }

    global class SessionResult {
        @InvocableVariable(label='Session Id')
        public Id sessionId;

        @InvocableVariable(label='Session Name')
        public String name;

        @InvocableVariable(label='Start Date/Time')
        public Datetime startTime;

        @InvocableVariable(label='End Date/Time')
        public Datetime endTime;

        @InvocableVariable(label='Status')
        public String status;

        global SessionResult() {}
    }

    global class Response {
        @InvocableVariable(label='Sessions')
        public List<SessionResult> sessions;

        global Response() {}
    }

    @InvocableMethod(label='Get Sessions By Name' description='Returns all sessions in the future whose name contains the given search term. Use this to resolve a session name to its Id and scheduled time before calling GetSpeakerAvailability.')
    global static List<Response> getSessions(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            if (String.isBlank(req.sessionName)) {
                throw new IllegalArgumentException('GetSessionsByName: sessionName must not be blank');
            }
            String likePattern = '%' + req.sessionName.trim() + '%';
            List<SessionResult> matched = new List<SessionResult>();
            for (Session__c s : [
                SELECT Id, Name, Session_Date__c, End_Date__c, Status__c
                FROM Session__c
                WHERE Name LIKE :likePattern
                  AND Session_Date__c >= TODAY
                ORDER BY Session_Date__c ASC NULLS LAST
            ]) {
                SessionResult sr = new SessionResult();
                sr.sessionId = s.Id;
                sr.name = s.Name;
                sr.startTime = s.Session_Date__c;
                sr.endTime = s.End_Date__c;
                sr.status = s.Status__c;
                matched.add(sr);
            }
            Response res = new Response();
            res.sessions = matched;
            responses.add(res);
        }
        return responses;
    }
}
