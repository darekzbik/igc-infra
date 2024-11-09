#!/bin/bash

systemctl enable docker
systemctl start docker

systemctl enable app
systemctl start app

systemctl start nginx