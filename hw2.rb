class SmithWatermann
  @@first_dna = 'abc'#'deadly'
  @@second_dna = 'abc'#'ddgearlyk'
  @@gap_penalty = 4


  #Some pretty bad code to build a 2 dimensional array.
  #Should learn some more ruby and clean this up
  def init_score
    score = Array.new(@@first_dna.length)
    i = 0
    while (i < @@first_dna.length)
      score[i] = Array.new(@@second_dna.length)
      i+=1  
    end

    i = 0
    j = 0
    while (i < @@first_dna.length)
      while (j < @@second_dna.length)
        score[i][j] = 0
        j+=1
      end
      i+=1
      j = 0
    end
    return score
  end


  #Does the main logic of filling in score matrix
  def run
    score = init_score()

    i = 1
    j = 1
     
    while (j < @@second_dna.length)
      while (i < @@first_dna.length)
        val = [0, match(score, i, j)].max
        val = [val, delete(score, i, j)].max
        val = [val, insert(score, i, j)].max
        score[i][j] = val
        i+=1
      end
      j+=1
      i = 1
    end   
    puts score
  end

  def ismatch?(i, j)
    if (@@first_dna[i] == @@second_dna[j])
      return true
    else
      return false
    end
  end
 
  def match(score, i, j)
    return score[i - 1][j - 1] + get_score(i, j)
  end

  def delete(score, i, j)
    return score[i - 1][j] - @@gap_penalty
  end

  def insert(score, i, j)
    return score[i][j-1] - @@gap_penalty
  end

  def get_score(i, j)
    return 1
  end

  if __FILE__ == $PROGRAM_NAME
    sw = SmithWatermann.new
    sw.run
  end

end