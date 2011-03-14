-- phpMyAdmin SQL Dump
-- version 3.2.5
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Mar 14, 2011 at 03:32 PM
-- Server version: 5.1.49
-- PHP Version: 5.3.3-7

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `list_of_lights`
--

-- --------------------------------------------------------

--
-- Table structure for table `lights`
--

CREATE TABLE IF NOT EXISTS `lights` (
  `version` int(11) NOT NULL DEFAULT '1',
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `int_chr` char(1) NOT NULL,
  `int_nr` varchar(11) NOT NULL,
  `int_subnr` char(3) NOT NULL,
  `usl_list` varchar(32) NOT NULL,
  `usl_nr` int(11) NOT NULL,
  `usl_subnr` char(3) NOT NULL,
  `osm_id` int(11) NOT NULL DEFAULT '-1',
  `section_name` varchar(256) NOT NULL,
  `name` varchar(256) NOT NULL,
  `longname` varchar(256) NOT NULL,
  `lat` float NOT NULL,
  `lon` float NOT NULL,
  `character_full` varchar(32) NOT NULL,
  `character` enum('F','L.Fl','Al.Fl','Fl','Iso','Oc','V.Q','U.Q','Q','Mo') NOT NULL,
  `group` varchar(4) NOT NULL,
  `pos` varchar(32) NOT NULL DEFAULT '',
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
  `racon_grp` varchar(5) NOT NULL,
  `racon_period` int(11) DEFAULT NULL,
  `structure` varchar(256) NOT NULL,
  `type` enum('lateral:starboard','lateral:port','lateral:preferred_channel_starboard','lateral:preferred_channel_port','cardinal:north','cardinal:east','cardinal:south','cardinal:west','safe_water','isolated_danger','special_purpose','major','') NOT NULL,
  `typea` enum('major','buoy','beacon','minor','float','vessel') NOT NULL,
  `bsystem` enum('A','B','') NOT NULL,
  `shape` varchar(32) NOT NULL,
  `shapecol` varchar(256) NOT NULL,
  `fsignal` enum('horn','siren','whistle','bell','diaphone','gong','explosive') DEFAULT NULL,
  `error` set('position','beacon_guess','height','intdup','name_incomplete','usldup') NOT NULL,
  `source` varchar(256) NOT NULL,
  `remarks` varchar(256) NOT NULL,
  `dir` int(6) DEFAULT NULL,
  `dirdist` int(6) DEFAULT NULL,
  `leading` enum('front','rear') DEFAULT NULL,
  `height_landm` int(5) NOT NULL,
  PRIMARY KEY (`usl_list`,`usl_nr`,`usl_subnr`),
  UNIQUE KEY `int_chr` (`int_chr`,`int_nr`,`int_subnr`),
  UNIQUE KEY `osm_id` (`osm_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `sectors`
--

CREATE TABLE IF NOT EXISTS `sectors` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usl_list` varchar(32) NOT NULL,
  `usl_nr` int(11) NOT NULL,
  `usl_subnr` char(2) NOT NULL DEFAULT '',
  `sector_nr` int(2) unsigned NOT NULL AUTO_INCREMENT,
  `start` float DEFAULT NULL,
  `end` float DEFAULT NULL,
  `colour` enum('W','R','G','Y','Bu','Or','Vi') NOT NULL,
  `range` int(3) unsigned DEFAULT NULL,
  `visibility` enum('int','unint','') NOT NULL DEFAULT '',
  PRIMARY KEY (`usl_list`,`usl_nr`,`usl_subnr`,`sector_nr`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;
