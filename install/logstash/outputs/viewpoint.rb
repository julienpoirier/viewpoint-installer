# encoding: utf-8
require "logstash/namespace"
require "logstash/environment"
require "logstash/outputs/elasticsearch"
require "stud/buffer"
require "date"

class LogStash::Outputs::Viewpoint < LogStash::Outputs::ElasticSearch

  config_name "viewpoint"
  milestone 1

  public
  def receive(event)
    @logger.debug("Receive event")

    # Will contain the list of unit event
    eventHash = event.to_hash;

    # Clean unwanted field from the cloned
    clonedEvent = event.to_hash.clone
    clonedEvent.delete("event")
    clonedEvent.delete("events")
    clonedEvent["_ttl"] = "7d"

    # Build the events format
    if !eventHash.nil? && eventHash.key?("events") && !eventHash['events'].nil?
      eventHash['events'].each do |subEvent|
      
        # Create a copy of the base
        copy = clonedEvent.clone
                   
        # Add the subevent content
        subEvent.each do |key, value|
          copy[key] = value
        end

        begin
          if copy.key?("date")
            copy["date"] = Time.at(copy["date"]).strftime("%Y%m%dT%H%M%S.%L%z") 
          end
        rescue 
          @logger.info("Unable to convert date")
        end         
                 
        @logger.info("Store an event from events")
        super(LogStash::Event.new(copy))
      end
    end

    # And the event unique structure
    if !eventHash.nil? && eventHash.key?("event") && !eventHash['event'].nil?
      # Create a copy of the base
      copy = clonedEvent.clone
                                             
      # Add the subevent content
      eventHash['event'].each do |key, value|
        copy[key] = value
      end

      begin
        if copy.key?("date")
          copy["date"] = Time.at(copy["date"]).strftime("%Y%m%dT%H%M%S.%L%z")
        end
      rescue
        @logger.info("Unable to convert date")
      end      

      @logger.info("Store an event from event")
      super(LogStash::Event.new(copy))
    end

  end # def receive

end # end LogStash::Outputs::Viewpoint
