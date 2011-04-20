require 'logger'
require 'net/http'


class Permuter
  def initialize(first_dna, second_dna, points)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN
    @true_score = points
    @first_dna = "#{first_dna.upcase}"
    @second_dna = "#{second_dna.upcase}"
  end
  
  def permute(n)
    counter = n
    k = 0
    while (counter > 0)
      permuted_dna = @first_dna
      (0...permuted_dna.length).each do |i|
        j = rand(i)
        tmp = permuted_dna[i]
        permuted_dna[i] = permuted_dna[j]
        permuted_dna[j] = tmp
      end
      sw = SmithWatermann.new(permuted_dna, @second_dna)
      counter -= 1
      if (sw.get_max > @true_score)
        k+=1
      end
    end
    pval = (Float(k+1) / Float(n+1))
    @logger.debug('pVal ' + pval.to_s + ' over ' + n.to_s + ' permutations')
    return pval
  end
end

class SmithWatermann
  class Score
    def initialize(x, y)
      @y = y
      @score = Array.new(x*y, 0)
    end

    def [](i, j)
      @score[i*@y + j]
    end

    def []=(i, j, val)
      @score[i*@y + j] = val
    end
    
    def subseq(i)
      return @score[i*@y..(((i+1)*@y)-1)]
    end

    def max
      max = @score.max
      i, j = @score.index(max).divmod(@y)
      [max, i, j]
    end

    def to_s
      @score.inspect
    end
  end

  GAP_PENALTY = 4
  INDEX = %w[ A R N D C Q E G H I L K M F P S T W Y V B Z X ]
  BLOSUM62 = [
    [  4, -1, -2, -2,  0, -1, -1,  0, -2, -1, -1, -1, -1, -2, -1,  1,  0, -3, -2,  0, -2, -1,  0 ],
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
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN
    
    @first_dna = " #{first_dna.upcase}"
    @second_dna = " #{second_dna.upcase}"
    
    @score = Score.new(@first_dna.length, @second_dna.length)
    (1...@first_dna.length).each do |i|
      (1...@second_dna.length).each do |j|
        @score[i,j] = [0, match(i,j), delete(i,j), insert(i,j)].max
      end
    end
  end

  def get_max
    @logger.debug(@score)
    max, i, j = @score.max
    return max
  end
  
  def print_score
    j = 0
    outputline = "  "
    @second_dna.each_char do |x|
      outputline += ' ' + x.to_s + ' '
    end
    p outputline
    
    while j < @first_dna.length
      subseq = @score.subseq(j)
      outputline = ""
      subseq.each do |x|
        outputline += ' ' + x.to_s + ' '
      end
      p "#{@first_dna[j,1]} #{outputline}"
      j+=1
    end
  end
  
  def print(first_prefix, second_prefix)
    max, i, j = @score.max
    @logger.debug("Highest value is #{max} at #{i} #{j}")
    top_string = @first_dna[i].chr
    bot_string = @second_dna[j].chr
    mid_string = (top_string == bot_string) ? @first_dna[i].chr : '+'

    while (true)
      up = @score[i-1, j]
      @logger.debug("upscore is #{up}")
      left = @score[i, j-1]
      @logger.debug("leftscore is #{left}")
      maxUpLeft = [up, left].max
      # is it a match/mismatch?
      valMatch = @score[i-1, j-1]

      if (valMatch >= maxUpLeft)
 
        @logger.debug('Match or Positive Mismatch')
        i -= 1
        j -= 1
        if (valMatch <= 0)
          break
        end
        top_string << @first_dna[i].chr
        bot_string << @second_dna[j].chr
        if ismatch?(i, j)
          mid_string << @first_dna[i].chr
        elsif blosum_score(i, j) > 0
          mid_string << '+'
        else
          mid_string << ' '
        end 
      elsif up > left
        @logger.debug('Chose up path')
        i -= 1
        top_string << @first_dna[i].chr
        bot_string << '-'
        mid_string << ' '
      else
        @logger.debug('Chose left path')
        j -= 1
        top_string << '-'
        bot_string << @second_dna[j].chr
        mid_string << ' '
      end

      break if (i == 0 && j == 0)
      break if (@score[i, j] == 0)
    end

    top_string.reverse!
    mid_string.reverse!
    bot_string.reverse!
    
    first_prefix = "#{first_prefix} #{i} "
    second_prefix = "#{second_prefix} #{j} "
    
    prefixBuffer = [first_prefix.length, second_prefix.length].max
    top_prefix = second_prefix.center(prefixBuffer)
    bot_prefix = first_prefix.center(prefixBuffer)

    mid_skip_char = " ".center([top_prefix.length, bot_prefix.length].max - 1)
    
    
    
    strTop = "#{bot_string}"
    strBot = "#{top_string}"
    strMid = " #{mid_string}"
  
    lines = [strTop.length, strMid.length, strBot.length].max / 60
    i = 0
    while i <= lines
      pos = i*60
      p "#{bot_prefix}" + strTop[pos, pos+60]
      p "#{mid_skip_char}" + strMid[pos, pos+60]
      p "#{top_prefix}" + strBot[pos, pos+60]
      i+=1
    end
    
    @logger.debug(@score)
  end

  def ismatch?(i, j)
    @first_dna[i] == @second_dna[j]
  end
 
  def match(i, j)
    @score[i-1, j-1] + blosum_score(i, j)
  end

  def delete(i, j)
    @score[i-1, j] - GAP_PENALTY
  end

  def insert(i, j)
    @score[i, j-1] - GAP_PENALTY
  end

  def blosum_score(i, j)
    BLOSUM62[INDEX.index(@first_dna[i].chr)][INDEX.index(@second_dna[j].chr)]
  end
end

def get_fasta(code)
  html = Net::HTTP.get URI.parse("http://www.uniprot.org/uniprot/#{code}.fasta")
  html = html.split(%r{\n})
  dna = ""
  html.each_index do |i|
    unless i == 0
      dna = dna + html[i]
    end
  end
  return dna
end

TESTDATA = [['TEST1','ddgearlyk'],['TEST2','deadly']]

REALDATA = %w[P15172 P17542 P10085 P16075 P13904 Q90477 Q8IU24 P22816 Q10574 O95363]

# FLAGS for assignment. DO_TEST works on 'deadly v ddgearlyk'
# DO_ALIGN works on aligning all proteins in REALDATA
# DO_PVAL calculates the pval for a couple proteins on 1000 permutations
DO_TEST = 1
DO_ALIGN = 1
DO_PVAL = 0

#DNASET = [['P15172','MELLSPPLRDVDLTAPDGSLCSFATTDDFYDDPCFDSPDLRFFEDLDPRLMHVGALLKPEEHSHFPAAVHPAPGAREDEHVRAPSGHHQAGRCLLWACKACKRKTTNADRRKAATMRERRRLSKVNEAFETLKRCTSSNPNQRLPKVEILRNAIRYIEGLQALLRDQDAAPPGAAAAFYAPGPLPPGRGGEHYSGDSDASSPRSNCSDGMMDYSGPPSGARRRNCYEGAYYNEAPSEPRPGKSAAVSSLDCLSSIVERISTESPAAPALLLADVPSESPPRRQEAAAPSEGESSGDPTQSPDAAPQCPAGANPNPIYQVL'],
#          ['P17542','MTERPPSEAARSDPQLEGRDAAEASMAPPHLVLLNGVAKETSRAAAAEPPVIELGARGGPGGGPAGGGGAARDLKGRDAATAEARHRVPTTELCRPPGPAPAPAPASVTAELPGDGRMVQLSPPALAAPAAPGRALLYSLSQPLASLGSGFFGEPDAFPMFTTNNRVKRRPSPYEMEITDGPHTKVVRRIFTNSRERWRQQNVNGAFAELRKLIPTHPPDKKLSKNEILRLAMKYINFLAKLLNDQEEEGTQRAKTGKDPVVGAGGGGGGGGGGAPPDDLLQDVLSPNSSCGSSLDGAASPDSYTEEPAPKHTARSLHPAMLPAADGAGPR'],          [],
#          [],
#          [],
if __FILE__ == $0
  # Uh - right now first should be SECOND (aka bottom)
  # and second is first - aka TOP string. crazy, right?
  #sw = SmithWatermann.new('deadly', 'ddgearlyk')
  #perm = Permuter.new('deadly', 'ddgearlyk', sw.run)
  if DO_TEST == 1
    (0...TESTDATA.length).each do |i|
      (i+1...TESTDATA.length).each do |j|
        sw = SmithWatermann.new(TESTDATA[i][1], TESTDATA[j][1])
        perm = Permuter.new(TESTDATA[i][1], TESTDATA[j][1], sw.get_max)
        p "Pval of TESTCASE on 1000 permutations is: #{perm.permute(1000)}"
        sw.print(TESTDATA[i][0], TESTDATA[j][0])
        sw.print_score
      end
    end
  end
  
  if DO_ALIGN == 1
    (0...REALDATA.length).each do |i|
      (i+1...REALDATA.length).each do |j|
        dna1 = get_fasta(REALDATA[i])
        dna2 = get_fasta(REALDATA[j])
        sw = SmithWatermann.new(dna1, dna2)
      
        p "Matching DNA #{REALDATA[i]} #{REALDATA[j]}"
        sw.print(REALDATA[i], REALDATA[j])
      end
    end
  end
  
  if DO_PVAL == 1
    sw = SmithWatermann.new(get_fasta('Q10574'),get_fasta('P15172'))
    perm = Permuter.new(get_fasta('Q10574'),get_fasta('P15172'), sw.get_max)
    p "Pval of P15172 : Q10574 on 1000 permutations is: #{perm.permute(1000)}"
    
    sw = SmithWatermann.new(get_fasta('O95363'),get_fasta('P15172'))
    perm = Permuter.new(get_fasta('O95363'),get_fasta('P15172'), sw.get_max)
    p "Pval of P15172 : O95363 on 1000 permutations is: #{perm.permute(1000)}"
  end
  
end

