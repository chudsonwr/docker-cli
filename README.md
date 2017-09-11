# docker-cli
CLI for launching dockerized apps on Ubuntu 16.04 LTS

* Retrieves repo from GitHub based on commit hash or branch
* Creates Docker image
* Launches Docker container.
* Runs multiple containers behind nginx-reverse proxy container.

## Requirements
* Ubuntu 16.04 LTS (though probably works on other *nix variants)
* Docker-ce
* Docker Compose
* Ruby 2.1.3 (probably works on later versions as well)

## Usage
Run `bundle install`

Run the provision.rb executable and supply various command line options.

##### --action
This is the action you would like to perform. It mirrors most actions available to the standard docker-compose binary with a few extras. 
* _launch_ - which builds the application and then lanuches it
* _relaunch_ - which will stop a running compose stack, download the changes, rebuild and relaunch
* _clean_all_ - which will stop and remove all running containers and then remove all images  

##### --github
This is the Github project and repository you wish to build, i.e `chudsonwr/sample_app`  

##### --version
This is either the git commit hash or the branch you would like to build  
  
##### --proxy
Boolean switch to run the reverse proxy. (allows you to run multiple containers behind the same TCP port using host headers)


#### Example
`ruby bin/provision.rb --github chudsonwr/sample_app --version master --proxy --action launch`

`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action config`

`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action logs`

`ruby bin/provision.rb --github chudsonwr/sample_app --version 00436fdece9a843536845027c2521d208615cbfc --proxy --action launch`

`ruby bin/provision.rb --github chudsonwr/sample_app --version 00436fdece9a843536845027c2521d208615cbfc --proxy --action logs`  


`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action down`

`ruby bin/provision.rb --github chudsonwr/sample_app --version 00436fdece9a843536845027c2521d208615cbfc --proxy --action down`

`ruby bin/provision.rb --github chudsonwr/sample_app --version master --proxy --action clean_all`
  
    
## Setup
To setup dependencies on your local environment run `scripts/setup_local_env.sh`  

## Issues

The docker-compose file for the application you're building MUST conform to certain criteria:

* It must have a service called `web` which refers to the main website part of the application

* If it uses a database, must have a service called `db`.
(this will get renamed locally as per the version you're building from git)

The docker-compose file can remain static between versions (branches/commits etc) as the tool will update them to be unique.  

## To Do

* Add more unit tests
* Add some mocking/stubbing in order to increase test coverage
