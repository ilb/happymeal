<?php

/*
 *
 * Скрипт отвечает за формирование сводного нормализованного xsd документа
 * в котором каждому комплексному типу привязан его namespace. (не нашел как это сделать через
 * xslt, он не читает атрибуты xmlns:.. файлов).
 * Из получившихся данных формируем временный файл.
 *
 */

include_once "config.php";

$code = "";
$counter = 0; //Счетчик для уникальный идишников узлов
$nss = $uniques = array();

if (count($argv) < 2 || !$argv[1]) {
    throw new Exception("Undefined namespace");
}
$namespace = $argv[1];

if (count($argv) < 3 || !$argv[2]) {
    throw new Exception("Undefined schema path");
}
// каталог схем
$base = realpath($argv[2]);
//$base = dirname( dirname( __FILE__ ) ).SCHEMAS_PATH;

if (count($argv) < 4 || !$argv[3]) {
    throw new Exception("Undefined build directory");
}
// каталог созданных классов
$buildDir = $argv[3];

$imports = array(); // импортированные файлы
/*
  printf("namespace = %s %s\n", $namespace, $base);
  for($i = 0; $i < count( $argv ); $i++) {
  printf("arg %d = %s\n", $i, $argv[$i]);
  }
  exit(0);
 */


if (count($argv) > 4) {
    $i = 4;
    while (isset($argv[$i])) {
        $fullname = $base . DIRECTORY_SEPARATOR . $argv[$i];
        $fullname = preg_replace("/\/{2,}/", "/", $fullname); //убираем двойные слэши чтобы однозначно идентифицировать адрес импортируемого ресурса
        if (is_dir($fullname)) {
            $dir = new RecursiveDirectoryIterator($fullname);
            foreach (new RecursiveIteratorIterator($dir) as $val) {
                if ($val->isFile() && strpos($val->getPathname(), ".xsd") != 0) {
                    $imports[$val->getPathname()] = FALSE;
                }
            }
            /*
              foreach ( glob( $fullname."{/*}/*.xsd" ) as $filename ) {
              if( !file_exists( $filename ) ) throw new Exception( "File ".$filename." doesn"t exist" );
              $imports[$filename] = FALSE;
              }
             * */
        } else {
            if (!file_exists($fullname))
                throw new Exception("File $fullname doesn't exist");
            $imports[$fullname] = FALSE;
        }
        $i++;
    }
} else {
    /**
     *
     * Если не передан список файлов или директорий то строим по всем схемам внутри каталога схем
     * Так делать не стоит. если проект большой то все умрет
     *
     */
    //if( is_dir( $base ) ) {
    //    foreach ( glob( $base."/*/*.xsd" ) as $filename ) {
    //        if( !file_exists( $filename ) ) throw new Exception( "File ".$filename." doesn"t exist" );
    //        $imports[$filename] = FALSE;
    //    }
    //}
}

//print_r( $imports ); exit;

$xw = new XMLWriter();
$xw->openMemory();
$xw->setIndent(true);
$xw->setIndentString(" ");
$xw->startDocument("1.0", "UTF-8");
$xw->startElementNS(NULL, "schema", "urn:ru:ilb:tmp");
$xw->writeAttribute("namespace", $namespace);

$notImported = getNotImported($imports);

while ($notImported) {
    $tree = array();
    import2assoc($notImported, $xw);
    foreach ($tree as $file) {
        foreach ($file as $class) {
            //$code .= class2code( $class );
        }
    }

    $notImported = getNotImported($imports);
}
$xw->endElement();
$xw->endDocument();
$xml = $xw->flush();
//file_put_contents( dirname( __FILE__ )."/tmp/schemas.xml", $xml );
//file_put_contents( dirname( __FILE__ )."/tmp/code.txt", $code );
print( $xml);
exit;

/* functions */

function getNotImported($imports) {
    foreach ($imports as $k => $v) {
        if ($v === FALSE)
            return $k;
    }
    return FALSE;
}

// parse schema files

