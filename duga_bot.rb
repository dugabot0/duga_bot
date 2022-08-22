require './duga_util.rb'
require './twitter_v2.rb'
require 'date'
require 'logger'
require 'twitter-text'

HITS = 100

def makeText(av)
  text = ''
  if av['originaltitle']
    text += "#{av['originaltitle']}\n"
  else
      text += "#{av['title']}\n"
  end
  text += "メーカー : ##{av['makername'].gsub(/\s/,'')}\n"
  text += "レーベル : ##{av['label'][0]['name'].gsub(/\s/,'')}\n" if av['label'] && av['label'][0]['name'] != av['makername']

  categories = [['performer', '出演者'], ['director', '監督'], ['category', 'カテゴリー'], ['series', 'シリーズ']]
  categories.each do |category|
    if av[category[0]]
      text += "#{category[1]} : "
      av[category[0]].each do |a|
        if a['data']
          text += "#" if category[1] != 'カテゴリー'
          text += "#{a['data']['name'].gsub(/\s/,'')} "
        else
          text += "#" if category[1] != 'カテゴリー'
          text += "#{a['name'].gsub(/\s/,'')} "
        end
      end
      text.slice!(-1, 1)
      text += "\n"
    end
  end
  text += "#{av['price']}\n"
  text += "#{av['caption']}\n"

  loop do
    tweet = text + av['affiliateurl']
    res = Twitter::TwitterText::Validation.parse_tweet(tweet, {tweet_mode: "extened"})
    break if res[:permillage].to_i < 1000
    text.slice!(-4, 4)
    text += "…\n"
  end
  res = Twitter::TwitterText::Validation.parse_tweet(text + "#{av['affiliateurl']}", {tweet_mode: "extened"})
  return text + "#{av['affiliateurl']}"
end

log = Logger.new('./log')

params = {}
releasestt = (Date.today - 7).to_s.gsub(/-/,'') # 1週間
releaseend = Date.today.to_s.gsub(/-/,'')
params.store('releasestt', releasestt)
params.store('releaseend', releaseend)
params.store('hits', HITS)

num_titles = 0
random_num = 0
offset = 1
twitter_text = ''
first = true
loop do
  params['offset'] = offset
  res = DugaUtil.search_title(params)
  if first
    num_titles = res['count']
    srand
    random_num = rand(num_titles) + 1
    first = false
  end

  found = false
  res['items'].each do |i|
    if offset == random_num
      twitter_text = makeText(i['item'])
      found = true
      break
    end
    offset += 1
  end
  break if found

  num_titles += res['items'].size
  break if res['items'].size < HITS
end

if twitter_text == ''
  log.error('twitter_text is empty...')
  log.error("random_num=#{random_num} num_titles=#{num_titles}")
  exit
end
log.info(twitter_text)

twitter = TwitterV2.new
res = twitter.postTweet(twitter_text)
log.info(res.code)
if res.code.to_i != 201
  log.error("#{JSON.pretty_generate(JSON.parse(response.body))}")
end
