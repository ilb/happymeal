<?php

namespace Happymeal\Port\Adaptor\Data;

abstract class Validator {

    protected $validationHandler;

    public function __construct(ValidationHandler $handler = NULL) {
        $this->validationHandler = $handler;
    }

    protected function handleError($error, $code) {
        if (is_object($this->validationHandler)) {
            $this->validationHandler->handleError($error, $code);
        } else {
            error_log($error);
            throw new \Exception($error, $code);
        }
    }

    abstract public function validate();
}