function xml2assoc(\XMLReader $xr, $path, \XMLWriter &$xw, $target = "", $ns_path = "") {

    global $uniques, $namespace, $nss, $nss_replacements, $counter, $buildDir;

    $tree = null;
    while ($xr->read())
        switch ($xr->nodeType) {
            case XMLReader::END_ELEMENT:
                if ($xr->localName != "schema" && $xr->localName != "import") {
                    $xw->endElement();
                }
                return $tree;
            case XMLReader::ELEMENT:
                switch ($xr->localName) {
                    case "schema":
                        // каждую новую схему добавляем в дерево
                        $tree = schema2assoc($xr, $path, $xw);
                        break;
                    case "import":
                    case "include":
                        $spath = dirname($path) . "/" . $xr->getAttribute("schemaLocation");
                        file_exists($spath) or trigger_error("file not exists:" . $spath);
                        import2assoc(realpath($spath), $xw);
                        break;
                    default:
                        // обычные узлы дополняем атрибутами
                        $node = array(
                            "tag" => $xr->name,
                            "prefix" => $xr->prefix,
                            "localName" => $xr->localName
                        );

                        $xw->startElement($xr->localName);

                        if ($xr->hasAttributes) {
                            $node["attributes"] = array();
                            while ($xr->moveToNextAttribute()) {
                                if ($node["localName"] == "pattern" && !$xr->prefix) {
                                    // если узел представляет из себя pattern рестрикшена,
                                    // то надо заменить в нем некоторые символы, чтобы обеспечить валидность выражения
                                    $val = str_replace("/", "\/", $xr->value);
                                    $node["attributes"][$xr->name] = htmlentities($val);
                                } else if (!$xr->prefix) {
                                    $node["attributes"][$xr->name] = $xr->value;
                                }
                                // элементы и типы элементов
                                if ($xr->localName == "name" && !$xr->prefix) {
                                    $node["attributes"]["schemaName"] = $xr->value;
                                    /**
                                     *
                                     * Один проблемный момент
                                     * могут запутаться классы атрибутов и классы элементов
                                     * в случае если атрибуты и элементы находятся в одном узле
                                     * дерева и при этом имеют одинаковые названия
                                     *
                                     * @todo решить как уходить от такого рода конфликтов
                                     *  и на каком этапе проектирования
                                     */
                                    $packagename = create_package_ns($xr->value, $target);
                                    $classname = create_class_name($xr->value);
                                    $propname = create_prop_name($xr->value);
                                    //$node["attributes"]["package"] = $packagename;
                                    $node["attributes"]["getter"] = "get" . $propname;
                                    $node["attributes"]["setter"] = "set" . $propname;
                                    $node["attributes"]["className"] = $classname;
                                    $node["attributes"]["propName"] = $propname;
                                    $node["attributes"]["targetNS"] = $target;
                                    $node["attributes"]["classNS"] = create_class_ns($packagename, $ns_path, $classname);
                                    $node["attributes"]["class"] = $node["attributes"]["classNS"] . "\\" . $classname;
                                    $node["attributes"]["filePath"] = $buildDir . DIRECTORY_SEPARATOR .
                                            str_replace("\\", DIRECTORY_SEPARATOR, $node["attributes"]["class"]);
                                }
                                if (in_array($xr->localName, array("type", "base", "itemType")) && !$xr->prefix) {
                                    $packagetypename = create_package_ns($xr->value, $target);
                                    $typename = create_class_name($xr->value);
                                    $node["attributes"]["typeClassNS"] = create_class_ns($packagetypename, "", $typename);
                                    $node["attributes"]["typeClassName"] = $typename;
                                    $node["attributes"]["typeClass"] = $node["attributes"]["typeClassNS"] .
                                            "\\" . $typename;
                                    $node["attributes"]["mode"] = "\Adaptor_XML::CONTENTS";
                                }
                                if ($xr->localName == "ref" && !$xr->prefix) {
                                    $packagerefname = create_package_ns($xr->value, $target);
                                    $refname = create_class_name($xr->value);
                                    $node["attributes"]["refClassNS"] = create_class_ns($packagerefname, "", $refname);
                                    $node["attributes"]["refClassName"] = $refname;
                                    $node["attributes"]["refClass"] = $node["attributes"]["refClassNS"] .
                                            "\\" . $refname;
                                    $node["attributes"]["mode"] = "\Adaptor_XML::ELEMENT";
                                }
                                if ($xr->localName == "substitutionGroup" && !$xr->prefix) {
                                    $package_subs_name = create_package_ns($xr->value, $target);
                                    $subs_name = create_class_name($xr->value);
                                    $node["attributes"]["subsClassNS"] = create_class_ns($package_subs_name, "", $subs_name);
                                    $node["attributes"]["subsClassName"] = $subs_name;
                                    $node["attributes"]["subsClass"] = $node["attributes"]["subsClassNS"] .
                                            "\\" . $subs_name;
                                }
                            }
                            foreach ($node["attributes"] as $k => $v) {
                                $xw->writeAttribute($k, $v);
                            }
                            $xw->writeAttribute("_ID", md5($counter++));
                            $xr->moveToElement();
                        }
                        if ($xr->isEmptyElement) {
                            $node["content"] = "";
                            $xw->endElement();
                        } else {
                            if (isset($classname))
                                $new_path = $ns_path != "" ? $ns_path . "\\" . $classname : $classname;
                            else
                                $new_path = $ns_path;
                            $node["content"] = xml2assoc($xr, $path, $xw, $target, $new_path);
                        }
                        if (isset($node["attributes"]["class"]) && !isset($uniques[$node["attributes"]["class"]])) {
                            $uniques[$node["attributes"]["class"]] = $node;
                        }
                        $tree[] = $node;
                }
                break;
            case XMLReader::TEXT:
            case XMLReader::CDATA:
                $xw->text($xr->value);
                $tree .= $xr->value;
        }
    return $tree;
}

function import2assoc($path, \XMLWriter &$xw) {
    global $base, $imports, $nss, $nss_replacements, $tree;

    if (isset($imports[$path]) && $imports[$path] !== FALSE)
        return array();

//    try {
    $xr = new XMLReader();
    $xr->XML(file_get_contents($path));

    $tree[] = xml2assoc($xr, $path, $xw);
//    } catch ( Exception $e ) {
//        throw new Exception( $path.":".$e->getMessage() );
    /* $xw->startElementNS( NULL, "importError", "urn:ru:ilb:tmp:error" );
      $xw->writeAttribute( "path", $path );
      $xw->text( $e->getMessage() );
      $xw->endElement();
      $xw->endDocument();
      exit();
     *
     */
//    }
}

