"""ProyectoHospital package initializer.

This file is used to initialize package-level behavior. When the project uses
MySQL via PyMySQL we register it to act as MySQLdb for Django compatibility.
"""

import pymysql

# Make PyMySQL act as MySQLdb so Django's MySQL backend finds the driver.
pymysql.install_as_MySQLdb()

