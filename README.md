# docker-cli
CLI for launching dockerized apps on Ubuntu 16.04 LTS

* Retrieves repo from GitHub based on commit hash or branch
* Creates Docker image
* Launches Docker container.

## Requirements
* Ubuntu 16.04 LTS (though probably works on other *nix variants)
* Docker-ce
* Docker Compose
* Ruby 2.1.3 (probably works on later versions as well)

## Usage
Run the provision.rb executable and supply various command line options.

##### --action
This is the action you would like to perform. It mirrors most actions available to the standard docker-compose binary with a couple extras. 
* _launch_ - which builds the application and then lanuches it
* _relaunch_ - which will stop a running compose stack, download the changes, rebuild and relaunch  

##### --github
This is the Github project and repository you wish to build, i.e `chudsonwr/my_web_app`  

##### --version
This is either the git commit hash or the branch you would like to build  
  
#### Example
`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action launch`

`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action config`

`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action down`
  
    
## Setup
To setup dependencies on your local environment run `scripts/setup_local_env.sh`


