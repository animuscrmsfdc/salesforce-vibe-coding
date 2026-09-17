global with sharing class GetSpeakerSessions {

    global class CandidateSpeaker {
        @InvocableVariable(label='Candidate Speaker Id')
        public Id speakerId;
        @InvocableVariable(label='Candidate Speaker Number')
        public String speakerNumber;
        @InvocableVariable(label='Candidate Full Name')
        public String fullName;
        @InvocableVariable(label='Candidate Email')
        public String email;
        global CandidateSpeaker() {}
    }

    global class SessionItem {
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
        @InvocableVariable(label='Role')
        public String role;
        global SessionItem() {}
    }

    global class Request {
        @InvocableVariable(label='Speaker Id')
        public Id speakerId;
        @InvocableVariable(label='Speaker First Name')
        public String firstName;
        @InvocableVariable(label='Speaker Last Name')
        public String lastName;
        @InvocableVariable(label='Speaker Full Name')
        public String fullName;
        @InvocableVariable(label='Speaker Email')
        public String email;
        global Request() {}
    }

    global class Response {
        @InvocableVariable(label='Sessions')
        public List<SessionItem> sessions;
        @InvocableVariable(label='Resolved Speaker Id')
        public Id speakerId;
        @InvocableVariable(label='Is Ambiguous')
        public Boolean isAmbiguous;
        @InvocableVariable(label='Candidates')
        public List<CandidateSpeaker> candidates;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        global Response() {
            this.isAmbiguous = false;
            this.candidates  = new List<CandidateSpeaker>();
            this.sessions    = new List<SessionItem>();
        }
    }

    @InvocableMethod(label='Get Speaker Sessions' description='Returns the list of sessions assigned to a speaker, resolved by Id, email, full name, first name, or last name. When multiple speakers match, returns candidates for disambiguation.')
    global static List<Response> getSpeakerSessions(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();

            if (req.speakerId != null) {
                res.speakerId = req.speakerId;
            } else {
                String term = buildSearchTerm(req);
                if (String.isBlank(term) && String.isBlank(req.email)) {
                    res.errorMessage = 'Please provide a speaker name or email to search.';
                    responses.add(res);
                    continue;
                }

                List<Speaker__c> matches = lookupSpeakers(req, term);
                if (matches.isEmpty()) {
                    String searched = String.isNotBlank(req.email) ? req.email.trim() : term;
                    res.errorMessage = 'No speaker found matching "' + searched + '". Here are the 10 most recently updated speakers — pick one and try again.';
                    res.candidates = getRecentSpeakers();
                    responses.add(res);
                    continue;
                }
                if (matches.size() == 1) {
                    res.speakerId = matches[0].Id;
                } else {
                    res.isAmbiguous = true;
                    res.candidates  = toCandidates(matches);
                }
            }

            responses.add(res);
        }

        Set<Id> speakerIds = new Set<Id>();
        for (Response res : responses) {
            if (res.errorMessage == null && !res.isAmbiguous && res.speakerId != null) {
                speakerIds.add(res.speakerId);
            }
        }

        if (!speakerIds.isEmpty()) {
            Map<Id, List<SessionItem>> sessionsBySpeaker = new Map<Id, List<SessionItem>>();
            for (Id sid : speakerIds) {
                sessionsBySpeaker.put(sid, new List<SessionItem>());
            }
            for (Session_Speaker__c ss : [
                SELECT Speaker__c, Role__c,
                       Session__r.Id, Session__r.Name,
                       Session__r.Session_Date__c, Session__r.End_Date__c,
                       Session__r.Status__c
                FROM Session_Speaker__c
                WHERE Speaker__c IN :speakerIds
                WITH USER_MODE
                ORDER BY Session__r.Session_Date__c ASC NULLS LAST
            ]) {
                SessionItem item = new SessionItem();
                item.sessionId = ss.Session__r.Id;
                item.name      = ss.Session__r.Name;
                item.startTime = ss.Session__r.Session_Date__c;
                item.endTime   = ss.Session__r.End_Date__c;
                item.status    = ss.Session__r.Status__c;
                item.role      = ss.Role__c;
                sessionsBySpeaker.get(ss.Speaker__c).add(item);
            }
            for (Response res : responses) {
                if (res.errorMessage == null && !res.isAmbiguous && res.speakerId != null) {
                    res.sessions = sessionsBySpeaker.get(res.speakerId);
                }
            }
        }

        return responses;
    }

    private static List<Speaker__c> lookupSpeakers(Request req, String term) {
        if (String.isNotBlank(req.email)) {
            String val = req.email.trim();
            return [SELECT Id, Name, First_Name__c, Last_Name__c, Email__c
                    FROM Speaker__c WHERE Email__c = :val WITH USER_MODE];
        }
        if (String.isNotBlank(req.firstName) && String.isNotBlank(req.lastName)) {
            String fn = req.firstName.trim() + '%';
            String ln = req.lastName.trim() + '%';
            return [SELECT Id, Name, First_Name__c, Last_Name__c, Email__c
                    FROM Speaker__c WHERE First_Name__c LIKE :fn AND Last_Name__c LIKE :ln WITH USER_MODE];
        }
        if (String.isNotBlank(req.firstName)) {
            String fn = req.firstName.trim() + '%';
            return [SELECT Id, Name, First_Name__c, Last_Name__c, Email__c
                    FROM Speaker__c WHERE First_Name__c LIKE :fn WITH USER_MODE];
        }
        if (String.isNotBlank(req.lastName)) {
            String ln = req.lastName.trim() + '%';
            return [SELECT Id, Name, First_Name__c, Last_Name__c, Email__c
                    FROM Speaker__c WHERE Last_Name__c LIKE :ln WITH USER_MODE];
        }
        List<List<SObject>> results = [FIND :term IN ALL FIELDS
                                       RETURNING Speaker__c(Id, Name, First_Name__c, Last_Name__c, Email__c)];
        return (List<Speaker__c>) results[0];
    }

    private static String buildSearchTerm(Request req) {
        if (String.isNotBlank(req.fullName)) return req.fullName.trim();
        List<String> parts = new List<String>();
        if (String.isNotBlank(req.firstName)) parts.add(req.firstName.trim());
        if (String.isNotBlank(req.lastName))  parts.add(req.lastName.trim());
        return String.join(parts, ' ');
    }

    private static List<CandidateSpeaker> getRecentSpeakers() {
        return toCandidates([
            SELECT Id, Name, First_Name__c, Last_Name__c, Email__c
            FROM Speaker__c
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
            LIMIT 10
        ]);
    }

    private static List<CandidateSpeaker> toCandidates(List<Speaker__c> speakers) {
        List<CandidateSpeaker> result = new List<CandidateSpeaker>();
        for (Speaker__c s : speakers) {
            CandidateSpeaker c = new CandidateSpeaker();
            c.speakerId     = s.Id;
            c.speakerNumber = s.Name;
            c.fullName      = s.First_Name__c + ' ' + s.Last_Name__c;
            c.email         = s.Email__c;
            result.add(c);
        }
        return result;
    }
}
