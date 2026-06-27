#!/bin/bash

options=("Send file to container" "Receive file from container" "Quit")
selected=0
container_name="mycontainer"   # <-- set your container name here

while true; do
    clear
    echo "Use ↑ ↓ and Enter to select:"
    for i in "${!options[@]}"; do
        if [[ $i -eq $selected ]]; then
            echo -e "\033[32m> ${options[$i]}\033[0m"
        else
            echo "  ${options[$i]}"
        fi
    done

    read -rsn1 key
    case "$key" in
        $'\x1b')
            read -rsn2 key
            case "$key" in
                '[A') ((selected--)) ;;
                '[B') ((selected++)) ;;
            esac
            ;;
        "")
            case "${options[$selected]}" in
                "Send file to container")
                    read -p "Enter local file path: " local_file
                    read -p "Enter target path inside container: " target_path

                    echo "Searching in $(pwd)..."
                    ls | grep "$(basename "$local_file")"

                    echo "Local pwd: $(pwd)"
                    echo "Container ls at $target_path:"
                    docker exec "$container_name" ls -l "$target_path"

                    read -p "Is this the correct file? (y/n): " confirm
                    if [[ $confirm == "y" ]]; then
                        docker cp "$local_file" "$container_name":"$target_path"
                        echo "✅ File copied into container."
                    else
                        echo "❌ Cancelled."
                    fi
                    read -n1 -s -r -p "Press any key to continue..."
                    ;;

                "Receive file from container")
                    read -p "Enter file path inside container: " container_file
                    read -p "Enter destination path on host: " host_path

                    echo "Container pwd:"
                    docker exec "$container_name" pwd
                    echo "Container ls:"
                    docker exec "$container_name" ls -l "$(dirname "$container_file")"

                    read -p "Is this the correct file? (y/n): " confirm
                    if [[ $confirm == "y" ]]; then
                        docker cp "$container_name":"$container_file" "$host_path"
                        echo "✅ File copied to host."
                    else
                        echo "❌ Cancelled."
                    fi
                    read -n1 -s -r -p "Press any key to continue..."
                    ;;

                "Quit")
                    break
                    ;;
            esac
            ;;
    esac

    ((selected < 0)) && selected=$((${#options[@]} - 1))
    ((selected >= ${#options[@]})) && selected=0
done
