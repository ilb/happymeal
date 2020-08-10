<?php

class App {

    private static $instance = null;
    private $_container;
    private $_server;
    private $accept = array();
    private $default_replace_pairs = array(
        "\r" => '', //браузер для совместимости добавляет долбаный вендовый перевод строки - вырезаем его
        "&" => '&amp;', //экранировать амперсанд
        "&#8470;" => 'N', //русский "номер" заменить на N
        "&#171;" => '"', //заменить ковычки << на "
        "&#187;" => '"', //заменить ковычки >> на "
        "&#8211;" => '-', //заменить "длинное тире" на -
        "&#8212;" => '-', //заменить "длинное тире" на -
        "–" => '-',
        "—" => '-',
        "―" => '-',
        "«" => '"',
        "»" => '"',
        "№" => 'N',
    );

    private function __construct() {
        $path = str_replace(preg_replace('/\/api(\.v[0-9]{1,2}-[0-9]{1,2})?.php/', '', $_SERVER['SCRIPT_NAME']), '', $_SERVER['SCRIPT_URL']);
        // Уберем префикс  api/v? в сроке запроса
        $path_info = preg_replace('/\/api(\/v[0-9]{1,2}\.[0-9]{1,2})?/', '', $path);
        $this->_container['PATH_INFO'] = $path_info;
        preg_match('/\/api(\/v[0-9]{1,2}\.[0-9]{1,2})?/', $path, $matches);
        //error_log($matches[0]);
        $this->_container['API_VERSION'] = $matches[0];
        //print $this->_container['PATH_INFO'];exit;
    }

    public static function getInstance() {
        if (!static::$instance) {
            static::$instance = new \App();
        }
        return static::$instance;
    }

    // router
    public function get($pattern) {
        $args = func_get_args();
        array_shift($args);
        $this->_route('GET', $pattern, $args);
    }

    public function delete($pattern) {
        $args = func_get_args();
        array_shift($args);
        $this->_route('DELETE', $pattern, $args);
    }

    public function post($pattern) {
        $args = func_get_args();
        array_shift($args);
        $this->_route('POST', $pattern, $args);
    }

    public function put($pattern) {
        $args = func_get_args();
        array_shift($args);
        $this->_route('PUT', $pattern, $args);
    }

    public function patch($pattern) {
        $args = func_get_args();
        array_shift($args);
        $this->_route('PATCH', $pattern, $args);
    }

    private function _route($method, $pattern, $fn) {
        //assert method
        if (($_SERVER['REQUEST_METHOD'] == $method && !isset($_SERVER["HTTP_X_HTTP_METHOD_OVERRIDE"]) ) ||
                ( isset($_SERVER["HTTP_X_HTTP_METHOD_OVERRIDE"]) && $_SERVER["HTTP_X_HTTP_METHOD_OVERRIDE"] == $method )) {
            // convert URL parameters (":p", "*") to regular expression
            //$regex = str_replace(['*','(',')',':p'],['[^/]+','(?:',')?','([^/]+)'],$pattern);
            $regex = preg_replace('#:([\w]+)#', '(?<\\1>[^/]+)', str_replace(['*', ')'], ['[^/]+', ')?'], $pattern));
            //error_log($regex);
            if (substr($pattern, -1) === '/')
                $regex .= '?';
            if (!preg_match('#^' . $regex . '$#', $this->PATH_INFO, $values)) {
                return;
            }
            preg_match_all('#:([\w]+)#', $pattern, $params, PREG_PATTERN_ORDER);
            $args = [];
            foreach ($params[1] as $param) {
                if (isset($values[$param]))
                    $args[] = urldecode(preg_replace("/[^a-zA-ZА-ЯЁа-яё0-9\-]/", "", $values[$param]));
            }
            $this->_exec($fn, $args);
        } else
            return;
    }

    private function _exec(&$fn, &$args) {
        foreach ((array) $fn as $cb) {
            if (is_object($cb) && method_exists($cb, '__invoke')) {
                call_user_func_array($cb, $args);
            } else if (strstr("::", $cb)) {
                call_user_func_array(array($cb), $args);
            } else {
                $fn = explode(':', $cb);
                $obj = new $fn[0]();
                call_user_func_array(array(&$obj, $fn[1]), $args);
            }
        }
        exit;
    }

    // service&params container
    private function _get($id) {
        if (isset($this->_container[$id])) {
            $isInvokable = is_object($this->_container[$id]) && method_exists($this->_container[$id], '__invoke');
            return $isInvokable ? $this->_container[$id]($this) : $this->_container[$id];
        }
    }

    private function _set($id, $val) {
        $this->_container[$id] = $val;
    }

    public function once($id, $value) {
        $this->_set($id, function () use ($value) {
            static $object;
            if (null === $object) {
                $object = $value();
            }
            return $object;
        });
    }

    // helpers
    /**
     *
     * Парсим заголовок HTTP_ACCEPT для того, чтобы определить тип содержимого
     */
    public function __get($id) {
        return $this->_get($id);
    }

    public function __set($id, $val) {
        return $this->_set($id, $val);
    }

