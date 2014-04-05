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

def prep_board(board = Chess::Game.new.board)
  board = board.to_s.split("\e").reject {|e| e.length < 6}.map {|s| s.split}.each {|e| e.shift }[0..-2]
  board.map! {|e| e.map! {|p| @pieces[p] }}
  if @flip == true
    # everything is mutable / life is transient; ephemeral.
    board.reverse!
    board.map! do |row|
      row.reverse
    end
  end

  board.map {|l| l.join('|') }.join("\n")
end

def stream_send_board(topic, board, stream)
  @client.send_message(topic, board,  stream)
end

def pm_send_board
end

def stream_game(message)
  stream = message.display_recipient
  topic = message.subject

  game_key = stream + '::' + topic
  @games[game_key] ||= {game:Chess::Game.new, flip:false}

  if message.sender_email != @client.email_address
    if !message.content.scan(/`[a-zA-Z0-9\-]+`/).empty?
      my_move = message.content.scan(/`[a-zA-Z0-9\-]+`/).join.slice(1..-2).strip
      puts my_move
      if my_move == "start"
        @games[game_key][:game] = Chess::Game.new
        @games[game_key][:flip] = false
        stream_send_board(topic, prep_board(@games[game_key][:game]), stream)
      elsif my_move == "peek"
        stream_send_board(topic, prep_board(@games[game_key][:game]), stream)
      elsif my_move == "gg" || my_move == "resign"
        @client.send_message(topic, 'gg!', stream)
        @games[game_key][:game] = Chess::Game.new
        @games[game_key][:flip] =
      elsif my_move == "halp"
        @client.send_message(topic, '[](http://blog.check-and-secure.com/wp-content/uploads/2014/02/halp.png)', stream)
      elsif my_move == "help"
        @client.send_message(topic, "I respond to the following commands:\n```start``` sets up a new board.\n```peek``` prints out the board again\n```[any properly notated legal move]``` in [algebraic notation](http://en.wikipedia.org/wiki/Algebraic_notation_(chess)) makes the move, flips the board, and prints it out again.\n\nI listen to everything on stream 'chessbot' where every topic gets its own table.\n\nCommands must be formatted between backticks to form a markdown code block.", stream)
      else
        begin
          @games[game_key][:game].move(my_move)
        rescue Chess::IllegalMoveError
          @client.send_message(topic, 'That is not a legal move!', stream)
        rescue Chess::BadNotationError
          @client.send_message(topic, 'Malformed notation.', stream)
        else
          @games[game_key][:flip] = !@games[game_key][:flip]
          if @games[game_key][:game].board.checkmate?
            @client.send_message(topic, 'Checkmate!', stream)
          end
          @client.send_message(topic, 'Check!', stream) if @games[game_key][:game].board.check?
        stream_send_board(topic, prep_board(@games[game_key][:game]), stream)
        end
      end
    end
  end
end


def main
  puts "Chessbot is listening"

  @client.stream_messages do |message|

    puts message

    if message.type == "stream"
      stream_game(message)
    elsif message.type == "private"
      # stream_game(message)
    end
  end
end

main
