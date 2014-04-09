require "chesscontroller.rb"

class StreamGame < ChessController

  attr_reader :stream, :topic

  def initialize(stream, topic)
    init
    @stream = stream
    @topic = topic
  end
  def init
    super
  end

  def send(response)
    @@client.send_message(@topic, response, @stream)
  end

end
