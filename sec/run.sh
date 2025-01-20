#!/bin/bash

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker and try again."
    exit 1
fi

if ! command -v tmux &> /dev/null; then
    echo "tmux not found. Please install tmux and try again."
    exit 1
fi

create_network() {
    if ! docker network inspect vault_101 &> /dev/null; then
        echo "Creating Docker network 'vault_101'..."
        docker network create --driver bridge vault_101 || { echo "Failed to create network."; exit 1; }
    else
        echo "Docker network 'vault_101' already exists."
    fi
}

build_containers() {
    if ! docker images | grep -q "^attacker "; then
        echo "Building attacker container..."
        docker build -t attacker ./attacker/ || { echo "Failed to build attacker."; exit 1; }
    else
        echo "Attacker image already exists. Skipping build."
    fi

    if ! docker images | grep -q "^target "; then
        echo "Building target container..."
        docker build -t target ./target/ || { echo "Failed to build target."; exit 1; }
    else
        echo "Target image already exists. Skipping build."
    fi
}

start_containers_tmux() {
    echo "Starting tmux session 'vault'..."
    tmux new-session -d -s vault

    if ! docker ps | grep -q "attacker"; then
        echo "Starting attacker container in pane 1..."
        tmux send-keys -t vault "docker run -it --rm --name attacker --network vault_101 attacker" C-m
    else
        echo "Attacker container is already running. Skipping start."
    fi

    tmux split-window -h -t vault

    if ! docker ps | grep -q "target"; then
        echo "Starting target container in pane 2..."
        tmux send-keys -t vault "docker run -it --rm --name target --network vault_101 target" C-m
    else
        echo "Target container is already running. Skipping start."
    fi

    echo "Configuring tmux layout..."
    tmux select-layout -t vault tiled
    tmux attach-session -t vault
}

create_network
build_containers
start_containers_tmux

#echo "Use 'tmux attach -t vault' to reattach the session."
