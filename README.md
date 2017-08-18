# cbm-gateway
Condition-Based Monitoring Gateway
---------
This is a program designed to use Vimana Enrich intervals posted to an MTConnect agent to calculate any change
in remaining useful life and other machine metrics. The program then returns the data to the MTConnect agent for
use in other programs, i.e. a dynamic scheduler.

These instructions are designed for Mac OS X and Linux. Windows machines will require different procedures to install.


There are two things that need to be installed:

1. Ruby
2. CBM Gateway (and requisite Ruby gems)

Install Ruby
-------

1. Start a new terminal session
2. Use the following command to get the latest ruby version:

          sudo apt-get install ruby-full

Install CBM Gateway
-------

*Make sure you can access the internet!*

1. Clone the git repository into desired path.
2. Install ruby bundler by running the following command:

          gem install bundler
          
   Then install the requisite gems by running bundler:
   
          bundle install
          
3. Configure the gateway


  * Open config/device_data.yaml in any text editor
    * Edit device name and values to provide starting values for each device
  * Open config/agents.yaml in any text editor
    * Add one line per device you want to collect information from
  * Open bin/start_gateway.sh in any text editor
    * Edit the paths to correspond to the location of the cbm-gateway on your machine
    
4. The CBM Gateway will listen on port 7979. Update the MTConnect Agent config files.
  * Put the following under the adapter section:

          cbm {
              Device = <insert device name>
              Host = <insert CBM Gateway host name>
              Port = 7979
            }
          
5. Start the gateway

  * Run bin/start_gateway.sh
  
Information
--------
There are 3 configuration files inside the config directory:

* agents.yaml: sets up where information is to be found for each device
* device_data.yaml: sets up initial data values for each device. This YAML file will be updated while the gateway
is running, so that the gateway retains the last calculated statistics.
* logging.yaml: sets log outputs and logging levels

Logging files can be found in the log directory. There are 2 log files:

* config.log records configuration values
* cbm_gateway.log records activity when the gateway is running

There will also be recovery files for each device. This stores the instance # and the sequence # of last EQUIPMENT_TIMER request for the device.
* Recover_\<device name\>_\<url\>.dat

Troubleshooting
-------

Potential issues:
1. The recovery files store the time instance when the program exits. If the agent is no longer storing
data from that time instance, it will display an MTConnect error and disconnect for 10 seconds. This is resolved
by waiting out the 10 seconds, after which the program will reconnect from the latest sequence # and the recovery files will be updated.

2. If the machine running the MTConnect agent is unavailable, a connection error will occur.

3. If there are multiple instances of the gateway in use, a port in use error will occur. If you see this error,
check to make sure that you only have one running instance of the gateway. 

If necessary, you can increase the log level.

1. Edit logging.yaml
2. Change level to DEBUG
  
        level: Debug
        
3. Change the output to console

        file: STDOUT
        
4. Run using the start script as before.