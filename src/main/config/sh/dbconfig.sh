#!/bin/bash
cat dbHosts | sed 's/"//g' | sed 's/:.*//g'