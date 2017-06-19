require 'yaml'
require 'faraday'
require 'indico'

# シェルコマンドを子プロセス(非同期)で扱う
# validation，発話，Log記録を行う
# 生成時にspeak, 死活管理は任せた
class SpeakTask
  settings = YAML.load_file('settings.yml')['speaking']
  @@words = settings['words']
  @@char_list = settings['chars']
  Indico.api_key = YAML.load_file('auth.yml')["indico"]

  # Do all process
  # Return nil/obj
  def initialize text, char='ykr', ip
    @text = text
    @char = char
    @ip = ip
    @pid = nil
    
    adjust()
    return nil if text.empty? || text.length>100

    speak()
  end

  # Wait proc (non-blocking
  # Return bool, that process is alive
  def isAlive
    return false if @pid == nil

    if Process.waitpid(@pid, Process::WNOHANG)==@pid
      @pid = nil
      return false
    end
    
    return true
  end
  
  # Force kill
  def kill
    Process.kill 9, @pid if isAlive()
  end


  private

  # analyze, speak, log動作
  # Return proc pid
  def speak
    asj = analyze()

    vol = '2.0'
    if @char == 'ai'
      command = "yukarin -v 1.0 -c ai -q #{@text}"
    else 
      char = "-c #{@char}" 
      command = "yukarin2 -v #{vol} #{char} -q -a #{asj[:a]} -s #{asj[:s]} -j #{asj[:j]} #{@text}"
    end
    
    @pid = Process.spawn "echo \"+#{command}\"" if $DEV
    @pid = Process.spawn command if !$DEV

    Log.create(ip: @ip, text: @text)

    return @pid
  end

  # 喋るのに適した形へ
  # Escape, and kidding text
  # Validate char
  def adjust 
    result = escaping @text
    result = kidding result

    @char = "ykr" unless @@char_list.include? @char

    @text = result
  end

  # 感情値解析
  def analyze 
    return {a: '1.0', s: '1.0', j: '1.0'} if $DEV

    t_text = translate @text
    value = emotion t_text

    return value
  end

  # Google翻訳(not api)
  def translate text
    url = "https://translate.google.com"

    conn = Faraday.new url do |faraday|
      faraday.request :url_encoded
      faraday.adapter :net_http
    end

    res = conn.get do |req|   
      req.params[:h1] = "ja"
      req.params[:langpair] = "ja%7Cen"
      req.params[:text] = text
    end
    res = res.body.match(/TRANSLATED_TEXT='(.*)';var ctr,/)[1] 
    
    return res
  end

  # indicoで感情解析
  def emotion text
    res = Indico.emotion text
    val = {a: format('%.2f',res['anger']), 
              s: format('%.2f',res['sadness']), j: format('%.2f',res['joy'])}

    return val
  end

  # 記号その他のエスケープ処理
  def escaping text
    text.strip!
    text.gsub!(/(https?|ftp)(:\/\/[-_.!~*\'();a-zA-Z0-9;\/?:\@&=+\$,%#]+)/, '(url)')
    text.gsub!(' ', '、')
    text.gsub!('\n', '。')

    text.tr!(',.|<>:;/\\"\'`&%#', '，．｜＜＞：；／＼”’`＆％＃')

    return text
  end

  # ネタ
  def kidding text
    if text.match(/^世の中には/)
      return "世の中には魔女や魔法少女という存在がいる。"
    end

    @@words.each do |w|
      if text.include?(w)
        return  '汚いこと言わせようとしないでください'
      end
    end

    return text
  end 
end
