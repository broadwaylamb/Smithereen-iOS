# Smithereen iOS app

### Building
1. Create the `DeveloperSettings.xcconfig` file in the project root and put the following
   there:
   ```
   DEVELOPMENT_TEAM=<your team ID>
   ORGANIZATION_IDENTIFIER=<your organization identifier>
   ```

   `DEVELOPMENT_TEAM` is a alphanumeric string that you can obtain by logging into
   [Apple Developer Center](https://developer.apple.com/account/) and navigating to
   **Membership Details**. Team ID is what you're looking for.

   `ORGANIZATION_IDENTIFIER` is any string in reverse DNS notation.
   Used for forming the app's bundle identifier, which should uniquely identify the app.

#### Producing an unsigned IPA for sideloading:
1. Run the following command:
   ```
   xcodebuild archive \
       -project Smithereen.xcodeproj \
       -scheme Smithereen \
       -archivePath Smithereen.xcarchive \
       -configuration Release \
       -skipMacroValidation \
       CODE_SIGN_IDENTITY="" \
       CODE_SIGNING_REQUIRED=NO \
     && zip -r Smithereen.ipa Smithereen.xcarchive/Products/Applications
   ```
1. Congratulations, you have an IPA file that you can sideload.
