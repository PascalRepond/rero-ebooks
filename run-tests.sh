#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# RERO EBOOKS
# Copyright (C) 2020 RERO
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# COLORS for messages
NC='\033[0m'                    # Default color
INFO_COLOR='\033[1;97;44m'      # Bold + white + blue background
SUCCESS_COLOR='\033[1;97;42m'   # Bold + white + green background
ERROR_COLOR='\033[1;97;41m'     # Bold + white + red background

PROGRAM=`basename $0`
SCRIPT_PATH=`dirname $0`

# MESSAGES
msg() {
  echo -e "${1}" 1>&2
}
# Display a colored message
# More info: https://misc.flogisoft.com/bash/tip_colors_and_formatting
# $1: choosen color
# $2: title
# $3: the message
colored_msg() {
  msg "${1}[${2}]: ${3}${NC}"
}

info_msg() {
  colored_msg "${INFO_COLOR}" "INFO" "${1}"
}

error_msg() {
  colored_msg "${ERROR_COLOR}" "ERROR" "${1}"
}

error_msg+exit() {
    error_msg "${1}" && exit 1
}

success_msg() {
  colored_msg "${SUCCESS_COLOR}" "SUCCESS" "${1}"
}

# Displays program name
msg "PROGRAM: ${PROGRAM}"

# Poetry is a mandatory condition to launch this program!
if [[ -z "${VIRTUAL_ENV}" ]]; then
  error_msg+exit "Error - Launch this script via poetry command:\n\tpoetry run run-tests"
fi

set -e
# TODO: find out why we have following error:
# +============================+===========+==========================+==========+
# | package                    | installed | affected                 | ID       |
# +============================+===========+==========================+==========+
# | wtforms                    | 2.3.3     | <3.0.0a1                 | 42852    |
# | werkzeug                   | 1.0.1     | <2.0.2                   | 42050    |
# | sqlalchemy-utils           | 0.35.0    | >=0.27.0                 | 42194    |
# | flask-caching              | 1.10.1    | <=1.10.1                 | 40459    |
# | celery                     | 5.1.2     | <5.2.0                   | 42498    |
# | celery                     | 5.1.2     | <5.2.2                   | 43738    |
# +============================+===========+==========================+==========+
safety check -i 42852 -i 42050 -i 42194 -i 40459 -i 42498 -i 43738
info_msg "Test pydocstyle:"
pydocstyle rero_ebooks tests docs
info_msg "Test isort:"
isort --check-only --diff "${SCRIPT_PATH}"
info_msg "Test useless imports:"
autoflake -c -r --remove-all-unused-imports --ignore-init-module-imports . &> /dev/null || {
  autoflake --remove-all-unused-imports -r --ignore-init-module-imports .
  exit 1
}
# info_msg "Check-manifest:"
# TODO: check if this is required when rero-ils will be published
# check-manifest --ignore ".travis-*,docs/_build*"
info_msg "Sphinx-build:"
sphinx-build -qnNW docs docs/_build/html
info_msg "Tests:"
poetry run tests
