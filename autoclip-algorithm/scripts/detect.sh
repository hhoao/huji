#!/bin/bash
ps aux|grep python
ps aux|grep python | grep ping_pong_detect | awk '{print $2}' | xargs py-spy dump --pid {} >> output.txt
ps aux|grep python | grep ping_pong_detect | awk '{print $2}' | xargs -i  sudo env "PATH=$PATH" py-spy dump --pid {} >> output.txt
