<?php

/**
 * вывод на печать ошибок валидации
 * @param \Happymeal\Port\Adaptor\Data\ValidationHandler $vh
 */
function serialize_errors(\Happymeal\Port\Adaptor\Data\ValidationHandler $vh) {
    foreach ($vh->getErrors() as $code => $errors) {
        foreach ($errors as $error) {
            print " $code: $error\n";
        }
    }
}
