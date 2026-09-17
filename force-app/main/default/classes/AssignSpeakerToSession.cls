global with sharing class AssignSpeakerToSession {

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

        @InvocableVariable(label='Session Id' description='Provide Session Id or Session Name, not both.')
        public Id sessionId;
        @InvocableVariable(label='Session Name' description='Name (or partial name) of a future Session__c. Used to infer the Session Id when the Id is not known. If multiple future sessions match, the assignment is not made and the matches are listed in the response message.')
        public String sessionName;

        @InvocableVariable(label='Role' description='Optional: Keynote, Panelist, Moderator, or Workshop Leader. Defaults to the field default if omitted.')
        public String role;

        global Request() {}
    }

    global class Response {
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Session Speaker Id')
        public Id sessionSpeakerId;
        @InvocableVariable(label='Message' description='Human-readable confirmation on success, or the reason the assignment could not be made.')
        public String message;
        @InvocableVariable(label='Is Speaker Ambiguous')
        public Boolean isSpeakerAmbiguous;
        @InvocableVariable(label='Speaker Candidates')
        public List<CandidateSpeaker> speakerCandidates;
        global Response() {
            this.isSpeakerAmbiguous  = false;
            this.speakerCandidates   = new List<CandidateSpeaker>();
        }
    }

    @InvocableMethod(label='Assign Speaker To Session' description='Creates a Session_Speaker__c record linking a Speaker to a Session, enforcing existing double-booking and cancelled-session rules. Speaker and session can both be identified by name.')
    global static List<Response> assignSpeakers(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Integer i = 0; i < requests.size(); i++) {
            responses.add(new Response());
        }

        try {
            if (!Session_Speaker__c.SObjectType.getDescribe().isCreateable()) {
                String noAccessMessage = 'You do not have permission to create Session Speaker records.';
                for (Response res : responses) {
                    res.success = false;
                    res.message = noAccessMessage;
                }
                return responses;
            }

            // Phase 1 — resolve speakers by name/email when speakerId is not provided.
            Map<Integer, Id> resolvedSpeakerId = new Map<Integer, Id>();
            for (Integer i = 0; i < requests.size(); i++) {
                Request req = requests[i];
                if (req.speakerId != null) {
                    resolvedSpeakerId.put(i, req.speakerId);
                    continue;
                }
                String term = buildSpeakerSearchTerm(req);
                if (String.isBlank(term) && String.isBlank(req.email)) {
                    responses[i].success = false;
                    responses[i].message = 'Provide a speaker name, email, or Speaker Id.';
                    continue;
                }
                List<Speaker__c> matches = lookupSpeakers(req, term);
                if (matches.isEmpty()) {
                    String searched = String.isNotBlank(req.email) ? req.email.trim() : term;
                    responses[i].success = false;
                    responses[i].message = 'No speaker found matching "' + searched + '". Here are the 10 most recently updated speakers — pick one and try again.';
                    responses[i].speakerCandidates = getRecentSpeakers();
                } else if (matches.size() == 1) {
                    resolvedSpeakerId.put(i, matches[0].Id);
                } else {
                    responses[i].isSpeakerAmbiguous = true;
                    responses[i].speakerCandidates  = toCandidates(matches);
                }
            }

            // Phase 2 — resolve session names to IDs. One query per unique name; future sessions only.
            Map<Integer, Id> resolvedSessionId = new Map<Integer, Id>();
            Map<String, List<Session__c>> sessionsByNormalizedName = new Map<String, List<Session__c>>();
            for (Integer i = 0; i < requests.size(); i++) {
                if (responses[i].message != null || responses[i].isSpeakerAmbiguous) continue;
                Request req = requests[i];
                if (req.sessionId != null) {
                    resolvedSessionId.put(i, req.sessionId);
                    continue;
                }
                if (String.isBlank(req.sessionName)) continue;
                String key = req.sessionName.trim().toLowerCase();
                if (!sessionsByNormalizedName.containsKey(key)) {
                    String likePattern = '%' + req.sessionName.trim() + '%';
                    sessionsByNormalizedName.put(key, [
                        SELECT Id, Name, Session_Date__c
                        FROM Session__c
                        WHERE Name LIKE :likePattern
                          AND Session_Date__c >= TODAY
                          AND Status__c != 'Cancelled'
                        ORDER BY Session_Date__c ASC NULLS LAST
                    ]);
                }
                List<Session__c> sessionMatches = sessionsByNormalizedName.get(key);
                if (sessionMatches.size() == 1) {
                    resolvedSessionId.put(i, sessionMatches[0].Id);
                } else if (sessionMatches.isEmpty()) {
                    responses[i].success = false;
                    responses[i].message = 'No future session found matching "' + req.sessionName.trim() + '".';
                } else {
                    List<String> opts = new List<String>();
                    for (Session__c s : sessionMatches) {
                        opts.add('"' + s.Name + '" on ' + s.Session_Date__c.format());
                    }
                    responses[i].success = false;
                    responses[i].message = 'Multiple future sessions match "' + req.sessionName.trim()
                        + '". Please specify which one: ' + String.join(opts, '; ') + '.';
                }
            }

            // Phase 3 — bulk-query resolved speakers and sessions.
            Set<Id> speakerIds = new Set<Id>();
            Set<Id> sessionIds = new Set<Id>();
            for (Integer i = 0; i < requests.size(); i++) {
                Id effSpeakerId = resolvedSpeakerId.get(i);
                Id effSessionId = resolvedSessionId.get(i);
                if (effSpeakerId != null) speakerIds.add(effSpeakerId);
                if (effSessionId  != null) sessionIds.add(effSessionId);
            }
            Map<Id, Speaker__c> speakersById = new Map<Id, Speaker__c>(
                [SELECT Id, Name FROM Speaker__c WHERE Id IN :speakerIds]
            );
            Map<Id, Session__c> sessionsById = new Map<Id, Session__c>(
                [SELECT Id, Name FROM Session__c WHERE Id IN :sessionIds]
            );
            Set<String> validRoles = getActiveRoleValues();

            List<Session_Speaker__c> toInsert = new List<Session_Speaker__c>();
            List<Integer> requestIndexByInsertIndex = new List<Integer>();

            for (Integer i = 0; i < requests.size(); i++) {
                Response res = responses[i];
                if (res.message != null || res.isSpeakerAmbiguous) continue;
                res.success = false;

                Id effSpeakerId = resolvedSpeakerId.get(i);
                Id effSessionId = resolvedSessionId.get(i);

                if (effSpeakerId == null || effSessionId == null) {
                    res.message = 'Speaker and session are required — provide names or IDs for both.';
                    continue;
                }
                if (!speakersById.containsKey(effSpeakerId)) {
                    res.message = 'No Speaker record was found for Id ' + effSpeakerId + '.';
                    continue;
                }
                if (!sessionsById.containsKey(effSessionId)) {
                    res.message = 'No Session record was found for Id ' + effSessionId + '.';
                    continue;
                }
                if (String.isNotBlank(requests[i].role) && !validRoles.contains(requests[i].role)) {
                    List<String> sorted = new List<String>(validRoles);
                    sorted.sort();
                    res.message = '"' + requests[i].role + '" is not a valid Role. Valid values are: ' + String.join(sorted, ', ') + '.';
                    continue;
                }

                Session_Speaker__c ss = new Session_Speaker__c(
                    Speaker__c = effSpeakerId,
                    Session__c = effSessionId
                );
                if (String.isNotBlank(requests[i].role)) {
                    ss.Role__c = requests[i].role;
                }
                toInsert.add(ss);
                requestIndexByInsertIndex.add(i);
            }

            if (toInsert.isEmpty()) {
                return responses;
            }

            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, toInsert);
            List<Database.SaveResult> saveResults = Database.insert(decision.getRecords(), false);

            for (Integer j = 0; j < saveResults.size(); j++) {
                Database.SaveResult sr = saveResults[j];
                Integer requestIndex = requestIndexByInsertIndex[j];
                Response res = responses[requestIndex];
                Id effSpeakerId = resolvedSpeakerId.get(requestIndex);
                Id effSessionId = resolvedSessionId.get(requestIndex);

                if (sr.isSuccess()) {
                    res.success = true;
                    res.sessionSpeakerId = sr.getId();
                    res.message = 'Assigned ' + speakersById.get(effSpeakerId).Name
                        + ' to "' + sessionsById.get(effSessionId).Name + '". View: '
                        + URL.getOrgDomainUrl().toExternalForm() + '/' + sr.getId();
                } else {
                    res.message = sr.getErrors()[0].getMessage();
                }
            }
        } catch (Exception e) {
            String fallbackMessage = 'Unexpected error while assigning speakers: ' + e.getMessage();
            for (Response res : responses) {
                if (res.success == null) {
                    res.success = false;
                    res.message = fallbackMessage;
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

    private static String buildSpeakerSearchTerm(Request req) {
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

    private static Set<String> getActiveRoleValues() {
        Set<String> values = new Set<String>();
        for (Schema.PicklistEntry entry : Session_Speaker__c.Role__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) values.add(entry.getValue());
        }
        return values;
    }
}
