# yonglei_generator.rb
# 根据 CSV 文件生成网页。

require 'erb'
require 'csv'

ARGV << 'yonglei.csv' if ARGV.empty?
raise '参数错误：找不到指定的文件。' unless File.exist?(ARGV.last)
data = []
CSV.foreach(ARGV.last, encoding: 'bom|utf-8') do |row|
  data << [row[0].encode(xml: :text), row[1].encode(xml: :text, universal_newline: true)]
end
template = File.read('index.html.erb')
File.open('index.html', 'w+') do |file|
  file.write ERB.new(template).result
end
puts 'Done.'