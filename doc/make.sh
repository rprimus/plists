#!/bin/sh
erl -eval 'edoc:files(["../src/plists.erl"])' -run init stop -noshell
