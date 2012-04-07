#!/usr/bin/make -f
# Generic build utility for Lua modules.
# D.Manura, This util.mk file is public domain.

Q="[\"\']"
VERSIONFROM:=$(shell sed -n "s,.*VERSIONFROM *= *$Q\(.*\)$Q,\1,p" rockspec.in)
ROCKVERSION:=$(shell sed -n "s,.*ROCKVERSION *= *$Q\(.*\)$Q,\1,p" rockspec.in)
ROCKSCMVERSION:=$(shell sed -n "s,.*ROCKSCMVERSION *= *$Q\(.*\)$Q,\1,p" rockspec.in)
VERSION:=$(shell sed -n "s,.*_VERSION=$Q\(.*\)$Q.*,\1,p" $(VERSIONFROM))
SCMVERSION:=scm
NAME:=$(shell sed -n "s,.*package *= *$Q\(.*\)$Q,\1,p" rockspec.in)
#NAME=$(shell lua -e 'dofile"rockspec.in"; print(package)')

rockspec : tmp
	cat rockspec.in | \
	   sed 's,$$(_VERSION),$(VERSION),g' | \
	   sed 's,$$(ROCKVERSION),$(ROCKVERSION),g' | \
	   sed 's,^--URL=,  url=,' \
	     > tmp/$(NAME)-$(VERSION)-$(ROCKVERSION).rockspec
	cat rockspec.in | \
	   sed 's,$$(_VERSION),$(SCMVERSION),g' | \
	   sed 's,$$(ROCKVERSION),$(ROCKSCMVERSION),g' | \
	   sed 's,^--URLSCM=,  url=,' | \
	   sed '/tag *= */d' \
	      > tmp/$(NAME)-$(SCMVERSION)-$(ROCKSCMVERSION).rockspec

install : rockspec
	luarocks make tmp/$(NAME)-$(VERSION)-$(ROCKVERSION).rockspec
install-local : rockspec
	luarocks make --local tmp/$(NAME)-$(VERSION)-$(ROCKVERSION).rockspec
remove :
	luarocks remove $(NAME)
remove-local :
	luarocks remove --local $(NAME)

dist : version rockspec
	rm -fr tmp/$(NAME)-$(VERSION)
	for x in `cat MANIFEST`; do \
	   install -D $$x tmp/$(NAME)-$(VERSION)/$$x || exit; \
	done
	cd tmp && zip -r $(NAME)-$(VERSION).zip $(NAME)-$(VERSION) \
	cd tmp && zip -r $(NAME)-$(VERSION)-$(ROCKVERSION).src.rock \
	   $(NAME)-$(VERSION).zip \
	   $(NAME)-$(VERSION)-$(ROCKVERSION).rockspec

dist-install : dist
	cd tmp/$(NAME)-$(VERSION) && \
	   luarocks make $(NAME)-$(VERSION)-$(ROCKVERSION).rockspec

test :
	@if [ -e test.lua ]; then lua test.lua; fi
	@if [ -e test/test.lua ]; then lua test/test.lua; fi

pack : dist
	cd tmp/ && luarocks pack $(NAME)-$(VERSION)-$(ROCKVERSION).rockspec

tag :
	git tag -f v$(VERSION)-$(ROCKVERSION)

version :
	@echo $(NAME)-$(VERSION)-$(ROCKVERSION)
	@echo $(NAME)-$(SCMVERSION)-$(ROCKSCMVERSION)

clean-tmp :
	rm -fr tmp/
tmp :
	mkdir tmp

.PHONY : dist install test tag version
