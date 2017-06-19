# rcc-yukari
## 構成
Sinatra サーバ
* web
* 発話
* Logの処理
* youtube

Twitter daemon
* tl拾ってきてサーバにパス

## requirement
* Ruby (>2.3.0)
* SQlite3

* youtube-dl(https://rg3.github.io/youtube-dl/index.html)
* mplayer(http://www.mplayerhq.hu/)
* yukarin(from hilenet)

## run
0. Make "config/settings.yml" and "config/auth.yml". You can replicate and fill in with \*.tmp.
1. `bundle install --path=vendor/path`
2. `bundle exec rake db:migrate`
3. `bundle exec rackup [-E production]`

## purpose(dev
* process usage
speaking task will be thread
youtube too

* rackup module
yet

* rspec testing
yet
