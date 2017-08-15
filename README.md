# cbm-gateway
Condition-Based Monitoring Gateway
---------
This is a program designed to use Vimana Enrich intervals posted to an MTConnect agent to calculate any change
in remaining useful life and other machine metrics. The program then returns the data to the MTConnect agent for
use in other programs, i.e. a dynamic scheduler.


There are two things that need to be installed:

1. Ruby
2. CBM Gateway (and requisite Ruby gems)

Install Ruby
-------

1. Start a new terminal session
2. Use the following command to get the latest ruby version:
* sudo apt-get install ruby-full

Install CBM Gateway
-------

Make sure you can access the internet

1. Unzip the cbm-gateway.zip file to chosen directory
2. Install bundles from terminal

          C:> cd C:\cbm-gateway
  
3. Configure the application

  * Open device_data.yaml in any text editor
    * Edit device name and values to provide starting values for the 
  * Open agents.yaml in any text editor
    * Add one line per device you want to collect information from

4. Start the service

  * Open the services in the administrator tools
  * Start the CBM Gateway
  
Troubleshooting
-------

Potential issues:
1. The recovery files store the time instance when the program exits. If the agent is no longer storing
data from that time instance, it will display an MTConnect error and disconnect for 10 seconds. This is resolved
by waiting out the 10 seconds, after which the program will reconnect and the recovery files will be updated.

2. If the machine running the agent is unavailable altogether, all sorts of error mayhem will ensue. There is nothing you can
do about this until the agent machine is online.

3. If there are multiple instances of the gateway in use, there will be an error with port already in use. If you see this error,
check to make sure that you only have one running instance of the gateway. 

You can log out to the console and increase the log level.

1. Edit logging.yaml
2. Change level to DEBUG
  
        level: Debug
        
3. Change the output to console

        file: STDOUT
        
3. Run using the start script as before.