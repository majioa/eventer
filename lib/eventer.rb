#!/usr/bin/ruby

module Eventer
  class UnknownEventError < StandardError
    def initialize(*args)
      args[0] = "Unregistered event :#{args[0]}" if args[0]
      super(*args)
    end
  end

private

  def add_event(event, &prc)
    event = event.to_sym
    @__events__ = {} unless @__events__
    @__events__[event] = [] unless @__events__[event]
    @__events__[event] << prc unless @__events__[event].include? prc
    true
  end

public

  def event(event, *args)
    res = {}

    if @__events__ && @__events__[event]
      @__events__[event].each do |event_h|
	res[event_h] = event_h.call(*args)
      end
    elsif self.methods.include?( eval ":on_#{event}" )
      return []
    else
      raise UnknownEventError.new event
    end

    res
  end

  def purge_events(*events)
    (events.empty? ? @__events__.keys : events).each do |e|
      self.class.class_eval "undef_method :on_#{e}"
      @__events__.delete(e)
    end
  end

  def purge_handlers(*events)
    if @__events__
      (events.empty? ? @__events__.keys : events).each do |e|
	  @__events__[e].clear if @__events__.key? e
      end
    end
  end

  def event_rs(event, *args)
    event(event, *args).map do |x| x[1..-1] end.flatten
  end

end


class Class

public
  def events(*args)
    include Eventer
    args.map do |e| e.to_sym end.compact.each do |e|
      self.class_eval "def on_#{e}(&block); add_event(:#{e}, &block); end"
    end
  end

end

