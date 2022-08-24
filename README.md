![サンプルツイート画像](/sample.png)

# duga_bot
DUGAで販売されているAVタイトルをランダムにつぶやくTwitterボットです。ランダムに選んだAVタイトル情報をツイートします。ツイートに含まれるリンクにはご自身のアフィリエイトコードが含まれるので、収益をあげることができます。一度cronなどで自動で定期的にツイートするよう設定すれば、ほったらかしの収入源にすることも可能です。

現在は最近一週間に発売されたAVタイトルからランダムにひとつ選んでツイートしています。`duga_bot.rb`をご自身で変更していただければ、ツイートする時点でもっとも人気のあるタイトルを選んだり、ジャンルをしぼってツイートすることも可能です。

* 動作はUbuntuで確認しましたが、ほかのLinux、Mac、WSLでもできると思います。
* DUGAはアダルトサイトになりますので、ご了承ください。
* Powered by [DUGAウェブサービス](https://click.duga.jp/aff/api/40413-01)
## DUGAの登録
1. [DUGAアフィリエイトサイト](https://click.duga.jp/aff/40413-01)でアフィリエイト登録をする。
2. 「ウェブサービス」からアプリケーションIDの発行申請をする。
3. 代理店IDとアプリケーションIDをメモしておく。
## Twitter開発者の登録
1. Twitterアカウントを開設する。メールアドレス、SMSを受け取れる電話番号が必要になります。
2. アダルト情報をツイートするので、設定->プライバシーと安全->ツイートで「ツイートするメディアをセンシティブな内容を含むものとして設定する」にチェックを入れる。
3. [Twitter開発者サイト](https://developer.twitter.com)でAPIキーを取得する。この際、Read and Writeの権限があることを確認する。[^1]
## Ruby環境の設定
1. rbenvなどを使ってRuby 3.1.2をインストールする。[^2]
2. 必要なgemなどをインストールする。
```shell
sudo apt install idn
sudo apt install libldap2-dev
sudo apt install libidn11-dev
gem install twitter-text
gem install oauth
gem install typhoeus
```
## 動作環境の設定
1. レポジトリをクローンする。
```
git clone https://github.com/dugabot0/duga_bot.git
```
2. 環境変数にDugaのアプリケーションID、代理店IDとTwitterのAPIキーを設定する。ここではAccess TokenとAccess Secretは使いません。
```shell
# 必要であれば.bash_profileなどに以下を追加する。
export DUGA_APPID='DUGAのアプリケーションID'
export DUGA_AGENTID='DUGAの代理店ID'
export TWITTER_CONSUMER_KEY='TwitterのAPI Key'
export TWITTER_CONSUMER_SECRET='TwitterのAPI Secret'
```
環境変数を設定するかわりにコードに直接アプリケーションIDなどを書いてもかまいません。
```ruby
duga_util.rb
  def self.search_title(params)
    params.store('version', VERSION)
    params.store('appid', ENV['DUGA_APPID'])      # ENV['DUGA_APPID']をDUGAのアプリケーションIDにかえる
    params.store('agentid', ENV['DUGA_AGENTID'])  # ENV['DUGA_AGENTID']をDUGAの代理店IDにかえる
```
```ruby
twitter_v2.rb
  def initialize
    consumer_key = ENV['TWITTER_CONSUMER_KEY']        # ENV['TWITTER_CONSUMER_KEY']をTwitter API Keyにかえる
    consumer_secret = ENV['TWITTER_CONSUMER_SECRET']  # ENV['TWITTER_CONSUMER_SECRET']をTwitter API Secretにかえる
```
3. 一度、動かしてOauth認証をする。指定されたURLをブラウザで開くとPINコードが表示されるので、そのPINコードを入力してEnterを押す。一度PINコード入力による認証がすめば、次からは認証は省略されます。認証情報は`tmp`ディレクトリに保存されます。
```
$ ruby duga_bot.rb 
Follow this URL to have a user authorize your app: https://api.twitter.com/oauth/authenticate?oauth_token=xxxx
Enter PIN:
```
4. Twitterで自分のアカウントのタイムラインにボットによる投稿がされていることを確認する。
5. cronなどで定期的にボットを動かす。あまりに頻繁にツイートするとアカウントを停止されてしまうので、特にはじめの頃は1時間に一度くらいにするとよい。
```
$ crontab -e
0 * * * * cd ~/duga_bot; ruby duga_bot.rb  # 毎時0分にツイートする。
```
6. 一度cronが動いてしまえば、特にメンテナンスは必要ないが、`log`ファイルが出力されるので、サイズが大きくなったら定期的に削除する。なお、`tmp`ディレクトリにはTwitter認証情報が保存されているので、消去しないよう注意する。

[^1]: [https://di-acc2.com/system/rpa/9688/](https://di-acc2.com/system/rpa/9688/)などを参考にしてください。
[^2]: [https://qiita.com/ma2shita/items/5c41aa8a4908c919ba78](https://qiita.com/ma2shita/items/5c41aa8a4908c919ba78)などを参照してください。
