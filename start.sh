#!/bin/bash
exec gunicorn -b 0.0.0.0:9090 -c config.py -e PYTHONBUFFERED=TRUE acct_mgt.wsgi:APP --log-file=-

