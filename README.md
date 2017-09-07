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
Run the provision.rb executable and supply various command line options.

##### --action
This is the action you would like to perform. It mirrors most actions available to the standard docker-compose binary with a couple extras. 
* _launch_ - which builds the application and then lanuches it
* _relaunch_ - which will stop a running compose stack, download the changes, rebuild and relaunch  

##### --github
This is the Github project and repository you wish to build, i.e `chudsonwr/sample_app`  

##### --version
This is either the git commit hash or the branch you would like to build  
  
#### Example
`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action launch`

`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action config`

`ruby bin/provision.rb --github chudsonwr/sample_app --version master --action down`

`ruby bin/provision.rb --github chudsonwr/sample_app --version bae426569acf019e4f38e03d08f4d632858ae51a --action launch`

`ruby bin/provision.rb --github chudsonwr/sample_app --version bae426569acf019e4f38e03d08f4d632858ae51a --action down`
  
    
## Setup
To setup dependencies on your local environment run `scripts/setup_local_env.sh`  

## Issues

The docker-compose file for the application you're building MUST conform to certain criteria:
* There must be a network named `nginx-proxy`. 
  ```
  networks:
    default:
      external:
        name: nginx-proxy
  ```

* It must have an environments element with a `VIRTUAL_HOST=` value inside an array. 
(The value of this variable does not matter as it's set by the tool)
  ```
  environment:
    - "VIRTUAL_HOST=nginx_test.dev.com"
  ```

* If it uses a database, must have a service called `db`.
(this will get renamed as per the version you're building from git)  

The docker-compose file can remain static between versions (branches/commits etc) as the tool will update them to be unique.  

## To Do

* Put in more testing
* Allow the user to turn on/off the proxy functionality
* Add the `Networks` element to docker-compose.yml files IF proxy is turned on

