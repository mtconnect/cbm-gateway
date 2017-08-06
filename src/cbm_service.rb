$: << '.'
require 'adapter'

$: << File.dirname(__FILE__)

require 'rbconfig'
require 'rubygems'
#in case gateway is run on a Windows machine
if RUBY_PLATFORM =~ /mingw32/
  require 'win32/daemon'
  require 'win32/service'
  require 'win32/registry'
end

begin

  $gateway_env = :production

  if ARGV.length > 0
    service_name = 'CBM Gateway'
    service_display_name = 'CBM Gateway'

    dir = File.expand_path(File.dirname(__FILE__) + "/..")
    ruby = File.join(RbConfig::CONFIG['bindir'], 'rubyw')
    cmd = "#{ruby} -C#{dir} #{File.expand_path(__FILE__)}".tr('/', '\\')

    case ARGV[0].downcase
      when 'install'
        $gateway_env = :install
        require 'configuration'
        require 'logging'
        puts "Installing command: #{cmd}"

        Win32::Service.new(service_name: service_name,
                           display_name: service_display_name,
                           description: service_display_name,
                           start_type: Win32::Service::AUTO_START,
                           binary_path_name: cmd)
        puts 'Service ' + service_name + ' installed'

      when  'update'
        $gateway_env = :install
        require 'configuration'
        require 'logging'
        puts "Updating command: #{cmd}"
        Win32::Service.configure(service_name: service_name,
                                 binary_path_name: cmd)

      when 'uninstall'
        $gateway_env = :install
        require 'configuration'
        require 'logging'
        Win32::Service.delete(service_name)
        puts 'Service ' + service_name + ' deleted'

      when 'run'
        $gateway_env = :run
        require 'main'
        Main.start

      when 'debug'
        puts "Starting debug"
        $gateway_env = :debug
        require 'main'
        Main.start
    end

    exit
  end


  dir = File.expand_path(File.join(File.dirname(__FILE__), "../log"))
  $stdout = open("#{dir}/std_output.log", (File::CREAT | File::WRONLY | File::APPEND))
  $stdout.sync = true
  $stderr = $stdout

  class CollectorDaemon < Win32::Daemon
    def service_init
      puts "Service starting #{Time.now}"
      $stdout.flush
    end

    def service_main(*args)
      Logging.logger.info "Starting service"
      Main.start
    end

    def service_stop
      Logging.logger.info "Stopping service"
      Main.stop
      Logging.logger.warn "Exiting from Main.stop"
      puts "Service stopping #{Time.now}"
      $stdout.flush
    end

    def service_pause
      Logging.logger.info "Stopping paused, ignoring"
    end

    def service_resume
      Logging.logger.info "Stopping resumed, ignoring"
    end
  end


rescue SystemExit

rescue Exception => e
  puts "Exception occurred in service: #{e}"
  if e.backtrace
    puts "#{e.backtrace.join("\n")}"
  end
  require 'logging'
  Logging.logger.error   "#{e}\n#{e.backtrace.join("\n")}"
  exit(1)
end

