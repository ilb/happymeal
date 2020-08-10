<?php

/*
 * Подмены классов для десериализации объектов
 * пример вызова
 * Adaptor_Bindings::setClassMapping(array("\ru\ilb\meta\contacts\contact\contacts\contactsbase\RelationMembers" => "\xxx\yyy\zzz\RelationMembersImpl"))
 */

/**
 * Description of Bindings
 *
 * @author slavb
 */
class Adaptor_Bindings {

    private static $classMapping;

    public static function setClassMapping($classMapping) {
        self::$classMapping = $classMapping;
    }

    public static function getClassMapping() {
        return self::$classMapping;
    }

    /**
     * @param class string  Имя класса
     * @param callback function Пользовательская функция.
     */
    public static function create($class, $callback = null) {
        if (isset(self::$classMapping[$class])) {
            $obj = new self::$classMapping[$class]();
        } else {
            $obj = new $class();
        }
        if ($callback) {
            return call_user_func_array($callback, array($obj));
        } else {
            return $obj;
        }
    }

}
