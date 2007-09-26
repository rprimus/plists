#!/bin/sh
erl -sname first_node@localhost \
-run file set_cwd .. \
-run make all \
-run file set_cwd test \
-pa ../ebin -run make all -run plists_unittests run \
-run init stop -noshell
