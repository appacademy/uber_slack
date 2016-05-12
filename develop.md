## Contributing
We love any contributions! If you have any bug fixes, or would like to add new features:

1. Fork this repo
2. Create feature branch
3. Push to your branch
4. Create Pull Request from your branch to the core project's master branch.

### Getting Started

Join our [Slack Channel](https://uberonslack.com/static_pages/join_slack_team) for
help or discussion.

Read [this](doc/structure.md) for an overview of the codebase.

If your changes would require more extensive testing (e.g. accessing a new Uber API endpoint),
you may want to setup a sandbox version of the app.

1. Fork this Repo.
2. Go to [Uber Developer] to register an app on Uber
  1. Set all redirect URIs as `https://uber-on-slack-sandbox-your-identifier.herokuapp.com/api/connect_uber`
  2. Point privacy policy to your github repo
3. Go to [Slack App API] to create an app
  1. Set all redirect URIs as `https://uber-on-slack-sandbox-your-identifier.com/api/connect_slack`
  2. Create a slash command, and name it as `/uber-your-identifier`
4. You will need the Uber client_id and client_secret, and the slack slash command verification token.
5. Host the app (we use [Heroku](https://dashboard.heroku.com/new)) as _uber-on-slack-sandbox-your-identifier_ (e.g. uber-on-slack-sandbox-app-academy).
  1. After creating the app, on the resources tab under Add-ons, add `Redis to Go`. (This will automatically add its key to Heroku's config.
  2. Under `Settings > Config Vars` add the following key-value pairs:
     * 	slack_app_token
     * 	uber_client_secret
     * 	uber_client_id
     * 	uber_base_url : https://sanbox-api.uber.com/
  3. Deploy the app, either by linking your github account or using the command-line tools Heroku provides.


<!--- 
10. Activate your app in a Slack Channel? 
-->

[Uber Developer]: https://developer.uber.com/dashboard/create
[Slack App API]: https://api.slack.com/apps/new
