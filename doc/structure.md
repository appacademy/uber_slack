# Overall App Structure

## Middleware Server
A Rails server handles authorization with both Slack and Uber. A user who wishes to use the app will receive a link to a static page on our server, which redirects to the Uber authorization page. We use a session to connect the slack user information with the Uber authorization information.

After authorization, the user's commands are parsed and executed by an UberCommand object. Most commands will involve us making a request to Uber's API. The response to that will be used as part of our response to the request from Slack.

Information about both a user's authorization and rides are stored in a Postgres DB.

## Slack
We have an an app registered within the Slack system. When someone adds our app to their channel, it makes an api call to us, and we then make a request to Slack with our identifying information and a code that was sent by the call from Slack.

When a user makes a request that we don't handle immediately, we will later use a webhook to send that information to them.

## Uber
Uber has a well documented and highly usable public api. Like Slack, our application is registered with Uber. Users authenticate us with the OAuth2 pattern.

When a user agrees to let our app do things on their behalf on the Uber website, they are sent to a page on our site, with a code included in the params. This code is exchanged for an authorization token, which is included in every request we make to Uber. Getting the authorization token also gives us a refresh token, which can be used to get a new authorization token when the old one expires.
