require 'spec_helper'
require 'rubygems'
require 'uri'
require 'net/http'

module Hydrant
  describe Felixwrapper do    
    context "integration" do
      before(:all) do
        $stderr.reopen("/dev/null", "w")
        felix_params = {
          :felix_home => File.expand_path("#{File.dirname(__FILE__)}/../../felix"),
	  :felix_port => '8080',
          :startup_wait => 300
        }
        Felixwrapper.configure(felix_params) 
      end
      
      it "starts" do
        ts = Felixwrapper.instance
        ts.logger.debug "Stopping felix from rspec."
        ts.stop
        ts.start      
        ts.logger.debug "Felix started from rspec at #{ts.pid}"
        pid_from_file = File.open( ts.pid_path ) { |f| f.gets.to_i }
        ts.pid.should eql(pid_from_file)
      
        # Can we connect to matterhorn?
        require 'net/http' 
        response = Net::HTTP.get_response(URI.parse("http://localhost:#{ts.port}/login.html"))
        response.code.should eql("200")
        ts.stop
      
      end
      
      it "won't start if it's already running" do
        ts = Felixwrapper.instance
        ts.logger.debug "Stopping felix from rspec."
        ts.stop
        ts.start
        ts.logger.debug "Felix started from rspec at #{ts.pid}"
        response = Net::HTTP.get_response(URI.parse("http://localhost:#{ts.port}/login.html"))
        response.code.should eql("200")
        lambda { ts.start }.should raise_exception(/Server is already running/)
        ts.stop
      end
      
      it "can check to see whether a port is already in use" do
        ts = Felixwrapper.instance
        ts.logger.debug "Stopping felix from rspec."
        ts.stop
	sleep 30
	#FIXME following test fails inexplicably!!!
        Felixwrapper.is_port_in_use?(ts.port).should eql(false)
	ts.start
        Felixwrapper.is_port_in_use?(ts.port).should eql(true)
	ts.stop
      end
      
      it "raises an error if you try to start a felix that is already running" do
        ts = Felixwrapper.instance
        ts.stop
        ts.pid_file?.should eql(false)
        ts.start
        lambda{ ts.start }.should raise_exception
        ts.stop
      end

    end
  end
end
