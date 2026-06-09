# Filo Paychecks

A FiveM paycheck system addon for managing player wages and job-based payouts.

## Features
- Configurable paycheck intervals (minutes)
- Customizable notification system (framework, lb-phone)
- Persistent player minutes tracking
- Database integration for player wages
- Currency formatting options (prefix/suffix)
- Multiple interaction modes (target-based or textUI)
- Customizable paycheck locations with optional NPC models

## Installation
1. Place files in `resources` folder
2. Add to `server.cfg`: `start filo_paychecks`
3. Configure settings in `shared/sh-config.lua`

## Usage
Players can:
- View available paychecks via UI/menu
- Claim paychecks through interaction prompts
- Configure paycheck settings via the admin interface (if implemented)

## Configuration
See `shared/sh-config.lua` for detailed settings

## Contributing
Pull requests are welcome! For major changes, please open an issue first.