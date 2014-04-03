require 'chess'
require 'zulip'

@game = Chess::Game.new
@flip = false
@games = {}

@client = Zulip::Client.new do |config|
  config.email_address = "chess-bot@students.hackerschool.com"
  config.api_key = "Zzho0MVVjYG1UUXmcsS8NsncdqUBNsVR"
end

# @client.send_message("chessbot", "Hello. I am Chessbot. I respond to ```[properly formatted algebraic notation]```, ```peek```, and also ```start```. I'm pretty dumb right now, but you can use my board while I learn to play.", "chess")

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

def send_board(board = Chess::Game.new.board)
  board = board.to_s.split("\e").reject {|e| e.length < 6}.map {|s| s.split}.each {|e| e.shift }[0..-2]
  board.map! {|e| e.map! {|p| @pieces[p] }}
  if @flip == true
    board.reverse!
    board.map! do |row|
      row.reverse
    end
  end
  board = board.map {|l| l.join('|') }.join("\n")
  @client.send_message("chessbot", board,  "chessbot")
  # @client.send_private_message(board, "jeffowler@gmail.com")
end

# @client.send_message("oh noooo", ":cry:" ,"off-topic")


@client.stream_messages do |message|

  # @client.subscribe message.stream
  p message

  if message.sender_email != 'chess-bot@students.hackerschool.com'
    if !message.content.scan(/```.+```/).empty?
      my_move = message.content.scan(/```.+```/).join.slice(3..-4).strip
      if my_move == "start"
        @game = Chess::Game.new if my_move == "start"
        send_board(@game)
        @flip = false
      elsif my_move == "peek"
        send_board(@game)
      else
        begin
          @game.move(my_move)
        rescue Chess::IllegalMoveError
          @client.send_message("chessbot", 'That is not a legal move!', 'chessbot' )
        rescue Chess::BadNotationError
          @client.send_message("chessbot", "Malformed notation", "chessbot")
        else
          @flip = !@flip
          @client.send_message("chessbot", 'Check!', "off-topic") if @game.board.check?
          if @game.board.checkmate?
            @client.send_message("chessbot", 'Checkmate, the game is over!', "chessbot") if @game.board.check?
          end
        end
      send_board(@game)
      end
    end
  end
end
