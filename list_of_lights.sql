-- phpMyAdmin SQL Dump
-- version 3.2.5
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Erstellungszeit: 14. Oktober 2010 um 18:05
-- Server Version: 5.1.49
-- PHP-Version: 5.3.2-2

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Datenbank: `list_of_lights`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lights`
--

CREATE TABLE IF NOT EXISTS `lights` (
  `version` int(11) NOT NULL DEFAULT '1',
  `int_chr` char(1) NOT NULL,
  `int_nr` varchar(11) NOT NULL,
  `int_subnr` char(3) NOT NULL,
  `usl_list` varchar(32) NOT NULL,
  `usl_nr` int(11) NOT NULL,
  `usl_subnr` char(3) NOT NULL,
  `section_name` varchar(256) NOT NULL,
  `name` varchar(256) NOT NULL,
  `name_comb` varchar(256) NOT NULL,
  `lat` float NOT NULL,
  `lon` float NOT NULL,
  `character_full` varchar(32) NOT NULL,
  `character` enum('F','L.Fl','Al.Fl','Fl','Iso','Oc','V.Q','U.Q','Q','Mo') NOT NULL,
  `group` varchar(4) NOT NULL,
  `pos` set('','vert','horiz') NOT NULL DEFAULT '',
  `period` float unsigned NOT NULL,
  `mult_light` int(2) unsigned NOT NULL DEFAULT '1',
  `height_ft` int(5) unsigned NOT NULL,
  `height_m` int(5) unsigned NOT NULL,
  `sequence` varchar(256) DEFAULT NULL,
  `horn` varchar(256) DEFAULT NULL,
  `siren` varchar(256) DEFAULT NULL,
  `whistle` tinyint(1) NOT NULL DEFAULT '0',
  `radar_reflector` tinyint(1) NOT NULL DEFAULT '0',
  `topmark` enum('2cones_pointup','2cones_base2base','2cones_pointdown','2cones_point2point','sphere','2spheres','xshape','cube','cone_pointup','yes','') NOT NULL DEFAULT '',
  `av_light` tinyint(1) NOT NULL DEFAULT '0',
  `racon` varchar(256) DEFAULT NULL,
  `structure` varchar(256) NOT NULL,
  `type` enum('lateral:starboard','lateral:port','lateral:preferred_channel_starboard','lateral:preferred_channel_port','cardinal:north','cardinal:east','cardinal:south','cardinal:west','safe_water','isolated_danger','special_purpose','major','') NOT NULL,
  `typea` enum('major','buoy','beacon','minor','float','vessel') NOT NULL,
  `bsystem` enum('A','B','') NOT NULL,
  `shape` varchar(32) NOT NULL,
  `shapecol` varchar(256) NOT NULL,
  PRIMARY KEY (`usl_nr`,`usl_subnr`,`usl_list`),
  UNIQUE KEY `int_chr` (`int_chr`,`int_nr`,`int_subnr`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `sectors`
--

CREATE TABLE IF NOT EXISTS `sectors` (
  `usl_list` varchar(32) NOT NULL,
  `usl_nr` int(11) NOT NULL,
  `usl_subnr` char(2) NOT NULL DEFAULT '',
  `sector_nr` int(2) unsigned NOT NULL AUTO_INCREMENT,
  `start` float unsigned DEFAULT NULL,
  `end` float unsigned DEFAULT NULL,
  `colour` enum('W','R','G','Y','Bu','Or','Vi') NOT NULL,
  `range` int(3) unsigned DEFAULT NULL,
  `visibility` enum('int','unint','') NOT NULL DEFAULT '',
  PRIMARY KEY (`usl_nr`,`usl_subnr`,`sector_nr`,`usl_list`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;
