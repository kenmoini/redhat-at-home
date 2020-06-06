#!/bin/bash

export USERNAME=${USERNAME:="satelliteLink"}
export FIRST_NAME=${FIRST_NAME:="Satellite"}
export LAST_NAME=${LAST_NAME:="Link"}
export PASSWORD=${PASSWORD:="somethingSecure"}

ovirt-aaa-jdbc-tool user add $USERNAME --attribute=firstName=$FIRST_NAME --attribute=lastName=$LAST_NAME
ovirt-aaa-jdbc-tool user password-reset $USERNAME --password=pass:${PASSWORD} --password-valid-to="2035-08-15 10:30:00Z"

ovirt-aaa-jdbc-tool user edit $USERNAME --flag=-disabled
ovirt-aaa-jdbc-tool user unlock $USERNAME