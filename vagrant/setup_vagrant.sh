#!/bin/bash

( cd ~ ; vagrant plugin update )
( cd ~ ; vagrant plugin install landrush vagrant-hostmanager vagrant-sshfs vagrant-reload )
