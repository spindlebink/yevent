# YEvent

YEvent is a tiny (~100 LOC), speedy, compile-time type-safe event system in Crystal.

* *Tiny:* it's tiny.
* *Speedy:* metaprogramming allows us to keep callbacks in type-specific arrays, which means type-checking is done at compile time and runtime iteration is purely index-based, no lookups.
* *Type-safe:* it catches event type errors and correctly type-restricts callbacks, since it doesn't use `:symbol` keys or `"string event names"`, and it requires event structs to be marked as such.
* *Event system:* attach callbacks for a type of event to objects, then emit the event, and each callback triggers, receiving the event struct as an argument.
* *In Crystal:* the loveliest programming language

```crystal
struct EventType
  include YEvent::Event

  def initialize(@value = 10)
  end

  def do_thing
    puts "Doing the thing: #{@value}"
  end
end

class ListeningObject
  include YEvent::Listener
end

class OtherObject
  # `ListenFor` annotation allows you to connect instance methods at declaration
  @[ListenFor(EventType)]
  def custom_listener(target, event)
    event.do_thing
  end
end

object = ListeningObject.new

object.listen_for EventType do |target, event|
  # `target` is the receiver of the event; `event` is the event instance
  event.custom_method
end

object.listening_for? EventType # true

object.emit_event EventType.new(50)
```

## Type-safe goodies

YEvent's predecessor used an `Event` type and a hash table of symbols mapping to stored callbacks. It worked fine and was transparent and simple, but there was a lurking sense of danger and boilerplate attached to listener code, since events were sent as `Event+`:
```crystal
object.listen_for :event_name do |event|
  if event.is_a? DesiredEventType
    event.now_we_can_do_stuff
  else
    puts "how did a non-DesiredEventType even get in here??"
  end
end
```
Forget to add the check even once and exceptions could creep in, but only down the line, long after I'd forgotten not to forget that I'd forgotten to add the check.

There was also the issue that listener keys were easy to slip up:
```crystal
object.listen_for :mouse_wheel_eevent do |event|
end
```
Passing the wrong name to a method like this would silently add it to the listener table, and adding validation in the form of, say, `Event.register_event_name :event_name` would be a point of friction as more events need to be kept track of and their associated validation steps need to be adhered to.

With metaprogramming, YEvent generates type-specific callback arrays and listener methods at compile time, which means both that listener blocks are correctly type-restricted (i.e. no casting to a specific event type necessary) and that the compiler checks listener methods at compile time against valid event types.


## License

```
Copyright © 2022 Stanaforth (@spindlebink)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