function schema2assoc(\XMLReader $xr, $path, \XMLWriter &$xw, $target = null) {
    global $nss, $nss_replacements, $imports;

    $target = $xr->getAttribute("targetNamespace");
    $imports[$path] = $target;
    while ($xr->moveToNextAttribute()) {
        // записываем информацию о пространствах имен указанных в схеме префиксов
        if ($xr->prefix == "xmlns")
            $nss[$target][$xr->localName] = replace_ns($xr->value);
    }
    return xml2assoc($xr, $path, $xw, $target);
}

/* utilities */

function replace_ns($ns) {
    global $nss_replacements;

    return isset($nss_replacements[$ns]) ? $nss_replacements[$ns] : $ns;
}

/**
 * пространство имен класса
 * если имя класса является точным(без учета регистра) повторением последнего
 * отрезка пространства имен, то усекаем пространство имен
 *
 */
function create_class_ns($package, $ns_path, $val) {
    global $namespace, $nss, $local_nss;

    if (strtoupper(substr($package, -( strlen("\\" . $ns_path) ))) == strtoupper("\\" . $ns_path)) {
        $package = substr($package, 0, strlen($package) - ( strlen("\\" . $ns_path) ));
        //$package = str_replace( "\\".$ns_path,"", $package );
    }
    $class_ns = $package . ( $ns_path != "" ? "\\" . $ns_path : "" );
    // Предотвращаем двойное усечение
    if (!strtoupper(substr($ns_path, - ( strlen("\\" . $val) ))) == strtoupper("\\" . $val)) {
        if (strtoupper(substr($class_ns, - ( strlen("\\" . $val) ))) == strtoupper("\\" . $val)) {
            $class_ns = substr($class_ns, 0, strlen($class_ns) - ( strlen("\\" . $val) ));
            //$class_ns = str_replace("\\".$val,"", $class_ns );
        }
    }
    return $class_ns;
}

/**
 * пространство имен php для определенного пространства имен схемы
 * заменяем глобальные пространства имен на локальные
 * заменяем локальное пространство имен на кусок имени после urn:ru:ilb:meta: на пустую строку
 * заменяем : на \
 * добавляем заданное пространство имен проекта
 *
 */
function create_package_ns($val, $target) {

    global $namespace, $nss, $local_nss;

    $comma = strpos($val, ":");
    if ($comma !== false) {
        // атрибут name содержит префикс пространства имен
        // поэтому надо изменить таргет на соответствующий тому пространству
        $pref = substr($val, 0, $comma);
        // если не известный префикс, то надо падать с ошибкой
        if (!isset($nss[$target][$pref]))
            throw new Exception("Undefined namespace prefix \"$pref\"");
        else {
            // если известный то заменяем таргет на соответствующее пространство имен
            $target = $nss[$target][$pref];
        }
        // имя класса очищаем от префикса
        $val = substr($val, $comma + 1);
    }
    // заменяем глобальные пространства на локальные
    $target = replace_ns($target);
    // у локаьных убираем начальный кусок
    foreach ($local_nss as $local_ns) {
        $target = str_replace($local_ns, "", $target);
    }
    // заменим сепараторы
    $target = str_replace(":", "\\", $target);
    // ели речь идет о пространстве имен XML\Schema то указываем для
    if ($target == XML_SCHEMA_TARGET_NS) {
        return XML_SCHEMA_NS;
    } else {
        return $namespace . "\\" . $target;
    }
}

// Имя класса. указано в атрибуте name узла
// убираем префикс в атрибуте
// заменяем первую букву оставшейся строки на прописную
function create_class_name($val) {

    global $class_name_restrictions;

    $comma = strpos($val, ":");
    if ($comma) {
        $pref = substr($val, 0, $comma);
        $val = substr($val, $comma + 1);
    }
    $val = strtoupper(substr($val, 0, 1)) . substr($val, 1);
    if (in_array(strtolower($val), $class_name_restrictions)) {
        $val = "x" . $val;
    }
    return $val;
}

/**
 *
 * Построение имени для свойства класса.
 * Просто брать наименование элемента из атрибута name нельзя,
 * потому как в одном узле могут быть элементы имеющие одно наименование,
 * но относящиеся к разным пространствам имен, поэтому
 * используем префикс для указания имени
 *
 */
function create_prop_name($val) {

    global $namespace, $class_name_restrictions;

    $comma = strpos($val, ":");
    if ($comma) {
        $pref = substr($val, 0, $comma);
        $val = substr($val, $comma + 1);
    } else {
        $pref = "";
    }
    $val = strtoupper($pref) . strtoupper(substr($val, 0, 1)) . substr($val, 1);
    if (in_array(strtolower($val), $class_name_restrictions)) {
        $val = "x" . $val;
    }
    return $val;
}
