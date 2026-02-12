#!/usr/bin/env node

/**
 * Post-version script for SpeedReadNotch
 * Updates the Xcode project version after npm version bump
 */

const fs = require('fs');
const path = require('path');

// Get the new version from package.json
const packageJsonPath = path.join(__dirname, '../package.json');
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));
const newVersion = packageJson.version;

// Path to the Xcode project file
const pbxprojPath = path.join(__dirname, '../SpeedReadNotch/SpeedReadNotch.xcodeproj/project.pbxproj');

// Read the current project file
let pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

// Update MARKETING_VERSION in all configurations
// This regex matches MARKETING_VERSION = x.y.z; and replaces it with the new version
const versionRegex = /MARKETING_VERSION = \d+\.\d+\.\d+(?:\.\d+)?;/g;
const newVersionString = `MARKETING_VERSION = ${newVersion};`;

const updatedContent = pbxprojContent.replace(versionRegex, newVersionString);

// Check if any changes were made
if (updatedContent === pbxprojContent) {
  console.warn('Warning: No MARKETING_VERSION found in project.pbxproj');
  process.exit(1);
}

// Write the updated content back
fs.writeFileSync(pbxprojPath, updatedContent, 'utf-8');

console.log(`✓ Updated Xcode project version to ${newVersion}`);
