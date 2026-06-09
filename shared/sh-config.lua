-- Configuration file for Paycheck system
-- Defines global settings and parameters
-- All values can be adjusted to customize behavior

Config = {}

-- Enable or disable debug mode (prints additional info)
Config.Debug = false

-- Interval between paychecks, in minutes
-- Change to adjust frequency of payouts
Config.PaycheckInterval = 15 -- minutes

-- Whether to send a notification when a paycheck is processed
-- Options: true/false
Config.NotifyOnPaycheck = true

-- Type of notification to display
-- "lb-phone" for in-game phone notifications, "framework" for generic UI
Config.NotifyType = "lb-phone" -- Options: "framework" or "lb-phone"

-- Currency formatting
Config.CurrencyPrefix = "$"
Config.CurrencySuffix = ""

-- Interaction method with players
-- "target" for target-based interaction, "textui" for text command UI
Config.InteractionType = "textui" -- Options: "target" or "textui"

-- Location data for paycheck-related entities
-- Each entry defines a coordinate set and optional model
Config.Locations = {
    {
        -- Primary spawn point for paycheck process
        coords = vec3(241.550, 227.414, 106.566)
    },
    {
        -- Additional interaction point with model assignment
        pedModel = `u_m_m_bankman`,
        coords = vec4(1176.59, 2708.36, 37.09, 183.81)
    }
}
