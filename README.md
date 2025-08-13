```
        .-.-----------.-.	Generic
        | |-----------|#|	LED Bars - Generation 1
        | |-----------| |	Setup & User Manual
        | |-----------| |
        | |--------etf| |	Rule of Thumb:
        | "-----------' |	a) Panels cannot be duplicatable, however, the entire product can be. (that includes the panel! just duplicate the entire folder.)
        |  .-----.-..   |	b) The lights are using a numbering system is infinite.
        |  |     | || |||	The only requirement is that your lights must be a mirror of eachother. (more later)
        |  |     | || \/|	c) This is a whitelisted product, meaning only users whos roblox account owns the license
        "--^-----^-^^---'	can use them in their game.

        API DOCUMENTATION: https://github.com/dr4wn/led-bars-api-docs
        THIS PRODUCT USES ATTRIBUTES! DO NOT NAME THE FIXTURE!

        Example of naming mechanisms:
        Group 1                                                                         Group 2
        FixtureID: 1 | FixtureID: 2 | FixtureID: 3 | FixtureID: 3 | FixtureID: 2 | FixtureID: 1
        Secondary: 1 | Secondary: 2 | Secondary: 3 | Secondary: 4 | Secondary: 5 | Secondary: 6

        ** This product is semi-functional on mobile devices.
        This product was designed for computer operators.

        Bugs may be expected (the light emitted from the product!)
        This product is generation one. We are always looking for
        suggestions :)

        ** / IMPORTANT \ **
        "Configuration.ignoreStreamingEnabled" is set to "false" by default.
        If StreamingEnabled is on in your game, the product will not run while this is false.

        "Configuration.streamingEnabledWarning" is a warning to indicate whether
        StreamingEnabled is set to true or not.

        TURN OFF STREAMINGENABLED!
        New places have updated all new places to automatically have
        StreamingEnabled on. Lights will NOT work within a certain distance
        with this setting on. To turn it off, navigate to Workspace and untick "StreamingEnabled".

        This setting has affected many lighting services, and we are working on a solution ASAP.
        Sorry for any inconvenience!

        If you cannot find it, run this script in the command bar.

        game.Workspace.StreamingEnabled = false

        How to setup the fixtures:
            a) Ensure that HTTP Services are enabled within your game. You can do this by navigating to "Game Settings"
            in the "Home" category at the top of your Roblox Studio. From there, go to "Security" and allow HTTP Requests
            to come through.

            [Optional, recommended] b) Configure your administrators list. By default, the panel and lights are accessible to be controlled by everyone,
            but if you configure your file, you will unlock the capability to whitelist groups, user ids, users, etc.

            [Important!] c) Number fixtures using the "FixtureID" attribute. Ensure fixtures are infinitely numberable if they mirror each other;
            set the right side's "GroupID" to 2. Do not change fixture names; only modify "FixtureID."

            If you are having additional problems, don't hesitate to submit a support ticket towards staff and
            someone will be there to assist you. Make sure to include a picture of your console!

            |[] Output                                                        |F]|!"|
            |"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""|"|
            |12.Workbench:> hi!                                                   | |
            |12.Workbench:> this is the output...                                 | |
            |12.Workbench:> You can navigate to it by going to "View"             | |
            |and clicking "Output". Make sure to include whats from this product! |_|
            |_____________________________________________________________________|/|

        Custom Position Configuration:

            To create custom positions, use the "custom" mode with the following parameters:

            Parameters:
            - "mode" (string): Required. Set to "custom" to enable custom positioning.
            - "data" (table): Required. An array of angles, in radians, for custom positioning.

            Example:

            {
                mode = "custom",
                data = { math.rad(0), math.rad(35), math.rad(90) }
            }

            Explanation:
            - "mode" is set to "custom" to indicate custom positioning.
            - The "interleave" is set to 3 represented by the 3 resutls in this array, representing the interleave factor.
            - "data" contains an array of angles, in radians, for custom positioning.

            Additional Notes:
            - Angle values in "data" should be specified in radians.
            - The angle limit is from -135 to 135 radians.

            Usage Guidelines:
            - Use this configuration to define custom positions for your application.

        API Usage:

            To enable the api, head to "configuration" and set "Configuration.usingApi" to "true".
            We understand that users may want to place their API script in another location, so here's a guide
            on how to access the API from an external spot!

            Keep in mind that this is an example that allows you to control one set of fixtures, you could
            always require all of the API modules from the same tag and have simultaneous control!

            * more information is present in the github link
```