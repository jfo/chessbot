require_relative "chesscontroller.rb"

require 'pry'

class StreamGame < ChessController

  attr_reader :stream, :topic

  def initialize(stream, topic)
    @stream = stream
    @topic = topic
    super
  end

  def send(response)
    @@client.send_message(@topic, response, @stream)
  end

end

binding.pry
