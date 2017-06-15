# rcc-yukari
## 構成
Sinatra サーバ
* web
* 発話
* Logの処理
* youtube

Twitter daemon
* tl拾ってきてサーバにパス

## run
0. Make "settings.yml" and "auth.yml". You can replicate and fill in with \*.tmp.
1. `bundle install --path=vendor/path`
2. `bundle exec ruby setup.rb`
3. `bundle exec rackup [-E production]`

## purpose(dev
* process usage
speaking task will be thread

* rackup module
* rspec testing
