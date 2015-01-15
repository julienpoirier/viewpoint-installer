DROP DATABASE IF EXISTS viewpoint;
CREATE DATABASE IF NOT EXISTS viewpoint DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

CREATE USER 'viewpoint'@'localhost' IDENTIFIED BY 'viewpoint';
GRANT ALL PRIVILEGES ON *.* TO 'viewpoint'@'localhost' WITH GRANT OPTION;

CREATE USER 'viewpoint'@'%' IDENTIFIED BY 'viewpoint';
GRANT ALL PRIVILEGES ON *.* TO 'viewpoint'@'%' WITH GRANT OPTION;

CREATE USER 'viewpoint'@'::1' IDENTIFIED BY 'viewpoint';
GRANT ALL PRIVILEGES ON *.* TO 'viewpoint'@'::1' WITH GRANT OPTION;

CREATE USER 'viewpoint'@'127.0.0.1' IDENTIFIED BY 'viewpoint';
GRANT ALL PRIVILEGES ON *.* TO 'viewpoint'@'127.0.0.1' WITH GRANT OPTION;

flush privileges;
