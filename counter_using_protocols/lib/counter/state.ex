defprotocol Counter.State do
  def handle_command(state, command)
  def handle_event(state, event)
end
