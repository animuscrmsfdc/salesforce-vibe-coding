global with sharing class GetSpeakerAvailability {

    global class Request {
        @InvocableVariable(label='Speaker Id' required=true)
        public Id speakerId;

        @InvocableVariable(label='Start Date/Time' required=true)
        public Datetime startTime;

        @InvocableVariable(label='End Date/Time')
        public Datetime endTime;

        global Request() {}
    }

    global class Response {
        @InvocableVariable(label='Is Available')
        public Boolean isAvailable;

        @InvocableVariable(label='Conflicting Session Speaker Id')
        public Id conflictingAssignmentId;

        global Response() {}
    }

    @InvocableMethod(label='Get Speaker Availability' description='Checks whether a Speaker is free for a candidate session time window, without creating a booking.')
    global static List<Response> checkAvailability(List<Request> requests) {
        Set<Id> speakerIds = new Set<Id>();
        for (Request req : requests) {
            if (req.speakerId == null || req.startTime == null) {
                throw new IllegalArgumentException('GetSpeakerAvailability: speakerId and startTime must not be null');
            }
            speakerIds.add(req.speakerId);
        }

        Map<Id, Map<Id, SpeakerAvailabilityService.Window>> windowsBySpeaker =
            SpeakerAvailabilityService.getActiveWindowsBySpeaker(speakerIds);

        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            SpeakerAvailabilityService.Window conflict = SpeakerAvailabilityService.findConflict(
                windowsBySpeaker.get(req.speakerId),
                req.startTime,
                req.endTime,
                null
            );

            Response res = new Response();
            res.isAvailable = conflict == null;
            res.conflictingAssignmentId = conflict == null ? null : conflict.assignmentId;
            responses.add(res);
        }
        return responses;
    }
}
