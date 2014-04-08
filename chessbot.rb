require 'chess'
require 'pry'

class ChessController

  attr_reader :game, :flip

  def initialize
    @game = Chess::Game.new
    @flip = false
  end

  def print_board

  # should I make this a class var or something?
  pieces = { 'r' => '♜',
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

    board = @game.board.to_s.split("\e").reject {|e| e.length < 6}.map {|s| s.split}.each {|e| e.shift }[0..-2]
    board.map! {|e| e.map! {|p| pieces[p] }}
    if @flip == true
      # everything is mutable / life is transient; ephemeral.
      board.reverse!
      board.map! do |row|
        row.reverse
      end
    end
  board.map {|l| l.join('|') }.join("\n")
  end

end

x = ChessController.new
binding.pry
