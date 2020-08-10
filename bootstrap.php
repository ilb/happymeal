<?php

set_include_path(dirname(__DIR__) . "/happymeal/classes" .
        PATH_SEPARATOR . $happymealBuildDir .
        PATH_SEPARATOR . get_include_path() .
        PATH_SEPARATOR . "phplib-1" . //FIXME оно тут надо?
        PATH_SEPARATOR . "metalibphp-1" //FIXME оно тут надо?
);

spl_autoload_register(
        function ($class) {
    $filename = str_replace(array("\\", "_"), array("/", "/"), $class) . ".php";
    require_once $filename;
}
);
