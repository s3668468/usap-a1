!/bin/bash
while true
do
        sleep 5m
        MDSTATUS=$(sudo mdadm --detail /dev/md0 | head -n 12 | tail -n +12 | cut -c22-30)
        if [ $(echo $MDSTATUS | grep -c "clean") -eq 0 ]
        then
                echo "/dev/md0 change detected. Sending pushbullet"
                pushbullet push all note "/dev/md0 change detected! Status: $(MDSTATUS)"
        else
                echo "/dev/md0 is clean"
        fi
done