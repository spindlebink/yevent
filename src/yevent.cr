# The base module.
module YEvent
  # Raised when attempting to pass a type that's not an event type to an event
  # method.
  class InvalidEventError < Exception; end

  # An entity that can listen for and emit events.
  module Listener
    annotation ListenFor
    end
  end

  # An event that can be dispatched to listeners.
  module Event
    macro finished
      {% event_types = [] of MacroID %}
      {% listener_types = [] of {MacroID, TypeNode} %}
      {% for including_type in @type.includers %}
        {% for subclass in including_type.all_subclasses + [including_type] %}
          {% event_types << subclass.id %}
        {% end %}
      {% end %}
      {% for including_type in Listener.includers %}
        {% for subclass in including_type.all_subclasses + [including_type] %}
          {% listener_types << {subclass.id, subclass} %}
        {% end %}
      {% end %}
      {% for listener_type in listener_types %}
        class ::{{listener_type[0]}}
          # :nodoc:
          def listen_for(event_class : Class, &callback : ::YEvent::Listener, ::YEvent::Event -> Nil)
            raise ::YEvent::InvalidEventError.new "#{event_class} is not a valid event type"
          end
          # :nodoc:
          def listening_for?(event_class : Class)
            raise ::YEvent::InvalidEventError.new "#{event} is not a valid event type"
          end
          # :nodoc:
          def num_listeners_for(event_class : Class)
            raise ::YEvent::InvalidEventError.new "#{event} is not a valid event type"
          end
          # :nodoc:
          def emit_event(event)
            raise ::YEvent::InvalidEventError.new "#{event} is not a valid event type"
          end
        {% for event_type in event_types %}
          {% listeners = [] of Def %}
          {% for check_class in listener_type[1].ancestors + [listener_type[1]] %}
            {% for method in check_class.methods %}
              {% if listener_annotation = method.annotation(::YEvent::Listener::ListenFor) %}
                {% if listener_annotation[0].id == event_type.id %}
                  {% listeners << method %}
                {% end %}
              {% end %}
            {% end %}
          {% end %}
          {% if listeners.empty? %}
            @%callbacks{event_type} = [] of ::YEvent::Listener, ::{{event_type}} -> Nil
          {% else %}
            @%callbacks{event_type} : Array(::YEvent::Listener, ::{{event_type}} -> Nil) = [
            {% for method in listeners %}
              ->(target : ::YEvent::Listener, event : ::{{event_type}}) : Nil { target.{{method.name.id}} target, event },
            {% end %}
            ]
          {% end %}

          # Adds a listener for events of type `{{event_type}}`.
          def listen_for(event_class : ::{{event_type}}.class, &callback : ::YEvent::Listener, ::{{event_type}} -> Nil)      
            if !@%callbacks{event_type}.includes? callback
              @%callbacks{event_type} << callback
            end
          end

          # Whether the object has at least one listener for events of type `{{event_type}}`.
          def listening_for?(event_class : ::{{event_type}}.class)
            !@%callbacks{event_type}.empty?
          end

          # The number of listeners for events of type `{{event_type}}`.
          def num_listeners_for(event_class : ::{{event_type}}.class)
            @%callbacks{event_type}.size
          end

          # Emits an event of type `{{event_type}}`, calling any associated callbacks.
          def emit_event(event : ::{{event_type}})
            @%callbacks{event_type}.each do |callback|
              callback.call self, event
            end
          end

          # Removes `callback` from listeners for events of type `{{event_type}}`.
          def stop_listening_for(callback : ::YEvent::Listener, ::{{event_type}} -> Nil)
            @%callbacks{event_type}.delete callback
          end
        {% end %}
          def remove_all_listeners
            {% for event_type in event_types %}
            @%callbacks{event_type}.clear
            {% end %}
          end
        end
      {% end %}
    end
  end
end
