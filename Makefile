.PHONY: build install

build:
	@shards build -Dembed_web_assets

install:
	@cp ./bin/workr /usr/local/bin/workr
