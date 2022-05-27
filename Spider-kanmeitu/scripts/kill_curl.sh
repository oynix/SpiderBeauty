ps -ef | grep curl | grep -v grep | awk '{print $2}' | xargs kill -9
