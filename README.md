# [UberOnSlack][uberslacklink]
[![Circle CI](https://circleci.com/gh/appacademy/uber_slack/tree/master.svg?style=svg)](https://circleci.com/gh/appacademy/uber_slack/tree/master)


* An Uber & Slack Integration API
* Built by App Academy students in the August 2015 cohort

## Overview

Uber on Slack enables Slack users to hail Uber rides directly from their chat client with a command-line type interface. By utilizing slash commands ([https://api.slack.com/slash-commands][slashlink]) from the Slack API, Uber on Slack allows the user to type in various commands (see Usage section below) to hail an UberX ride to a designated pickup location and designate certain options for the ride.

[slashlink]: https://api.slack.com/slash-commands
[uberslacklink]: https://uberonslack.com

## Usage

All commands will follow the following format:
```
/uber [command] [extra parameters]
```

#### Hailing a Ride
To hail a ride, enter a 'ride' command in your Slack chat in the following format:
```
/uber ride [pickup address] to [destination address]
```

This can handle a variety of address formats:
```
/uber ride 1061 market st to 24 willie mays plaza
/uber ride 1061 Market St. to 24 Willie Mays Plaza
/uber ride 1061 market street san francisco to 24 willie mays plaza san francisco
```

And will return a JSON string notifying you of the status:
```
{"status":"processing","request_id":"6c265d45-3a1c-4434-ba73-0be5d2c2d14f","driver":null,"eta":12,"location":null,"vehicle":null,"surge_multiplier":1.0}`
```

#### Cancelling a Ride
You can cancel a ride by using the 'cancel' command:
```
/uber cancel
```

#### Uber Vehicles
To see the various Über vehicles that are available:
```
/uber products [destination address]
```

This will return a response like so:
```
The following products are available:
- uberX: The low-cost Uber (Capacity: 4)
- uberXL: Low-Cost Rides for Large Groups (Capacity: 6)'
```

#### Help
A help manual is available with the 'help' command:
```
/uber help
```

#### Support
Get more info about support [here](support.md).

## Contributing

#### Slack Channels

Join our [Slack Channel](https://uber-on-slack.slack.com) to

- discuss about this project
- throw in ideas of new features
- or simply report/fix bugs if you see any

#### New features / bug fixes

1. Folk this repo
2. Create feature branch
3. Push to your branch
4. Create Pull Request from your branch
5. That's it!

#### Encounter issues?

If you encounter any kind of issue, you can simply report it on github or discuss on our 
[Slack Channel](https://uber-on-slack.slack.com)

## License
Uber on Slack is open-source and free to distribute or modify under the
[MIT License](LICENSE.txt).

## Acknowledgment
Uber on Slack would not be possible were it not for its contributors from App
Academy including: Simon Chaffetz, Edmund Lee, Matthew Symonds, Edward Huang,
Nicole DeVillers, Sangam Kaushik, Sven Ten Haaf, Christopher Huang,
Andrew Liu, Justin Menestrina, Alvin Ly, Sean Walker, Jacky Lei, Minh Nguyen,
Noah Wiener, Nathan Specht, Austin Kao, David Ammons, Ian Nguyen,
Joe Cho, Marc Tambara, Vic Chen, and Haseeb Qureshi.
