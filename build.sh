#!/bin/bash
tag=9.3
docker build -t varchasgopalaswamy/ifort-rhel-dev:${tag} -f Dockerfile .
