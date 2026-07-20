global with sharing class AssignSpeakerToSession {

    global class Request {
        @InvocableVariable(label='Speaker Id' required=true description='The Id of the Speaker__c record to assign.')
        public Id speakerId;

        @InvocableVariable(label='Session Id' required=true description='The Id of the Session__c record to assign the speaker to.')
        public Id sessionId;

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

        global Response() {}
    }

    @InvocableMethod(label='Assign Speaker To Session' description='Creates a Session_Speaker__c record linking a Speaker to a Session, enforcing existing double-booking and cancelled-session rules.')
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

            Set<Id> speakerIds = new Set<Id>();
            Set<Id> sessionIds = new Set<Id>();
            for (Request req : requests) {
                if (req.speakerId != null) speakerIds.add(req.speakerId);
                if (req.sessionId != null) sessionIds.add(req.sessionId);
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
                Request req = requests[i];
                Response res = responses[i];
                res.success = false;

                if (req.speakerId == null || req.sessionId == null) {
                    res.message = 'Both speakerId and sessionId are required.';
                    continue;
                }
                if (!speakersById.containsKey(req.speakerId)) {
                    res.message = 'No Speaker record was found for Id ' + req.speakerId + '.';
                    continue;
                }
                if (!sessionsById.containsKey(req.sessionId)) {
                    res.message = 'No Session record was found for Id ' + req.sessionId + '.';
                    continue;
                }
                if (String.isNotBlank(req.role) && !validRoles.contains(req.role)) {
                    res.message = '"' + req.role + '" is not a valid Role. Valid values are: ' + String.join(new List<String>(validRoles), ', ') + '.';
                    continue;
                }

                Session_Speaker__c ss = new Session_Speaker__c(
                    Speaker__c = req.speakerId,
                    Session__c = req.sessionId
                );
                if (String.isNotBlank(req.role)) {
                    ss.Role__c = req.role;
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
                Request req = requests[requestIndex];
                Response res = responses[requestIndex];

                if (sr.isSuccess()) {
                    res.success = true;
                    res.sessionSpeakerId = sr.getId();
                    res.message = 'Assigned ' + speakersById.get(req.speakerId).Name
                        + ' to "' + sessionsById.get(req.sessionId).Name + '". View: '
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

    private static Set<String> getActiveRoleValues() {
        Set<String> values = new Set<String>();
        for (Schema.PicklistEntry entry : Session_Speaker__c.Role__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }
}
