require 'chess'
require 'zulip'

@game = Chess::Game.new
@flip = false

@client = Zulip::Client.new do |config|
  config.email_address = "chess-bot@students.hackerschool.com"
  config.api_key = "Zzho0MVVjYG1UUXmcsS8NsncdqUBNsVR"
end
@client.subscribe 'off-topic'

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
  newboard = board.to_s.split("\e").reject {|e| e.length < 6}.map {|s| s.split}.each {|e| e.shift }[0..-2]
  newboard.map! {|e| e.map! {|p| @pieces[p] }}
  if @flip == true
    newboard.reverse!
    newboard.map! do |row|
      row.reverse
    end
  end
  newboard = newboard.map {|l| l.join('|') }.join("\n")
  @client.send_message("chessbot", newboard,  "off-topic")
  # @client.send_private_message(newboard, "jeffowler@gmail.com")
end

send_board

@client.stream_messages do |message|

  if message.sender_email != 'chess-bot@students.hackerschool.com'
    if !message.content.scan(/```.+```/).empty?
      my_move = message.content.scan(/```.+```/).join.slice(3..-4).strip
      @game = Chess::Game.new if my_move == "start"
      send_board(@game) if my_move == "peek"
      begin
        @game.move(my_move) if my_move != 'start' && my_move != 'peek'
      rescue Chess::IllegalMoveError
        @client.send_message("chessbot", 'That is not a legal move!', 'off-topic' )
      rescue Chess::BadNotationError
        @client.send_message("chessbot", "Malformed notation", "off-topic")
      else
        @flip = !@flip
        @client.send_message("chessbot", 'Check!', "off-topic") if @game.board.check?
        if @game.board.checkmate?
          @client.send_message("chessbot", 'Checkmate, the game is over! Type ```start``` to go again :)', "off-topic") if @game.board.check?
        end
        send_board(@game) if my_move != "peek"
      end
    end
  end

end
