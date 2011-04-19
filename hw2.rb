class SmithWatermann
  # ANDQC
  # 
  # RND-C 

  GAP_PENALTY = 4
  INDEX = ['A','R','N','D','C','Q','E','G','H','I','L','K','M','F','P','S','T','W','Y','V','B','Z','X']
  BLOSUM62 = [
    [ 4, -1, -2, -2,  0, -1, -1,  0, -2, -1, -1, -1, -1, -2, -1,  1,  0, -3, -2,  0, -2, -1,  0 ],
    [ -1,  5,  0, -2, -3,  1,  0, -2,  0, -3, -2,  2, -1, -3, -2, -1, -1, -3, -2, -3, -1,  0, -1 ], 
    [ -2,  0,  6,  1, -3,  0,  0,  0,  1, -3, -3,  0, -2, -3, -2,  1,  0, -4, -2, -3,  3,  0, -1 ],
    [ -2, -2,  1,  6, -3,  0,  2, -1, -1, -3, -4, -1, -3, -3, -1,  0, -1, -4, -3, -3,  4,  1, -1 ],
    [  0, -3, -3, -3,  9, -3, -4, -3, -3, -1, -1, -3, -1, -2, -3, -1, -1, -2, -2, -1, -3, -3, -2 ],
    [ -1,  1,  0,  0, -3,  5,  2, -2,  0, -3, -2,  1,  0, -3, -1,  0, -1, -2, -1, -2,  0,  3, -1 ],
    [ -1,  0,  0,  2, -4,  2,  5, -2,  0, -3, -3,  1, -2, -3, -1,  0, -1, -3, -2, -2,  1,  4, -1 ],
    [  0, -2,  0, -1, -3, -2, -2,  6, -2, -4, -4, -2, -3, -3, -2,  0, -2, -2, -3, -3, -1, -2, -1 ],
    [ -2,  0,  1, -1, -3,  0,  0, -2,  8, -3, -3, -1, -2, -1, -2, -1, -2, -2,  2, -3,  0,  0, -1 ],
    [ -1, -3, -3, -3, -1, -3, -3, -4, -3,  4,  2, -3,  1,  0, -3, -2, -1, -3, -1,  3, -3, -3, -1 ],
    [ -1, -2, -3, -4, -1, -2, -3, -4, -3,  2,  4, -2,  2,  0, -3, -2, -1, -2, -1,  1, -4, -3, -1 ],
    [ -1,  2,  0, -1, -3,  1,  1, -2, -1, -3, -2,  5, -1, -3, -1,  0, -1, -3, -2, -2,  0,  1, -1 ],
    [ -1, -1, -2, -3, -1,  0, -2, -3, -2,  1,  2, -1,  5,  0, -2, -1, -1, -1, -1,  1, -3, -1, -1 ],
    [ -2, -3, -3, -3, -2, -3, -3, -3, -1,  0,  0, -3,  0,  6, -4, -2, -2,  1,  3, -1, -3, -3, -1 ],
    [ -1, -2, -2, -1, -3, -1, -1, -2, -2, -3, -3, -1, -2, -4,  7, -1, -1, -4, -3, -2, -2, -1, -2 ],
    [  1, -1,  1,  0, -1,  0,  0,  0, -1, -2, -2,  0, -1, -2, -1,  4,  1, -3, -2, -2,  0,  0,  0 ],
    [  0, -1,  0, -1, -1, -1, -1, -2, -2, -1, -1, -1, -1, -2, -1,  1,  5, -2, -2,  0, -1, -1,  0 ],
    [ -3, -3, -4, -4, -2, -2, -3, -2, -2, -3, -2, -3, -1,  1, -4, -3, -2, 11,  2, -3, -4, -3, -2 ],
    [ -2, -2, -2, -3, -2, -1, -2, -3,  2, -1, -1, -2, -1,  3, -3, -2, -2,  2,  7, -1, -3, -2, -1 ],
    [  0, -3, -3, -3, -1, -2, -2, -3, -3,  3,  1, -2,  1, -1, -2, -2,  0, -3, -1,  4, -3, -2, -1 ],
    [ -2, -1,  3,  4, -3,  0,  1, -1,  0, -3, -4,  0, -3, -3, -2,  0, -1, -4, -3, -3,  4,  1, -1 ],
    [ -1,  0,  0,  1, -3,  3,  4, -2,  0, -3, -3,  1, -1, -3, -1,  0, -1, -3, -2, -2,  1,  4, -1 ],
    [  0, -1, -1, -1, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -2,  0,  0, -2, -1, -1, -1, -1, -1 ]
  ] 

  def initialize(first_dna, second_dna)
    @first_dna = " #{first_dna.upcase}"
    @second_dna = " #{second_dna.upcase}"

    @score = Array.new(@first_dna.length) { Array.new(@second_dna.length, 0) }
  end

  #Does the main logic of filling in score matrix
  def run
    (1...@first_dna.length).each do |i|
      (1...@second_dna.length).each do |j|
        @score[i][j] = [0, match(i,j), delete(i,j), insert(i,j)].max
      end
    end

    traceback

    p @second_dna
    @score.each {|i| p i }
  end

  def traceback
    p @score

    i = 0
    j = 0

    max = 0
    maxI = 0
    maxJ = 0

    while (i < @first_dna.length)
      while(j < @second_dna.length)
        if (max < @score[i][j])
          max = @score[i][j]
          maxI = i
          maxJ = j
        end
        j+=1
      end
      i+=1
      j = 0
    end

    puts "Highest value is " + max.to_s + " at " + maxI.to_s + " " + maxJ.to_s
    i = maxI
    j = maxJ
    top_string = @first_dna[maxI,1]
    
    if ismatch?(maxI, maxJ)
      mid_string = @first_dna[maxI,1].to_s
    else
      mid_string = '+'
    end 
    
    bot_string = @second_dna[maxJ,1]

    while (true)
      up = @score[i-1][j]
      p 'upscale is' + up.to_s
      left = @score[i][j-1]
      p 'leftscore is' + left.to_s
      maxUpLeft = [up, left].max
      # is it a match/mismatch?
      valMatch = @score[i - 1][j - 1]
      if (valMatch >= maxUpLeft)
 
        p 'Match or Positive Mismatch'
        i = i - 1
        j = j - 1
        if (valMatch <= 0)
          break
        end
        top_string = @first_dna[i,1].to_s + top_string.to_s
        bot_string = @second_dna[j,1].to_s + bot_string.to_s
        if ismatch?(i, j)
          mid_string = @first_dna[i,1].to_s + mid_string.to_s
        elsif blosum_score(i, j) > 0
          mid_string = '+' + mid_string.to_s
        else
          mid_string = ' ' + mid_string.to_s
        end 
      elsif up > left
        p 'Chose up path'
        i = i-1
        j = j
        top_string = @first_dna[i,1].to_s + top_string.to_s
        bot_string = '-' + bot_string.to_s
        mid_string = ' ' + mid_string.to_s
      else
        p 'Chose left path'
        i = i
        j = j - 1
        top_string = '-' + top_string.to_s
        bot_string = @second_dna[j,1].to_s + bot_string.to_s
        mid_string = ' ' + mid_string.to_s
      end
      if (i == 0 && j == 0)
        break
      end
      if (@score[i][j] == 0)
        break 
      end
    end
     strTop = j.to_s + ' ' + bot_string
     strBot = i.to_s + ' ' + top_string
     p strTop
     p '  ' + mid_string
     p strBot
  end

  def ismatch?(i, j)
    @first_dna[i] == @second_dna[j]
  end
 
  def match(i, j)
    @score[i - 1][j - 1] + blosum_score(i, j)
  end

  def delete(i, j)
    @score[i - 1][j] - GAP_PENALTY
  end

  def insert(i, j)
    @score[i][j-1] - GAP_PENALTY
  end

  def blosum_score(i, j)
    BLOSUM62[INDEX.index(@first_dna[i,1])][INDEX.index(@second_dna[j,1])]
  end
end

if __FILE__ == $0
  # Uh - right now first should be SECOND (aka bottom)
  # and second is first - aka TOP string. crazy, right?
  sw = SmithWatermann.new('deadly', 'ddgearlyk')
  sw.run
end

