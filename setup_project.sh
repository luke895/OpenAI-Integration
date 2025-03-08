#!/bin/bash

# Base project directory
PROJECT_NAME="ProjectAIPopulate"
mkdir -p $PROJECT_NAME/main/default

# Create subdirectories
mkdir -p $PROJECT_NAME/main/default/classes
mkdir -p $PROJECT_NAME/main/default/triggers
mkdir -p $PROJECT_NAME/main/default/lwc/AIStagingReview
mkdir -p $PROJECT_NAME/main/default/lwc/CallWhisperingSection
mkdir -p $PROJECT_NAME/main/default/objects
mkdir -p $PROJECT_NAME/main/default/staticresources
mkdir -p $PROJECT_NAME/main/default/external_services

# Create Apex Class files and metadata
for file in TaskAIProcessor TaskAssetHelper AIUtility MockAircallAPI; do
  touch $PROJECT_NAME/main/default/classes/$file.cls
  touch $PROJECT_NAME/main/default/classes/$file.cls-meta.xml
done

# Create Trigger files and metadata
for file in TaskTrigger TaskTriggerHandler; do
  touch $PROJECT_NAME/main/default/triggers/$file.trigger
  touch $PROJECT_NAME/main/default/triggers/$file.trigger-meta.xml
done

# Create LWC files and metadata
for component in AIStagingReview CallWhisperingSection; do
  touch $PROJECT_NAME/main/default/lwc/$component/$component.html
  touch $PROJECT_NAME/main/default/lwc/$component/$component.js
  touch $PROJECT_NAME/main/default/lwc/$component/$component.css
  touch $PROJECT_NAME/main/default/lwc/$component/$component.js-meta.xml
done

# Create object metadata files
for file in AI_Staging_Area__c Interested_Software__c Asset Opportunity; do
  touch $PROJECT_NAME/main/default/objects/$file.object-meta.xml
done

# Create static resources
touch $PROJECT_NAME/main/default/staticresources/OpenAIUtility.js

# Create external services metadata
touch $PROJECT_NAME/main/default/external_services/OpenAIIntegration.service-meta.xml

# Create project-level files
touch $PROJECT_NAME/README.md
touch $PROJECT_NAME/LICENSE
touch $PROJECT_NAME/.gitignore
touch $PROJECT_NAME/.forceignore
touch $PROJECT_NAME/sfdx-project.json

echo "Folder structure and files created for ProjectAIPopulate."

