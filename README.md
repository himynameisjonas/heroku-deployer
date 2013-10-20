HerokuDeployer
===============

Deploy to Heroku with a Github webhook (or anything that can do a post request) for automatic deploys to Heroku when you push to Github.

Supports multiple apps and even other services that does webhooks (for example [Bitbucket](https://confluence.atlassian.com/display/BITBUCKET/POST+hook+management))

## Usage
1. **Clone this repo**

  ```bash
  git clone git@github.com:himynameisjonas/heroku-deployer.git
  ```

2. **Setup app on Heroku**

  Best if it's deployed as a seperate heroku user that is added as a collaborator to all the apps you want to deploy to.
  Generate a new ssh key for this deploy app so it can push to your Heroku apps. Don't forget to add the public deploy key to the heroku user

  ```bash
  heroku config:add DEPLOY_SSH_KEY="$(cat deploy_rsa)" # Where deploy_rsa is your new private ssh key
  ```

  Add a secret deploy token that is used in the post request

  ```bash
  heroku config:add DEPLOY_SECRET="super_secret_string"
  ```

3. **Setup a deployable app**

  Generate a new pair of ssh keys. Add the public key as a deploy key to your github repository.

  Add the app's configs to the HerokuDeployer (here for an app named `example_app`)
  ```bash
  heroku config:add example_app_SSH_KEY="$(cat example_app_rsa)" example_app_GIT_REPO=ssh://git@github.com/himynameisjonas/example_app.git example_app_HEROKU_REPO=git@heroku.com:example_app.git
  ```

4. **Setup github webhook**

  Add a new webhook to the github repository to trigger a deploy to heroku on push.
  ```
  http://your-heroku-deployer-app.herokuapp.com/example_app/super_secret_string
  ```

**Repeat step 3 and 4 for each app you want to deploy**

## Credits
Inspired by [github-heroku-jekyll-hook](https://github.com/dommmel/github-heroku-jekyll-hook) and [github-heroku-pusher](https://github.com/himynameisjonas/github-heroku-pusher)
