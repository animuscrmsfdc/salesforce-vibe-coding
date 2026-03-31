@IsTest
private class ChatterHelperTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBodyAsBlob(Blob.valueOf('GIF89a'));
            return res;
        }
    }

    @IsTest
    static void getChatterGroups_returnsNonNullFeedItemId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        String feedItemId = ChatterHelper.getChatterGroups(
            'http://example.com/test.gif',
            'Test chatter post'
        );
        Test.stopTest();

        System.assertNotEquals(null, feedItemId, 'getChatterGroups should return a non-null FeedItem Id');
        System.assert(feedItemId.length() > 0, 'Returned FeedItem Id should not be empty');
    }
}
