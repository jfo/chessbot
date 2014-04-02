require 'chess'
require 'zulip'

g = Chess::Game.new

@client = Zulip::Client.new do |config|
  config.email_address = "chess-bot@students.hackerschool.com"
  config.api_key = "Zzho0MVVjYG1UUXmcsS8NsncdqUBNsVR"
end

@pieces =
{
'r' => '♜',
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
'.' => '＿'
}


def send_board(board = Chess::Game.new.board)
  newboard = board.to_s.split("\e").reject {|e| e.length < 6}.map {|s| s.split}.each {|e| e.shift }[0..-2]
  newboard.map! {|e| e.map! {|p| @pieces[p] }}
  newboard = newboard.map {|l| l.join('|') }.join("\n")
  @client.send_private_message(newboard, "jeffowler@gmail.com")
end

send_board(g)

# @client.stream_messages do |message|
# puts message.content
# end
