#!/usr/bin/env bash

RED="\033[0;31m"
NC="\033[0;0m"
read -p "Dime tu nombre: " name
echo -e "${RED}hola desde el script $name${NC}"
