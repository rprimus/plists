#!/bin/sh
erl -run file set_cwd .. \
-run make all \
-run file set_cwd test \
-pa ../ebin -run make all -run plists_unittests do_tests \
-run init stop -noshell
