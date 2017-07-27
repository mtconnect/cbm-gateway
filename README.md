To: Rewrite to 

Installation Instructions
-------

The files are available from dropbox: https://www.dropbox.com/sh/te3ftw1gg0hkt71/AADvdCrKCHn9QiHr9tUKiEB4a

There are three things that need to be installed

1. Install Ruby using the one click installer
2. Minw32 DevKit to build a few gems
3. B2MML Gateway

Install Ruby
-------

1. Double click rubyinstaller-2.0.0-p481.exe
2. Select English
3. Accept License
4. Accept default path 
5. *Make sure you check "Add Ruby executables to your PATH*
  
Install DevKit
-------

1. Double click DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe
2. Extract to C:\DevKit

Install B2MML Gateway
-------

Make sure you can access the internet

1. Unzip the b2mml-gateway.zip file to C:\
2. Install bundles from command prompt

          C:> cd C:\b2mml-gateway
          C:> bin\install
  
3. Configure the application

  * Open database.yaml in notepad
    * Edit the database configuration to the name of the machine the 
      database is running on
  * Open agents.yaml in notepad
    * Add one line per agent you want to connect to
    
4. Test the configuration

  * Delete the b2mml_gateway.log file from log directory. This was
    created by the installer and is only accessible by administrators

          C:> bin\start
    
    Check the log file and make sure its connecting
    
          I, [2014-06-21T21:38:24.746153 #5658]  INFO -- : tft (http://localhost:5002/) Time to parse: 8.4e-05 (processed 0 at 0 events/second)
          I, [2014-06-21T21:38:25.390358 #5658]  INFO -- : mtc (http://agent.mtconnect.org/) Time to parse: 0.139289 (processed 146 at 1048 events/second)
          I, [2014-06-21T21:38:25.990971 #5658]  INFO -- : mtc (http://agent.mtconnect.org/) Time to parse: 0.127493 (processed 137 at 1074 events/second)
          I, [2014-06-21T21:38:26.195045 #5658]  INFO -- : mtc (http://agent.mtconnect.org/) Time to parse: 0.132677 (processed 128 at 964 events/second)
            

5. Start a command prompt with admin privileges to install service

          C:> cd C:\b2mml_gateway
          C:> bin\install_service

6. Now start the service

  * Open the services in the adimistrator tools
  * Start the B2MML Gateway
  
Troubleshooting
-------

You can log out to the console and increase the log level.

1. Edit logging.yaml
2. Change level to DEBUG
  
        level: Debug
        
3. Change the output to console

        file: STDOUT
        
3. Run using the start script as before. I can't check the oracle connection since 
   I don't have access. That is the biggest unknown for the moment.# cbm-gateway
