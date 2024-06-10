#!/bin/bash

validate_time_format() {
    if [[ ! $1 =~ ^[0-9]{3,4}$ ]]; then
        echo "Invalid format. Use a 12-hour clock time to set the alarm."
        return 1
    fi

    hour=${1:0:${#1}-2}
    minute=${1:${#1}-2:2}

    if (( hour < 1 || hour > 12 || minute < 0 || minute > 59 )); then
        echo "Invalid format. Use a 12-hour clock time to set the alarm."
        return 1
    fi

    return 0
}

get_alarm_time() {
    while true; do
        read -p "Enter the alarm time in 12-hour format (hhmm or hmm): " alarm_time
        read -p "a.m. or p.m.? (Enter 'am' or 'pm'): " meridiem
        meridiem=$(echo "$meridiem" | tr '[:lower:]' '[:upper:]')
        if validate_time_format $alarm_time && [[ "$meridiem" == "AM" || "$meridiem" == "PM" ]]; then
            hour=${alarm_time:0:${#alarm_time}-2}
            minute=${alarm_time:${#alarm_time}-2:2}
            echo "Alarm set for $hour:$minute $meridiem"
            break
        else
            echo "Invalid input. Please enter the time in the correct format and specify AM or PM."
        fi
    done
}

get_remaining_time() {
    now=$(date +%s)
    current_hour=$(date +%I)
    current_minute=$(date +%M)
    current_second=$(date +%S)
    current_meridiem=$(date +%p)

    alarm_hour=${alarm_time:0:${#alarm_time}-2}
    alarm_minute=${alarm_time:${#alarm_time}-2:2}

    if [[ $meridiem == "PM" && $alarm_hour -lt 12 ]]; then
        alarm_hour=$((alarm_hour + 12))
    elif [[ $meridiem == "AM" && $alarm_hour -eq 12 ]]; then
        alarm_hour=0
    fi

    alarm_epoch=$(date -d "today $alarm_hour:$alarm_minute" +%s)
    
    if (( alarm_epoch <= now )); then
        alarm_epoch=$(date -d "tomorrow $alarm_hour:$alarm_minute" +%s)
    fi

    echo $((alarm_epoch - now))
}

sound_alarm() {
    alarm_sound="./alarm_sound.m4a"
    while true; do
        mpv --loop "$alarm_sound"
        sleep 1
    done
}

main() {
    get_alarm_time
    remaining_seconds=$(get_remaining_time)

    hours=$((remaining_seconds / 3600))
    minutes=$(( (remaining_seconds % 3600) / 60 ))

    echo "The alarm will go off in $hours hours and $minutes minutes."

    sleep $remaining_seconds
    
    trap 'pkill mpv; exit' SIGINT SIGTERM
    sound_alarm
}

main




