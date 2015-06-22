import GLib, Gst from require 'lgi'

class GST
  new:=>
    import \bus_callback, \idle_callback from @
    @idles={}
    @cbs={}
    @current_tags={}
    @current_state="NULL"
    @main_loop = GLib.MainLoop!
    GLib.idle_add GLib.PRIORITY_DEFAULT, idle_callback
    @player = Gst.ElementFactory.make "playbin", "play"
    @player.bus\add_watch GLib.PRIORITY_DEFAULT, bus_callback
  bus_callback:(bus, message)=>
    if message.type.ERROR
      print "Error:", message\parse_error!.message
      @main_loop\quit!
    --elseif message.type.EOS
    --  print "end of stream"
    --  @main_loop\quit!
    elseif message.type.STATE_CHANGED
      old, new, pending = message\parse_state_changed!
      --print "state changed: %s->%s:%s"\format old, new, pending
      @current_state=new
    elseif message.type.TAG then
      @current_tags={}
      message\parse_tag!\foreach (list, tag)->
        ts=tostring list\get tag
        @current_tags[tag]=ts
        --print "tag: %s = %s"\format tag, ts
    for fun in *@cbs
      fun @,message
    return true
  idle_callback:=>
    for fun in *@idles
      fun @
    return true
  addIdle:(idle)=>
    @idles[#@idles+1]=idle
    #@idles
  delIdle:(num)=>
    @idles[num]=nil
  addCB:(cb)=>
    @cbs[#@cbs+1]=cb
    #@cbs
  delCB:(num)=>
    @cbs[num]=nil
  setURI:(uri)=>
    @player.uri = uri
  setState:(state)=>
    @current_state=state
    @player.state=state
  play:(uri)=>
    if uri
      @setURI uri
    @setState "PLAYING"
  stop: => @setState "NULL"
  mainLoop:=>
    @main_loop\run!
    @stop!

