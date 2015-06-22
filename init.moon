GST = require "gst"
player=GST!
player\play "file:///home/kyra/Music/skype_bell.wav"
player\addCB (message)=>
  if message.type.STATE_CHANGED
    print "state: %s"\format @current_state
  elseif message.type.EOS
    print "EOS"
    print "restarting..."
    @stop!
    @play!
player\mainLoop!
