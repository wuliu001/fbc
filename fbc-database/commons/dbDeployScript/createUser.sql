CREATE USER IF NOT EXISTS 'dba'@'%' IDENTIFIED WITH mysql_native_password BY 'mysql';
GRANT ALL ON *.* TO 'dba'@'%';

CREATE USER IF NOT EXISTS 'ws'@'%' IDENTIFIED WITH mysql_native_password BY 'ygomi';
GRANT EXECUTE ON *.* TO 'ws'@'%';
