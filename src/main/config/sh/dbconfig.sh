#!/bin/bash
cat dbHosts | sed 's/:.*//g'