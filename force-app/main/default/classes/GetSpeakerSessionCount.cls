global with sharing class GetSpeakerSessionCount {

    global class CandidateSpeaker {
        @InvocableVariable(label='Candidate Speaker Id')
        public Id speakerId;
        @InvocableVariable(label='Candidate Full Name')
        public String fullName;
        @InvocableVariable(label='Candidate Email')
        public String email;
        global CandidateSpeaker() {}
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
        @InvocableVariable(label='Session Count')
        public Integer sessionCount;
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
        }
    }

    @InvocableMethod(label='Get Speaker Session Count' description='Returns the session count for a Speaker, resolved by Id, email, full name, first name, or last name. When multiple speakers match, returns candidates for the user to choose from.')
    global static List<Response> getSessionCounts(List<Request> requests) {
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
                    res.errorMessage = 'No speaker found matching "' + (String.isNotBlank(req.email) ? req.email.trim() : term) + '". Please try a different name or email.';
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
            Map<Id, Integer> countBySpeaker = new Map<Id, Integer>();
            for (Id sid : speakerIds) {
                countBySpeaker.put(sid, 0);
            }
            for (AggregateResult ar : [
                SELECT Speaker__c, COUNT(Id) cnt
                FROM Session_Speaker__c
                WHERE Speaker__c IN :speakerIds
                WITH USER_MODE
                GROUP BY Speaker__c
            ]) {
                countBySpeaker.put((Id) ar.get('Speaker__c'), (Integer) ar.get('cnt'));
            }
            for (Response res : responses) {
                if (res.errorMessage == null && !res.isAmbiguous && res.speakerId != null) {
                    res.sessionCount = countBySpeaker.get(res.speakerId);
                }
            }
        }

        return responses;
    }

    private static List<Speaker__c> lookupSpeakers(Request req, String term) {
        if (String.isNotBlank(req.email)) {
            String val = req.email.trim();
            return [SELECT Id, First_Name__c, Last_Name__c, Email__c
                    FROM Speaker__c WHERE Email__c = :val WITH USER_MODE];
        }
        List<List<SObject>> results = [FIND :term IN ALL FIELDS
                                       RETURNING Speaker__c(Id, First_Name__c, Last_Name__c, Email__c)];
        return (List<Speaker__c>) results[0];
    }

    private static String buildSearchTerm(Request req) {
        if (String.isNotBlank(req.fullName)) return req.fullName.trim();
        List<String> parts = new List<String>();
        if (String.isNotBlank(req.firstName)) parts.add(req.firstName.trim());
        if (String.isNotBlank(req.lastName))  parts.add(req.lastName.trim());
        return String.join(parts, ' ');
    }

    private static List<CandidateSpeaker> toCandidates(List<Speaker__c> speakers) {
        List<CandidateSpeaker> result = new List<CandidateSpeaker>();
        for (Speaker__c s : speakers) {
            CandidateSpeaker c = new CandidateSpeaker();
            c.speakerId = s.Id;
            c.fullName  = s.First_Name__c + ' ' + s.Last_Name__c;
            c.email     = s.Email__c;
            result.add(c);
        }
        return result;
    }
}