    private function _accept() {
        $json = $xml = 0;

        $parts = preg_split('/\s*(?:,*("[^"]+"),*|,*(\'[^\']+\'),*|,+)\s*/', $_SERVER["HTTP_ACCEPT"], 0, PREG_SPLIT_NO_EMPTY | PREG_SPLIT_DELIM_CAPTURE);
        foreach ($parts as $part) {
            $quality = 1.0;
            $params = preg_split('/;\s*q=/i', $part, 0, PREG_SPLIT_NO_EMPTY);
            if (count($params) == 1) {
                $params[] = $quality;
            }
            if (strpos($params[0], "/xml") !== FALSE) {
                $xml = (float) $params[1];
            } elseif (strpos($params[0], "/json") !== FALSE) {
                $json = (float) $params[1];
            }
        }
        if ($xml === 0 && $json === 0)
            return null;
        else
            return $xml > $json ? "xml" : "json";
    }

    /**
     * Обрабатываем входящий запрос
     *
     */
    public function request(\Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType $adaptor = null) {
        if ($_SERVER["REQUEST_METHOD"] == "POST") {
            if (!isset($GLOBALS["HTTP_RAW_POST_DATA"])) {
                $GLOBALS["HTTP_RAW_POST_DATA"] = file_get_contents("php://input");
            }
            if ($adaptor && array_key_exists("CONTENT_TYPE", $_SERVER) &&
                    strpos($_SERVER["CONTENT_TYPE"], "/xml") !== FALSE) {
                // todo: Можно проверить на соответствие схемы, хотя можно проверять через валидатор объекта
                $adaptor->fromXmlStr($GLOBALS["HTTP_RAW_POST_DATA"]);
                $this->REQUEST = $adaptor;
            } else if ($adaptor && array_key_exists("CONTENT_TYPE", $_SERVER) &&
                    strpos($_SERVER["CONTENT_TYPE"], "/json") !== FALSE) {
                if ($json = json_decode($GLOBALS["HTTP_RAW_POST_DATA"])) {
                    $adaptor->fromJSON(json_decode($GLOBALS["HTTP_RAW_POST_DATA"]));
                    $this->REQUEST = $adaptor;
                } else
                    $this->throwError(new \Exception("JSON data error", 450));
            } else {
                $this->REQUEST = $_POST;
            }
            $GLOBALS["HTTP_RAW_POST_DATA"] = NULL;
        }
        $this->QUERY = $_GET;
        return $this->REQUEST;
    }

    /**
     * Подготовка ответа
     *
     * @param $obj \Happymeal\Port\Adaptor\Data\XML\Schema\AnyType Сериализуемый объект
     * @param $pref вручную устанавливаемый тип контента
     */
    public function response(\Happymeal\Port\Adaptor\Data\XML\Schema\AnyType $obj, $pref = NULL) {
        $mode = $pref ? $pref : $this->_accept();
        switch ($mode) {
            case "xml":
                header("Content-type: application/xml; charset: utf-8");
                echo $obj->toXmlStr();
                exit;
            case "json":
                header("Content-type: application/json; charset: utf-8");
                echo $obj->toJSON();
                exit;
            default:
                header('HTTP/1.1 406 Not Acceptable');
                echo "We don't have any content for header 'Accept:" . $_SERVER["HTTP_ACCEPT"] . "'";
                exit;
        }
    }

    /**
     * https://svn.net.ilb.ru/viewvc/phplib/bb/HTTP/Request2Xml.php
     * Подчищает входные данные - лишние пробелы, переносы и пр.
     * @param string $value
     * @param array $replace_pairs массив замен символов, передать array() чтобы отключить замену
     * @return string
     */
    private function cleanup($value, $replace_pairs = NULL) {
        $replace_pairs = ($replace_pairs !== NULL) ? $replace_pairs : $this->$default_replace_pairs;
        return trim(strtr($value, $replace_pairs));
    }

    public function throwError(\Exception $e) {
        switch ($e->getCode()) {
            case 404:
                header('HTTP/1.0 404 Not Found');
                echo "<h1>Error 404 Not Found</h1>";
                echo "<p>The resource '" . $this->PATH_INFO . "' could not be found.</p>";
                exit();
            case 450:
                header('HTTP/1.0 400 Bad Request');
                echo "<p>" . $e->getMessage() . "</p>";
                exit;
            default:
                error_log($e->getLine() . ":" . $e->getFile() . " " . $e->getMessage());
                throw new \Exception($e->getMessage(), $e->getCode());
                exit;
        }
    }

    //cache
    //http://habrahabr.ru/post/44906/
    //http://www.exlab.net/dev/http-caching.html
    function cacheControl($lastmod) {
        //return;
        $etag = $lastmod;
        $expr = 60 * 60 * 24 * 7;
        $gmtime = gmdate("D, d M Y H:i:s", $lastmod) . " GMT";
        header("ETag: " . $etag);
        header("Last-Modified: " . $gmtime);
        header("Vary: Accept");
        header("Cache-Control: ");
        header("Pragma: ");
        header("Expires: ");
        if (isset($_SERVER["HTTP_IF_MODIFIED_SINCE"])) {
            $if_modified_since = preg_replace("/;.*$/", "", $_SERVER["HTTP_IF_MODIFIED_SINCE"]);
            if (trim($_SERVER["HTTP_IF_NONE_MATCH"]) == $etag && $if_modified_since == $gmtime) {
                header("HTTP/1.0 304 Not modified");
                header("Expires: max-age={$expr}, must-revalidate");
                exit;
            }
        }
    }

}
