<?php

//define( "SCHEMAS_PATH", "/web/schemas" );
define("XML_SCHEMA_NS", "Happymeal\Port\Adaptor\Data\XML\Schema");
define("XML_SCHEMA_TARGET_NS", "XML\Schema");

$class_name_restrictions = array(
    '__halt_compiler',
    'abstract', 'and', 'array', 'as',
    'break',
    'callable', 'case', 'catch', 'class', 'clone', 'const', 'continue',
    'declare', 'default', 'die',
    'do',
    'echo', 'else', 'elseif', 'empty', 'enddeclare', 'endfor', 'endforeach', 'endif', 'endswitch', 'endwhile', 'eval', 'exit', 'extends',
    'final', 'for', 'foreach', 'function',
    'global', 'goto',
    'if', 'implements', 'include', 'include_once', 'instanceof', 'insteadof', 'interface', 'isset',
    'list',
    'namespace', 'new',
    'or',
    'print', 'private', 'protected', 'public',
    'require', 'require_once', 'return',
    'static', 'switch',
    'throw', 'trait', 'try',
    'unset', 'use',
    'var',
    'while',
    'xor'
);

$nss_replacements = array(
    "http://www.w3.org/1999/XSL/Transform" => "urn:ru:ilb:meta:XML:XSL",
    "http://www.w3.org/1999/xlink" => "urn:ru:ilb:meta:XML:XLink",
    "http://www.w3.org/1999/xhtml" => "urn:ru:ilb:meta:XML:XHTML",
    "http://www.w3.org/2001/XMLSchema" => "urn:ru:ilb:meta:XML:Schema",
    "http://www.together.at/2006/XPIL1.0" => "urn:ru:ilb:meta:XPIL",
    "http://www.wfmc.org/2002/XPDL1.0" => "urn:ru:ilb:meta:XPDL"
);

$local_nss = array(
    'urn:ru:ilb:meta:',
    'urn:ru:ilb:',
    'urn:ru:mobilsoft:meta:',
    'urn:ru:battleship:'
);
