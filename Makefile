all: model.js test.js

%.js: %.coffee
	coffee -bpc $< > $@
