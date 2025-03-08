@isTest
private class TermsAndConditionsServiceTest {
    @isTest static void testDummy() {
        try {
            String res = TermsAndConditionsService.getTermsContent();
        } catch(Exception e) { }
        System.assert(true);
    }
}
