require 'chess'
require 'zulip'

class ChessController

  attr_accessor :game, :flip, :client

  @@client = Zulip::Client.new do |config|
    config.email_address = ENV['chessbot_email']
    config.api_key = ENV["chessbot_api_key"]
  end

  @@pieces = {  'r' => '♜',
              'n' => '♞',
              'b' => '♝',
              'q' => '♛',
              'k' => '♚',
              'p' => '♟',
              'P' => '♙',
              'R' => '♖',
              'N' => '♘',
              'B' => '♗',
              'Q' => '♕',
              'K' => '♔',
              '.' => '＿' }

  def init
    @game = Chess::Game.new
    @flip = false
  end

  def print_board

      board = @game.board.to_s.split("\e").reject {|e| e.length < 6}.map {|s| s.split}.each {|e| e.shift }[0..-2]
      board.map! {|e| e.map! {|p| @@pieces[p] }}
      if @flip == true
        # everything is mutable / life is transient; ephemeral.
        board.reverse!
        board.map! do |row|
          row.reverse
        end
      end
    board.map {|l| l.join('|') }.join("\n")
  end

  def set_up
    @game = Chess::Game.new
  end

end


class PMGame < ChessController

  attr_reader :recipients

  def initialize(recipients)
    init
    @recipients = recipients
  end

  def init
    super
  end

  def send(response)
    @@client.send_private_message(response, *recipients)
  end

end


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
