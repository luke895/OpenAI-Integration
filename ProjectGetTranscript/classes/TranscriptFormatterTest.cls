// File: force-app/ProjectGetTranscript/classes/TranscriptFormatterTest.cls
@isTest
private class TranscriptFormatterTest {
    
    @isTest static void testFormatTranscriptSuccess() {
        // Sample raw JSON transcript.
        String rawJson = '{"lines":[' +
            '{"type":"transcript", "name":"Alice", "content":"Hello world"},' +
            '{"type":"nontranscript", "name":"Bob", "content":"Ignore me"},' +
            '{"type":"TRANSCRIPT", "name":"Charlie", "content":"Testing"}' +
            ']}';
        String expected = 'Alice: Hello world\nCharlie: Testing';
        String result = TranscriptFormatter.formatTranscript(rawJson);
        System.assertEquals(expected, result, 'The formatted transcript should include only transcript lines.');
    }
    
    @isTest static void testFormatTranscriptEmpty() {
        String result = TranscriptFormatter.formatTranscript('');
        System.assertEquals('', result, 'Blank input should return an empty string.');
    }
    
    @isTest static void testMergeDescriptionsWithoutDelimiter() {
        String original = 'Initial description';
        String transcript = 'Alice: Hello world\nCharlie: Testing';
        String delimiter = '\n\n--- Transcript ---\n';
        String expected = original + delimiter + transcript;
        String result = TranscriptFormatter.mergeDescriptions(original, transcript);
        System.assertEquals(expected, result, 'Merged description should concatenate original description and transcript.');
    }
    
    @isTest static void testMergeDescriptionsWithDelimiter() {
        String original = 'Initial description\n\n--- Transcript ---\nOld transcript';
        String transcript = 'Alice: Hello world\nCharlie: Testing';
        String delimiter = '\n\n--- Transcript ---\n';
        String expected = 'Initial description' + delimiter + transcript;
        String result = TranscriptFormatter.mergeDescriptions(original, transcript);
        System.assertEquals(expected, result, 'Old transcript should be removed and new transcript appended.');
    }
}
