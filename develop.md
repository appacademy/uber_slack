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
5. Host the app (we use Heroku) as _uber-on-slack-sandbox-your-identifier_ (e.g. uber-on-slack-sandbox-app-academy).
  * This name would be used for your Heroku app, and Registration on Uber and Slack.
6. Go to [Uber Developer] to register an app on Uber
  1. Set all redirect URIs as `https://uber-on-slack-sandbox-your-identifier.herokuapp.com/api/connect_uber`
  2. Point privacy policy to your github repo
7. Go to [Slack App API] to create an app
  1. Set all redirect URIs as `https://uber-on-slack-sandbox-your-identifier.com/api/connect_slack`
  2. Create a slash command, and name it as `/uber-your-identifier`
8. You will need the Uber client_id and client_secret, and the slack slash command verification token.
  1. We use the [Figaro](https://github.com/laserlemon/figaro) gem to manage client secrets.
  2. Run `bundle exec figaro install`, which will generate an `application.yaml` file to store your secrets in. It should look like this:
  ```yaml
    # TODO: @Edmundleex, can you put your file here (with secrets censored), since this is just my best guess? I think you also have a redis URI that's been breaking for me locally, I'm not sure what to do with that.
    uber_client_id: "your id"
    uber_client_secret: "your secret"
    uber_base_url:   "https://sandbox-api.uber.com/"
    slack_app_token: "your token"
  ```
  3. Run `figaro heroku:set -e production` to push your keys to your production app. (You may need to have installed the Heroku CLI toolkit first)
9. Deploy the app to Heroku
<!-- 8. Click this button in your forked repo to deploy
  * [![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/username/repo)
  (@cchuang) This button wasn't working for me; but I had other problems like missing secrets too so I don't know.
9. Paste your heroku app URL in the description, and specify what the PR is about.
10. That's it.
10. Activate your app in a Slack Channel? -->

[Uber Developer]: https://developer.uber.com/dashboard/create
[Slack App API]: https://api.slack.com/apps/new
