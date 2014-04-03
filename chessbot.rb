require 'chess'
require 'zulip'

@client = Zulip::Client.new do |config|
  config.email_address = "YOUR BOT'S EMAIL ADDRESS"
  config.api_key = "YOUR BOT'S API KEY"
end

load "./zulip_api_vars.rb" if File.exist?("./zulip_api_vars.rb")

# @client.send_message("chessbot", ":grin:",  "chessbot")

@game = Chess::Game.new
@flip = false
@games = {}
@pieces = { 'r' => '♜',
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

def send_board(topic, board = Chess::Game.new.board, stream)
  board = board.to_s.split("\e").reject {|e| e.length < 6}.map {|s| s.split}.each {|e| e.shift }[0..-2]
  board.map! {|e| e.map! {|p| @pieces[p] }}
  if @flip == true
    # everything is mutable / life is transient; ephemeral.
    board.reverse!
    board.map! do |row|
      row.reverse
    end
  end
  board = board.map {|l| l.join('|') }.join("\n")
  # @client.send_message("chessbot", board,  "chessbot")
  @client.send_message(topic, board,  stream)
  # @client.send_private_message(board, "jeffowler@gmail.com")
end


@client.stream_messages do |message|

  p message
  puts
  stream = "chessbottest"
  topic = message.subject
  @games[topic] ||= Chess::Game.new

  if message.sender_email != 'chess-bot@students.hackerschool.com'
    if !message.content.scan(/```.+```/).empty?
      my_move = message.content.scan(/```.+```/).join.slice(3..-4).strip
      if my_move == "start"
        @games[topic] = Chess::Game.new if my_move == "start"
        @flip = false
        send_board(topic, @games[topic], stream)
      elsif my_move == "peek"
        send_board(topic, @games[topic], stream)
      else
        begin
          @games[topic].move(my_move)
        rescue Chess::IllegalMoveError
          # @client.send_message("chessbot", 'That is not a legal move!', 'chessbot' )
        rescue Chess::BadNotationError
          # @client.send_message("chessbot", "Malformed notation", "chessbot")
        else
          @flip = !@flip
          # @client.send_message("chessbot", 'Check!', "chessbot") if @game.board.check?
          if @games[topic].board.checkmate?
            # @client.send_message("chessbot", 'Checkmate!', "chessbot") if @game.board.check?
          end
        send_board(topic, @games[topic], stream)
        end
      end
    end
  end
end
