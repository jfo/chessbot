require 'chess'
require 'zulip'

@client = Zulip::Client.new do |config|
  config.email_address = "YOUR BOT'S EMAIL ADDRESS"
  config.api_key = "YOUR BOT'S API KEY"
end

load "./zulip_api_vars.rb" if File.exist?("./zulip_api_vars.rb")

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

  if fake
    board.map! {|row| row.map! {|p| p == '＿' ? '♕' : p }}
  end

  board = board.map {|l| l.join('|') }.join("\n")
  @client.send_message(topic, board,  stream)
end

def stream_game(message)
  stream = message.display_recipient
  topic = message.subject

  game_key = stream + '::' + topic
  @games[game_key] ||= Chess::Game.new

  if message.sender_email != 'chess-bot@students.hackerschool.com'
    if !message.content.scan(/`[a-zA-Z0-9 ]+`/).empty?
      my_move = message.content.scan(/`[a-zA-Z0-9 ]+`/).join.slice(1..-2).strip
      puts my_move
      if my_move == "start"
        @games[game_key] = Chess::Game.new if my_move == "start"
        @flip = false
        send_board(topic, @games[game_key], stream)
      elsif my_move == "peek"
        send_board(topic, @games[game_key], stream)
      elsif my_move == "halp"
        @client.send_message(topic, '[](http://blog.check-and-secure.com/wp-content/uploads/2014/02/halp.png)', stream)
      elsif my_move == "help"
        @client.send_message(topic, "I respond to the following commands:\n```start``` sets up a new board.\n```peek``` prints out the board again\n```[any properly notated legal move]``` in [algebraic notation](http://en.wikipedia.org/wiki/Algebraic_notation_(chess)) makes the move, flips the board, and prints it out again.\n\nI listen to everything on stream 'chessbot' where every topic gets its own table, but you can call me into any other stream by mentioning me in your messages (including all moves).\n\nCommands must be formatted between backticks to form a markdown code block. I'm not so good at conversation, but I'm a cheerful bot if you'd like to PM me sometime!", stream)
      else
        begin
          @games[game_key].move(my_move)
        rescue Chess::IllegalMoveError
          @client.send_message(topic, 'That is not a legal move!', stream)
        rescue Chess::BadNotationError
          @client.send_message(topic, 'Malformed notation.', stream)
        else
          @flip = !@flip
          @client.send_message(topic, 'Check!', stream) if @game.board.check?
          if @games[game_key].board.checkmate?
          @client.send_message(topic, 'Checkmate!', stream) if @game.board.checkmate?
          end
        send_board(topic, @games[game_key], stream)
        end
      end
    end
  end
end

@client.stream_messages do |message|
  p message
  puts

  if message.type == "stream"
    stream_game(message)
  else
    if message.sender_email != 'chess-bot@students.hackerschool.com'
      @client.send_private_message(":grin:",  message.sender_email)
    end
  end
end
