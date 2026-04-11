return json.encode(
    {
        schema = "http://adaptivecards.io/schemas/adaptive-card.json",
        type = "AdaptiveCard",
        version = "1.0",
        body = {
            {
                type = "TextBlock",
                size = "Large",
                weight = "Bolder",
                text = "ToS & Privacy Policy"
            },
            {
                type = "TextBlock",
                wrap = true,
                text = "Welcome, before proceeding we would like to inform you that your identifiers listed below will be used for server registration and user protection purposes."
            },
            {
                type = "FactSet",
                facts = {
                    {
                        title = "license",
                        value = "GTA V License"
                    },
                    {
                        title = "license2",
                        value = "GTA V License (Steam)"
                    },
                    {
                        title = "fivem",
                        value = "Fivem identifier"
                    },
                    {
                        title = "steam",
                        value = "Steam identifier"
                    },
                    {
                        title = "discord",
                        value = "Discord ID"
                    }
                },
            },
            {
                type = "TextBlock",
                wrap = true,
                text = "By clicking \"Accept\" you consent to the processing of your data. If you do not wish to do so, press \"Decline\" and the identifiers will not be collected and the connection to the server will be refused."
            },
        },
        actions = {
            {
                type = "Action.Submit",
                title = "✅ Accept (Join)",
                data = { action = "accept" }
            },
            {
                type = "Action.Submit",
                title = "❌ Decline (Leave)",
                data = { action = "decline" }
            }
        }
    }
)