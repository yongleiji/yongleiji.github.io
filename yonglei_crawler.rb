# yonglei_crawler.rb
# 从贴吧页面上抓取《咏雷》诗词，生成 CSV 格式的文件。

require 'optparse'
require 'csv'
require 'open-uri'
require 'nokogiri'

options = { from: 1, filename: 'yonglei.csv' }
OptionParser.new do |opts|
  opts.on('-fN', '--from N', '从第 N 页开始抓取（默认为1）') { |n| options[:from] = n.to_i }
  opts.on('-tN', '--to N', '抓取到第 N 页末为止（默认为最后一页）') { |n| options[:to] = n.to_i }
  opts.on('-oF', '--output F', '输出文件名') { |f| options[:filename] = f }
end.parse!

#options[:filename] += '.csv' if File.extname(options[:filename]).downcase != '.csv'
data = []
data = CSV.read(options[:filename], encoding: 'bom|utf-8').map{ |arr| arr.map { |s| s.tr("\r\n", '') } } if File.exist?(options[:filename])
file = File.new(options[:filename], 'a+', encoding: 'bom|utf-8')
csv = CSV.new(file)

YONGLEI_THREAD = "http://tieba.baidu.com/p/5024534932?see_lz=1"
thread = Nokogiri::HTML(open(YONGLEI_THREAD))
thread.search('br').each { |br| br.replace("\n") }
thread_count, page_count = thread.css('.pb_footer .l_reply_num span').map(&:text).map(&:to_i)
options[:to] = [options[:to] || page_count, page_count].min
raise '参数错误：找不到指定的起始页。' if options[:from] > options[:to]
hymn_count = 0
dup_count = 0
puts "共有 #{page_count} 页、#{thread_count} 条数据。"

(options[:from]..options[:to]).each do |n|
  puts "正在获取第 #{n} 页数据……"
  page = Nokogiri::HTML(open(YONGLEI_THREAD + "&pn=#{n}"))
  page.search('br').each { |br| br.replace("\n") }
  page.css('.d_post_content').each do |msg|
    msg.text =~ /咏雷[\t\r\f·\.]*(.*)/
    if $' && !$'.empty?
      title = ('咏雷 ' + ($1 ? $1.strip : '')).strip
      text = $'.strip
      puts title
      if data.include?([title, text.tr("\r\n", '')])
        dup_count += 1
        puts('跳过。')
      else
        csv << [title, text]
      end
      hymn_count += 1
    end
  end
  puts "=============="
end

file.close
unless File.read(options[:filename], 3, 0).force_encoding('utf-8') == "\xEF\xBB\xBF" # UTF-8 BOM
  File.write(options[:filename], "\xEF\xBB\xBF" + File.read(options[:filename]))
end
puts ["数据获取完毕，共找到 #{hymn_count} 首《咏雷》", dup_count.zero? ? nil : "忽略了 #{dup_count} 条重复数据"].compact.join('，') + '。'