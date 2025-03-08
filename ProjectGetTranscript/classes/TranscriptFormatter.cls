// File: ProjectGetTranscript/classes/TranscriptFormatter.cls
public with sharing class TranscriptFormatter {
    /**
     * Formats a raw JSON transcript string by extracting only the transcript lines.
     * Each line is formatted as "Name: Content".
     *
     * @param rawTranscriptJson The raw JSON string from Dialpad.
     * @return A formatted transcript string.
     */
    public static String formatTranscript(String rawTranscriptJson) {
        if (String.isBlank(rawTranscriptJson)) {
            return '';
        }
        try {
            // Deserialize the JSON into a generic map.
            Map<String, Object> transcriptMap = (Map<String, Object>) JSON.deserializeUntyped(rawTranscriptJson);
            if (transcriptMap == null || !transcriptMap.containsKey('lines')) {
                return '';
            }
            
            // Retrieve the list of transcript lines.
            List<Object> lines = (List<Object>) transcriptMap.get('lines');
            List<String> formattedLines = new List<String>();
            
            // Process each line.
            for (Object obj : lines) {
                Map<String, Object> line = (Map<String, Object>) obj;
                // Include only lines where "type" equals "transcript" (case-insensitive)
                if (line.containsKey('type') && String.valueOf(line.get('type')).toLowerCase() == 'transcript') {
                    String name = line.containsKey('name') ? String.valueOf(line.get('name')) : 'Unknown';
                    String content = line.containsKey('content') ? String.valueOf(line.get('content')) : '';
                    formattedLines.add(name + ': ' + content);
                }
            }
            return String.join(formattedLines, '\n');
        } catch (Exception ex) {
            System.debug('Error formatting transcript: ' + ex.getMessage());
            return '';
        }
    }
    
    /**
     * Merges the existing Task description with the new transcript.
     * If the original description already contains a transcript (identified by the delimiter),
     * it removes the old transcript and appends the new transcript.
     *
     * @param originalDescription The current saved Task description.
     * @param transcript The newly formatted transcript.
     * @return The merged Task description.
     */
    public static String mergeDescriptions(String originalDescription, String transcript) {
        String delimiter = '\n\n--- Transcript ---\n';
        if (originalDescription == null) {
            originalDescription = '';
        }
        // Remove any previously appended transcript.
        if (originalDescription.contains(delimiter)) {
            List<String> parts = originalDescription.split(delimiter);
            originalDescription = parts[0];
        }
        // Append the new transcript.
        return originalDescription + delimiter + transcript;
    }
}
