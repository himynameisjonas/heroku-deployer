HerokuDeployer [![Build Status](https://travis-ci.org/himynameisjonas/heroku-deployer.png?branch=master)](https://travis-ci.org/himynameisjonas/heroku-deployer) [![Code Climate](https://codeclimate.com/github/himynameisjonas/heroku-deployer.png)](https://codeclimate.com/github/himynameisjonas/heroku-deployer)
===============

HerokuDeployer is an app you can host on Heroku. 
It syncs the code in your github repositories with the apps you have in Heroku.
Each time you push to github, the changes will be deployed automatically to your Heroku apps.
This saves you the step of pushing to Heroku also, and keeping the two gits in sync manually.

To deploy to Heroku, HerokuDeployer uses a Github webhook (or anything that can do a post request). 

HerokuDeployer can support multiple Heroku apps and even other services that use webhooks (for example 
[Bitbucket](https://confluence.atlassian.com/display/BITBUCKET/POST+hook+management))

### Jekyll + Heroku + Prose.io

This is the way I use HerokuDeployer:

I have a [blog](http://jonasforsberg.se) hosted on Heroku as an app. 
I use [Jekyll](http://jekyllrb.com/) which means that my blog posts are static markdown pages kept in a git repository.
To write new posts I use [prose.io](http://prose.io/) with which I can make changes online directly on github. 
Then the HerokuDeployer deploys those changes automatically to my blog on Heroku.

See [himynameisjonas/jekyll-heroku-unicorn](https://github.com/himynameisjonas/jekyll-heroku-unicorn) 
to learn how to host a jekyll site on Heroku without need of building the site before deploy.

## Usage
1. **Create new account**

  It would be best if you create a new heroku account for HerokuDeployer. 
  
  ```
  Step 1:
    Create a new_account to heroku.com. 
  Step 2:
    Go to your old_account
    Go to each app you want to be able to deploy to automatically
    Add to each app new_account as a collaborator.
  ```

2. **Clone HerokuDeployer, and deploy it**

  ```bash
  git clone git@github.com:himynameisjonas/heroku-deployer.git
  heroku login
  # Give login and password for your new_account
  heroku create give_deployer_a_name
  git push heroku master
  ```

3. **Connect the old and the new account**

  Now we should create a ssh key, to allow the communication between the new_account and the old_account.
  
  ```bash
  ssh-keygen -t rsa
  # It will demand for a filename: Save it to "deploy_rsa"
  # You don't have to give any passphrase
  ```
  An RSA key has a private part, and a public part. We have to give the public part to our old_account, 
  and the private part to our new_account.
  
  ```bash
  Step 1:
    At your browser, sign in to your old_account at Heroku
    Go to Account > SSH Keys
    Copy the contents of "deploy_rsa.pub" to the "add new key" field
    Add the key
  Step 2 (command line):
    heroku login
    # Write your login and password for you new_account
    heroku config:set DEPLOY_SSH_KEY="$(cat deploy_rsa)" # deploy_rsa is your new private ssh key
  ```

  We should also add a secret deploy token that is used in the post request.

  ```bash
  heroku config:add DEPLOY_SECRET="super_secret_string"
  ```

4. **Connect HerokuDeployer with ONE Github repository and ONE Heroku app**

  Generate a new pair of ssh keys. Add the public key as a deploy key to your github repository.
  
  **ATTENTION**: You should replace the following:
  
  * "example_app" with your apps name.
  * "github_username" with your github username
  * "github_repository" wiht the name of the github repository you will use for deployment

  ```bash
  Step 1 (terminal):
    ssh-keygen -t rsa
    # It will demand for a filename: Save it to "example_app_rsa"
    # You don't have to give any passphrase
  Step 2 (browser):
    Connect to github
    Go to github_repository > Settings > Deploy Keys 
    Copy the contents of "example_app_rsa.pub" to the new key field
  ```

  Add the app's configs to the HerokuDeployer (here for an app named `example_app`)
 
  ```bash
  heroku config:set example_app_SSH_KEY="$(cat example_app_rsa)" example_app_GIT_REPO=ssh://git@github.com/github_username/github_repository.git example_app_HEROKU_REPO=git@heroku.com:example_app.git
  ```
  
5. **Setup github webhook**

  Add a new webhook to the github repository to trigger a deploy to heroku on push.
  ```bash
  Connect to github
  Go to github_repository > Settings > Service Hooks
  Add the following link as a WebHook URL
  https://give_deployer_a_name.herokuapp.com/deploy/example_app/super_secret_string
  ```

**Repeat step 4 and 5 for each app you want to deploy**

## Credits
Inspired by [github-heroku-jekyll-hook](https://github.com/dommmel/github-heroku-jekyll-hook) and [github-heroku-pusher](https://github.com/himynameisjonas/github-heroku-pusher)
