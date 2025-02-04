public with sharing class AICommentProcessor {
    @AuraEnabled
    public static String processComments(Id taskId) {
        // Validate CRUD: Ensure the running user has access to Task and its Description field.
        if (!Schema.sObjectType.Task.isAccessible() ||
            !Schema.sObjectType.Task.fields.Description.isAccessible()) {
            throw new AuraHandledException('Insufficient access to Task or Description.');
        }
        
        // Query the Task record for its Description.
        Task t = [SELECT Id, Description FROM Task WHERE Id = :taskId LIMIT 1];
        List<String> softwareMentioned = new List<String>();
        
        if (String.isNotBlank(t.Description)) {
            // Convert to lowercase for case-insensitive matching.
            String descLower = t.Description.toLowerCase();
            
            // Map of keywords to desired software names.
            Map<String, String> softwareMap = new Map<String, String>{
                'revit'           => 'Revit',
                'bluebeam'        => 'BlueBeam',
                'autocad'         => 'AutoCAD',
                'fusion 360'      => 'Fusion 360',
                '3ds max'         => '3ds Max',
                'microsoft'       => 'Microsoft',
                'adobe photoshop' => 'Adobe Photoshop'
            };
            
            // Loop through keywords and add the software name if the keyword is found.
            for (String keyword : softwareMap.keySet()) {
                if (descLower.contains(keyword)) {
                    softwareMentioned.add(softwareMap.get(keyword));
                }
            }
        }
        
        // Return a semicolon-separated string (e.g., "Revit;BlueBeam;Microsoft").
        return String.join(softwareMentioned, ';');
    }
}
