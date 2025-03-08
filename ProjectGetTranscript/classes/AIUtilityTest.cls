// File: force-app/ProjectGetTranscript/classes/AIUtilityTest.cls
@isTest
private class AIUtilityTest {
    
    // HTTP callout mock for OpenAI.
    class AIUtilityMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            // Return valid JSON.
            res.setBody('{"response": "Success"}');
            return res;
        }
    }
    
    @isTest static void testCallOpenAI() {
        Test.setMock(HttpCalloutMock.class, new AIUtilityMock());
        String responseBody = AIUtility.callOpenAI('Test task description');
        System.assertEquals('{"response": "Success"}', responseBody);
    }
}
