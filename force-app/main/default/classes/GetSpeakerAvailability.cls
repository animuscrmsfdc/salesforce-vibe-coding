global with sharing class GetSpeakerAvailability {

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

    global class Request {
        @InvocableVariable(label='Speaker Id' description='Provide Speaker Id or speaker name fields, not both.')
        public Id speakerId;
        @InvocableVariable(label='Speaker First Name')
        public String firstName;
        @InvocableVariable(label='Speaker Last Name')
        public String lastName;
        @InvocableVariable(label='Speaker Full Name')
        public String fullName;
        @InvocableVariable(label='Speaker Email')
        public String email;

        @InvocableVariable(label='Start Date/Time' description='Provide Start Date/Time or Session Name, not both.')
        public Datetime startTime;
        @InvocableVariable(label='End Date/Time')
        public Datetime endTime;
        @InvocableVariable(label='Session Name' description='Name (or partial name) of a future session. Used to infer the time window when Start Date/Time is not known.')
        public String sessionName;

        global Request() {}
    }

    global class Response {
        @InvocableVariable(label='Is Available')
        public Boolean isAvailable;
        @InvocableVariable(label='Conflicting Session Id')
        public Id conflictingSessionId;
        @InvocableVariable(label='Conflicting Session Name')
        public String conflictingSessionName;
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

    @InvocableMethod(label='Get Speaker Availability' description='Checks whether a Speaker is free for a candidate session time window. Speaker can be identified by name or email; session can be identified by name or by explicit start/end time.')
    global static List<Response> checkAvailability(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Integer i = 0; i < requests.size(); i++) {
            responses.add(new Response());
        }

        // Phase 1 — resolve speakers by name/email when speakerId is not provided.
        Map<Integer, Id> resolvedSpeakerId = new Map<Integer, Id>();
        for (Integer i = 0; i < requests.size(); i++) {
            Request req = requests[i];
            if (req.speakerId != null) {
                resolvedSpeakerId.put(i, req.speakerId);
                continue;
            }
            String term = buildSearchTerm(req);
            if (String.isBlank(term) && String.isBlank(req.email)) {
                responses[i].errorMessage = 'Provide a speaker name, email, or Speaker Id.';
                continue;
            }
            List<Speaker__c> matches = lookupSpeakers(req, term);
            if (matches.isEmpty()) {
                String searched = String.isNotBlank(req.email) ? req.email.trim() : term;
                responses[i].errorMessage = 'No speaker found matching "' + searched + '". Here are the 10 most recently updated speakers — pick one and try again.';
                responses[i].candidates = getRecentSpeakers();
            } else if (matches.size() == 1) {
                resolvedSpeakerId.put(i, matches[0].Id);
            } else {
                responses[i].isAmbiguous = true;
                responses[i].candidates  = toCandidates(matches);
            }
        }

        // Phase 2 — resolve session names to start/end times when startTime is not provided.
        Map<String, List<Session__c>> sessionsByNormalizedName = new Map<String, List<Session__c>>();
        Map<Integer, Datetime> resolvedStartTime = new Map<Integer, Datetime>();
        Map<Integer, Datetime> resolvedEndTime   = new Map<Integer, Datetime>();

        for (Integer i = 0; i < requests.size(); i++) {
            if (responses[i].errorMessage != null || responses[i].isAmbiguous) continue;
            Request req = requests[i];
            if (req.startTime != null) {
                resolvedStartTime.put(i, req.startTime);
                resolvedEndTime.put(i, req.endTime);
                continue;
            }
            if (String.isBlank(req.sessionName)) {
                responses[i].errorMessage = 'Provide a Start Date/Time or a Session Name.';
                continue;
            }
            String key = req.sessionName.trim().toLowerCase();
            if (!sessionsByNormalizedName.containsKey(key)) {
                String likePattern = '%' + req.sessionName.trim() + '%';
                sessionsByNormalizedName.put(key, [
                    SELECT Id, Name, Session_Date__c, End_Date__c
                    FROM Session__c
                    WHERE Name LIKE :likePattern
                      AND Session_Date__c >= TODAY
                      AND Status__c != 'Cancelled'
                    ORDER BY Session_Date__c ASC NULLS LAST
                ]);
            }
            List<Session__c> sessionMatches = sessionsByNormalizedName.get(key);
            if (sessionMatches.isEmpty()) {
                responses[i].errorMessage = 'No future session found matching "' + req.sessionName.trim() + '".';
            } else if (sessionMatches.size() == 1) {
                resolvedStartTime.put(i, sessionMatches[0].Session_Date__c);
                resolvedEndTime.put(i, sessionMatches[0].End_Date__c);
            } else {
                List<String> opts = new List<String>();
                for (Session__c s : sessionMatches) {
                    opts.add('"' + s.Name + '" on ' + s.Session_Date__c.format());
                }
                responses[i].errorMessage = 'Multiple future sessions match "' + req.sessionName.trim()
                    + '". Please specify which one: ' + String.join(opts, '; ') + '.';
            }
        }

        // Phase 3 — bulk-fetch existing bookings and check availability.
        Set<Id> speakerIds = new Set<Id>();
        for (Integer i = 0; i < requests.size(); i++) {
            if (responses[i].errorMessage != null || responses[i].isAmbiguous) continue;
            Id sid = resolvedSpeakerId.get(i);
            if (sid != null) speakerIds.add(sid);
        }

        Map<Id, Map<Id, SpeakerAvailabilityService.Window>> windowsBySpeaker =
            SpeakerAvailabilityService.getActiveWindowsBySpeaker(speakerIds);

        for (Integer i = 0; i < requests.size(); i++) {
            Response res = responses[i];
            if (res.errorMessage != null || res.isAmbiguous) continue;
            Id speakerId  = resolvedSpeakerId.get(i);
            Datetime startTime = resolvedStartTime.get(i);
            Datetime endTime   = resolvedEndTime.get(i);
            if (speakerId == null || startTime == null) continue;

            SpeakerAvailabilityService.Window conflict = SpeakerAvailabilityService.findConflict(
                windowsBySpeaker.get(speakerId), startTime, endTime, null
            );
            res.isAvailable = conflict == null;
            if (conflict != null) {
                res.conflictingSessionId   = conflict.sessionId;
                res.conflictingSessionName = conflict.sessionName;
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
